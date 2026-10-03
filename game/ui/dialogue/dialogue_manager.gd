class_name DialogueManager
extends CanvasLayer

signal dialogue_started
signal dialogue_finished

var last_cancelled: bool = false
var choices_active: bool = false
var _choice_prompt: String = ""
var _choice_callback: Callable
var active: bool = false
var line_index: int = 0
var _data: DialogueData
var _player: Node
var _owner: Node
var _finished: Callable
var _waiting_for_release: bool = false

@onready var panel: Panel = $Panel
@onready var speaker: Label = $Panel/SpeakerLabel
@onready var text: Label = $Panel/DialogueLabel
@onready var choices: HBoxContainer = $Panel/Choices


func _ready() -> void:
	panel.hide()
	choices.hide()
	$Panel/Choices/Yes.pressed.connect(_choose.bind(true))
	$Panel/Choices/No.pressed.connect(_choose.bind(false))


func can_start(data: DialogueData) -> bool:
	return not active and data != null and not data.lines.is_empty()


func start(data: DialogueData, actor: Node, interaction_owner: Node, finished: Callable, choice_prompt: String = "", chosen: Callable = Callable(), accept_label: String = "Yes", decline_label: String = "No") -> bool:
	if not can_start(data):
		return false
	last_cancelled = false
	choices_active = false
	choices.hide()
	$Panel/Choices/Yes.text = accept_label
	$Panel/Choices/No.text = decline_label
	$Panel/ContinueIndicator.show()
	_choice_prompt = choice_prompt
	_choice_callback = chosen
	_data = data
	_player = actor
	_owner = interaction_owner
	_finished = finished
	line_index = 0
	active = true
	# Consume the opening press and require release before another advance.
	_waiting_for_release = Input.is_action_pressed("interact")
	_show_line()
	panel.show()
	dialogue_started.emit()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if active and choices_active and event.is_action_pressed("ui_cancel") and not event.is_echo():
		_close(true)
		get_viewport().set_input_as_handled()
		return
	if not active or not event.is_action("interact"):
		return
	if event.is_action_released("interact"):
		_waiting_for_release = false
	elif event.is_action_pressed("interact") and not event.is_echo() and not _waiting_for_release:
		_waiting_for_release = true
		if not choices_active:
			advance()
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if active and (not is_instance_valid(_player) or not is_instance_valid(_owner)):
		_close(true)


func advance() -> void:
	if not active or choices_active:
		return
	line_index += 1
	if line_index >= _data.lines.size():
		if not _choice_prompt.is_empty() and _choice_callback.is_valid():
			choices_active = true
			text.text = _choice_prompt
			$Panel/ContinueIndicator.hide()
			choices.show()
			$Panel/Choices/Yes.grab_focus()
		else:
			_close()
	else:
		_show_line()


func cancel(interaction_owner: Node) -> void:
	if active and interaction_owner == _owner:
		_close(true)


func _show_line() -> void:
	var line: DialogueLine = _data.lines[line_index]
	speaker.text = line.speaker_name
	speaker.visible = not speaker.text.is_empty()
	text.text = line.text


func _choose(accepted: bool) -> void:
	if not active or not choices_active:
		return
	choices_active = false
	var callback: Callable = _choice_callback
	_choice_callback = Callable()
	if callback.is_valid():
		callback.call(accepted)
	_close()


func _close(cancelled: bool = false) -> void:
	if not active:
		return
	active = false
	last_cancelled = cancelled
	choices_active = false
	panel.hide()
	choices.hide()
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null and choices.is_ancestor_of(focused):
		focused.release_focus()
	var callback: Callable = _finished
	var actor: Node = _player
	var interaction_owner: Node = _owner
	# Clear the old session before callbacks; they may begin a new conversation.
	_finished = Callable()
	_choice_callback = Callable()
	_choice_prompt = ""
	_player = null
	_owner = null
	_data = null
	if callback.is_valid():
		callback.call()
	elif is_instance_valid(actor):
		actor.call("end_interaction", interaction_owner)
	dialogue_finished.emit()

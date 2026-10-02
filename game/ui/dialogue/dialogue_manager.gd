class_name DialogueManager
extends CanvasLayer

signal dialogue_started
signal dialogue_finished

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


func _ready() -> void:
	panel.hide()


func can_start(data: DialogueData) -> bool:
	return not active and data != null and not data.lines.is_empty()


func start(data: DialogueData, actor: Node, interaction_owner: Node, finished: Callable) -> bool:
	if not can_start(data):
		return false
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
	if not active or not event.is_action("interact"):
		return
	if event.is_action_released("interact"):
		_waiting_for_release = false
	elif event.is_action_pressed("interact") and not event.is_echo() and not _waiting_for_release:
		_waiting_for_release = true
		advance()
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if active and (not is_instance_valid(_player) or not is_instance_valid(_owner)):
		_close()


func advance() -> void:
	if not active:
		return
	line_index += 1
	if line_index >= _data.lines.size():
		_close()
	else:
		_show_line()


func cancel(interaction_owner: Node) -> void:
	if active and interaction_owner == _owner:
		_close()


func _show_line() -> void:
	var line: DialogueLine = _data.lines[line_index]
	speaker.text = line.speaker_name
	speaker.visible = not speaker.text.is_empty()
	text.text = line.text


func _close() -> void:
	active = false
	panel.hide()
	var callback: Callable = _finished
	_finished = Callable()
	if callback.is_valid():
		callback.call()
	elif is_instance_valid(_player):
		_player.call("end_interaction", _owner)
	_player = null
	_owner = null
	_data = null
	dialogue_finished.emit()

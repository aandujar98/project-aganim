extends CanvasLayer

var active: bool = false
var _actor: CharacterBody2D
var _selected: int = 1
var _pending_operation: StringName
var _pending_slot: int = -1
var _working: bool = false

@onready var screen: Control = $Screen
@onready var list: ItemList = $Screen/Panel/Slots
@onready var details: Label = $Screen/Panel/Details
@onready var name_entry: LineEdit = $Screen/Panel/NameEntry
@onready var feedback: Label = $Screen/Panel/Feedback
@onready var confirmation: Panel = $Screen/Confirm


func _ready() -> void:
	screen.hide()
	confirmation.hide()
	list.item_selected.connect(_on_selected)
	$Screen/Panel/New.pressed.connect(_request_new)
	$Screen/Panel/Load.pressed.connect(_load)
	$Screen/Panel/Save.pressed.connect(_save)
	$Screen/Panel/Delete.pressed.connect(_request_delete)
	$Screen/Panel/Close.pressed.connect(close_menu)
	$Screen/Confirm/Yes.pressed.connect(_confirm)
	$Screen/Confirm/No.pressed.connect(_cancel_confirmation)
	SaveManager.slots_changed.connect(_refresh)
	SaveManager.game_loaded.connect(_on_loaded)


func _input(event: InputEvent) -> void:
	# Handle Back before focused text fields consume it. Opening stays unhandled
	# so inventory/dialogue/shop can consume their own cancellation first.
	if active and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")) and not event.is_echo():
		if confirmation.visible:
			_cancel_confirmation()
		else:
			close_menu()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not active and event.is_action_pressed("pause") and not event.is_echo():
		open_menu()
		get_viewport().set_input_as_handled()


func open_menu() -> bool:
	if active or SaveManager.busy or SceneTransitions.busy:
		return false
	var actor: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if actor != null:
		if not actor.begin_interaction(self):
			return false
		_actor = actor
		_actor.interaction_cancelled.connect(_on_cancelled)
		_actor.tree_exiting.connect(close_menu)
	active = true
	screen.show()
	$Screen/Panel.show()
	confirmation.hide()
	name_entry.text = PlayerProfile.player_name
	feedback.text = "Save: active slot only · Close other menus first"
	_refresh()
	list.grab_focus()
	return true


func close_menu() -> void:
	if not active:
		return
	active = false
	screen.hide()
	confirmation.hide()
	Input.action_release("attack")
	var focus: Control = get_viewport().gui_get_focus_owner()
	if focus != null and screen.is_ancestor_of(focus):
		focus.release_focus()
	if is_instance_valid(_actor):
		if _actor.interaction_cancelled.is_connected(_on_cancelled):
			_actor.interaction_cancelled.disconnect(_on_cancelled)
		if _actor.tree_exiting.is_connected(close_menu):
			_actor.tree_exiting.disconnect(close_menu)
		_actor.end_interaction(self)
	_actor = null


func _on_cancelled(owner: Node) -> void:
	if owner == self:
		close_menu()


func _on_loaded(_slot: int) -> void:
	close_menu()


func _refresh() -> void:
	if not active:
		return
	list.clear()
	for slot: int in range(1, SaveManager.SLOT_COUNT + 1):
		var metadata: Dictionary = SaveManager.get_slot_metadata(slot)
		var label: String = "Empty" if metadata.empty else "Corrupted Save" if metadata.corrupted else metadata.player_name
		list.add_item("Slot %d · %s" % [slot, label])
	list.select(_selected - 1)
	_show_details()


func _on_selected(index: int) -> void:
	_selected = index + 1
	_show_details()


func _show_details() -> void:
	var metadata: Dictionary = SaveManager.get_slot_metadata(_selected)
	if metadata.empty:
		details.text = "Empty slot\nEnter a name, then choose New."
	elif metadata.corrupted:
		details.text = "Corrupted Save\n" + metadata.error
	else:
		var seconds: int = metadata.playtime_seconds
		details.text = "%s\nArea: %s\nTime: %02d:%02d:%02d\nLast Save: %s" % [metadata.player_name, metadata.current_area_name,
			seconds / 3600, seconds / 60 % 60, seconds % 60, metadata.last_saved_timestamp]
	$Screen/Panel/Load.disabled = metadata.empty or metadata.get("corrupted", false)
	$Screen/Panel/Delete.disabled = metadata.empty
	$Screen/Panel/Save.disabled = SaveManager.active_slot < 1


func _request_new() -> void:
	if _working:
		return
	if SaveManager.has_save(_selected):
		_show_confirmation(&"new", "Start a new game in Slot %d? Its save is replaced only when you manually save." % _selected)
	else:
		_start_new(_selected, false)


func _request_delete() -> void:
	if not _working and SaveManager.has_save(_selected):
		_show_confirmation(&"delete", "Permanently delete Slot %d and its backup?" % _selected)


func _show_confirmation(operation: StringName, message: String) -> void:
	_pending_operation = operation
	_pending_slot = _selected
	$Screen/Panel.hide()
	$Screen/Confirm/Message.text = message
	confirmation.show()
	$Screen/Confirm/No.grab_focus()


func _cancel_confirmation() -> void:
	confirmation.hide()
	$Screen/Panel.show()
	_pending_operation = &""
	_pending_slot = -1
	list.grab_focus()


func _confirm() -> void:
	var slot: int = _pending_slot
	var operation: StringName = _pending_operation
	_cancel_confirmation()
	if operation == &"delete":
		SaveManager.delete_save(slot, true)
		feedback.text = SaveManager.last_error if not SaveManager.last_error.is_empty() else "Slot deleted."
		_refresh()
	elif operation == &"new":
		_start_new(slot, true)


func _start_new(slot: int, confirmed: bool) -> void:
	_working = true
	var success: bool = await SaveManager.new_game(slot, name_entry.text, confirmed)
	_working = false
	if not success and active:
		feedback.text = SaveManager.last_error


func _load() -> void:
	if _working:
		return
	_working = true
	var success: bool = await SaveManager.load_game(_selected)
	_working = false
	if not success and active:
		feedback.text = SaveManager.last_error


func _save() -> void:
	if _working:
		return
	# Close our own scoped lock so only NORMAL gameplay snapshots are accepted.
	close_menu()
	var success: bool = SaveManager.save_game()
	InventoryScreen.show_notification("Game saved." if success else SaveManager.last_error)

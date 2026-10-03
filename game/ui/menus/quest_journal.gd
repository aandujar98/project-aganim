extends CanvasLayer

var active: bool = false
var _actor: CharacterBody2D
var _ids: Array[StringName] = []
var _selected_id: StringName

@onready var screen: Control = $Screen
@onready var tabs: TabBar = $Screen/Panel/Tabs
@onready var list: ItemList = $Screen/Panel/QuestList
@onready var empty: Label = $Screen/Panel/EmptyLabel
@onready var title: Label = $Screen/Panel/QuestDetails/Contents/Title
@onready var description: Label = $Screen/Panel/QuestDetails/Contents/Description
@onready var objectives: Label = $Screen/Panel/QuestDetails/Contents/Objectives
@onready var status: Label = $Screen/Panel/QuestDetails/Contents/Status
@onready var details: ScrollContainer = $Screen/Panel/QuestDetails


func _ready() -> void:
	screen.hide()
	tabs.tab_changed.connect(_on_tab_changed)
	list.item_selected.connect(_on_selected)
	$Screen/Panel/Close.pressed.connect(close_journal)
	QuestManager.quest_state_changed.connect(_on_quest_changed)
	QuestManager.notification_requested.connect(InventoryScreen.show_notification)


func _input(event: InputEvent) -> void:
	if event.is_action("quest_journal"):
		if event.is_action_pressed("quest_journal") and not event.is_echo():
			if active:
				close_journal()
			else:
				open_journal(get_tree().get_first_node_in_group("player") as CharacterBody2D)
		get_viewport().set_input_as_handled()
	elif active and event.is_action("ui_cancel"):
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			close_journal()
		get_viewport().set_input_as_handled()
	elif active and details.has_focus():
		_navigate_details(event)


func _navigate_details(event: InputEvent) -> void:
	# ScrollContainer does not scroll from D-pad input by default.
	for action: StringName in [&"ui_up", &"ui_down", &"ui_left", &"ui_right"]:
		if not event.is_action(action):
			continue
		if event.is_action_pressed(action):
			var maximum: int = int(details.get_v_scroll_bar().max_value - details.get_v_scroll_bar().page)
			if action == &"ui_left":
				list.grab_focus()
			elif action == &"ui_right" or (action == &"ui_down" and details.scroll_vertical >= maximum):
				$Screen/Panel/Close.grab_focus()
			elif action == &"ui_up" and details.scroll_vertical == 0:
				tabs.grab_focus()
			else:
				details.scroll_vertical += 12 if action == &"ui_down" else -12
		get_viewport().set_input_as_handled()
		return


func open_journal(actor: CharacterBody2D) -> bool:
	if active or SceneTransitions.busy or not is_instance_valid(actor) or not actor.is_in_group("player"):
		return false
	if get_tree().current_scene == null or not get_tree().current_scene.is_ancestor_of(actor) or not actor.begin_interaction(self):
		return false
	_actor = actor
	_actor.interaction_cancelled.connect(_on_cancelled)
	_actor.tree_exiting.connect(close_journal)
	active = true
	_selected_id = &""
	tabs.current_tab = 0
	screen.show()
	_rebuild()
	if _ids.is_empty():
		tabs.grab_focus()
	else:
		list.grab_focus()

	return true


func close_journal() -> void:
	if not active:
		return
	active = false
	screen.hide()
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null and screen.is_ancestor_of(focused):
		focused.release_focus()
	if is_instance_valid(_actor):
		if _actor.interaction_cancelled.is_connected(_on_cancelled):
			_actor.interaction_cancelled.disconnect(_on_cancelled)
		if _actor.tree_exiting.is_connected(close_journal):
			_actor.tree_exiting.disconnect(close_journal)
		_actor.end_interaction(self)
	_actor = null


func _on_cancelled(interaction_owner: Node) -> void:
	if interaction_owner == self:
		close_journal()


func _on_quest_changed(_id: StringName) -> void:
	if active:
		_rebuild()


func _on_tab_changed(_index: int) -> void:
	_selected_id = &""
	if active:
		_rebuild()


func _rebuild() -> void:
	list.clear()
	_ids.clear()
	var selected: int = -1
	var requested: QuestRuntime.QuestState = QuestRuntime.QuestState.ACTIVE if tabs.current_tab == 0 else QuestRuntime.QuestState.COMPLETED
	for data: QuestData in QuestManager.database.get_all():
		if QuestManager.get_state(data.id) != requested:
			continue
		if _selected_id == data.id:
			selected = _ids.size()
		_ids.append(data.id)
		list.add_item(data.title)
	empty.visible = _ids.is_empty()
	empty.text = "No active quests." if tabs.current_tab == 0 else "No completed quests."
	if _ids.is_empty():
		_selected_id = &""
		_show_details()
	else:
		selected = maxi(selected, 0)
		list.select(selected)
		list.ensure_current_is_visible()
		_on_selected(selected)


func _on_selected(index: int) -> void:
	if index >= 0 and index < _ids.size():
		if _selected_id != _ids[index]:
			details.scroll_vertical = 0
		_selected_id = _ids[index]
		_show_details()


func _show_details() -> void:
	var data: QuestData = QuestManager.get_definition(_selected_id)
	var runtime: QuestRuntime = QuestManager.get_runtime(_selected_id)
	title.text = data.title if data != null else ""
	description.text = data.description if data != null else ""
	objectives.text = ""
	status.text = ""
	if data == null or runtime == null:
		return
	for index: int in range(data.objectives.size()):
		var objective: QuestObjectiveData = data.objectives[index]
		objectives.text += "%s\n%d / %d\n\n" % [objective.description, runtime.objective_progress[index], objective.required_amount]
	if runtime.state == QuestRuntime.QuestState.COMPLETED:
		status.text = "Completed"
	elif runtime.objectives_complete:
		status.text = data.turn_in_description if data.require_turn_in else "Objectives complete"
	else:
		status.text = "Active"

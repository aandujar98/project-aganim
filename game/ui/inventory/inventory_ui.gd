extends CanvasLayer

var active: bool = false
var _actor: CharacterBody2D
var _entries: Array[InventoryEntry] = []
var _selected_id: StringName = &""

@onready var screen: Control = $Screen
@onready var tabs: TabBar = $Screen/Panel/CategoryTabs
@onready var list: ItemList = $Screen/Panel/ItemList
@onready var empty: Label = $Screen/Panel/EmptyLabel
@onready var icon: TextureRect = $Screen/Panel/ItemIcon
@onready var item_name: Label = $Screen/Panel/ItemName
@onready var description: Label = $Screen/Panel/ItemDescription
@onready var category: Label = $Screen/Panel/CategoryLabel
@onready var quantity: Label = $Screen/Panel/QuantityLabel
@onready var use_button: Button = $Screen/Panel/UseButton
@onready var close_button: Button = $Screen/Panel/CloseButton
@onready var feedback: Label = $Screen/Panel/FeedbackLabel
@onready var acquired_notification: Panel = $Notification
@onready var notification_timer: Timer = $NotificationTimer


func _ready() -> void:
	screen.hide()
	acquired_notification.hide()
	tabs.tab_changed.connect(_on_category_changed)
	list.item_selected.connect(_on_selected)
	list.item_activated.connect(_on_activated)
	use_button.pressed.connect(_use_selected)
	close_button.pressed.connect(close_inventory)
	Inventory.inventory_changed.connect(_on_inventory_changed)
	Inventory.item_added.connect(_on_item_added)
	notification_timer.timeout.connect(acquired_notification.hide)


func _input(event: InputEvent) -> void:
	if event.is_action("inventory"):
		if event.is_action_pressed("inventory") and not event.is_echo():
			if active:
				close_inventory()
			else:
				var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
				open_inventory(player)
		get_viewport().set_input_as_handled()
	elif active and event.is_action("ui_cancel"):
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			close_inventory()
		get_viewport().set_input_as_handled()


func open_inventory(actor: CharacterBody2D) -> bool:
	if active or SceneTransitions.busy or not is_instance_valid(actor) or not actor.is_in_group("player"):
		return false
	if get_tree().current_scene == null or not get_tree().current_scene.is_ancestor_of(actor):
		return false
	if not actor.is_inside_tree() or not actor.begin_interaction(self):
		return false
	_actor = actor
	_actor.interaction_cancelled.connect(_on_cancelled)
	_actor.tree_exiting.connect(close_inventory)
	active = true
	_selected_id = &""
	tabs.set_current_tab(0)
	feedback.text = ""
	acquired_notification.hide()
	screen.show()
	_rebuild()
	if _entries.is_empty():
		tabs.grab_focus()
	else:
		list.grab_focus()
	return true


func close_inventory() -> void:
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
		if _actor.tree_exiting.is_connected(close_inventory):
			_actor.tree_exiting.disconnect(close_inventory)
		_actor.end_interaction(self)
	_actor = null


func _on_cancelled(interaction_owner: Node) -> void:
	if interaction_owner == self:
		close_inventory()


func _on_inventory_changed() -> void:
	if active:
		_rebuild()


func _on_category_changed(_tab: int) -> void:
	if active:
		_selected_id = &""
		feedback.text = ""
		_rebuild()


func _rebuild() -> void:
	var previous_index: int = list.get_selected_items()[0] if not list.get_selected_items().is_empty() else 0
	var had_use_focus: bool = use_button.has_focus()
	list.clear()
	_entries.clear()
	var selected: int = -1
	for entry: InventoryEntry in Inventory.get_entries():
		var item: ItemData = ItemDatabase.get_item(entry.item_id)
		if item == null or not _matches_category(item):
			continue
		if entry.item_id == _selected_id:
			selected = _entries.size()
		_entries.append(entry)
		# Put quantity first so long names cannot ellipsize away owned amounts.
		list.add_item("×%d · %s" % [entry.quantity, item.display_name], item.icon)
		list.set_item_tooltip(_entries.size() - 1, "%s · Quantity: %d" % [item.display_name, entry.quantity])
	empty.visible = _entries.is_empty()
	empty.text = "Inventory is empty." if Inventory.get_entries().is_empty() else "This category is empty."
	if _entries.is_empty():
		_selected_id = &""
		_show_details(null)
	else:
		if selected < 0:
			selected = clampi(previous_index, 0, _entries.size() - 1)
		list.select(selected)
		list.ensure_current_is_visible()
		_on_selected(selected)
	if had_use_focus and not use_button.visible:
		if not _entries.is_empty():
			list.grab_focus()
		else:
			tabs.grab_focus()


func _matches_category(item: ItemData) -> bool:
	match tabs.current_tab:
		1: return item.category == ItemData.ItemCategory.CONSUMABLE
		2: return item.category in [ItemData.ItemCategory.KEY_ITEM, ItemData.ItemCategory.DUNGEON_ITEM, ItemData.ItemCategory.QUEST_ITEM]
		3: return item.category == ItemData.ItemCategory.MATERIAL or item.category == ItemData.ItemCategory.COLLECTIBLE
	return true


func _on_selected(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	_selected_id = _entries[index].item_id
	_show_details(ItemDatabase.get_item(_selected_id))


func _show_details(item: ItemData) -> void:
	icon.texture = item.icon if item != null else null
	item_name.text = item.display_name if item != null else ""
	description.text = item.description if item != null else ""
	category.text = item.category_name() if item != null else ""
	quantity.text = "Quantity: %d" % Inventory.get_quantity(item.id) if item != null else ""
	use_button.visible = item != null and item.category == ItemData.ItemCategory.CONSUMABLE and not item.use_effect.is_empty()
	list.focus_neighbor_right = list.get_path_to(use_button if use_button.visible else close_button)
	list.focus_next = list.focus_neighbor_right
	close_button.focus_previous = close_button.get_path_to(use_button if use_button.visible else list)


func _on_activated(index: int) -> void:
	_on_selected(index)
	_use_selected()


func _use_selected() -> void:
	if not active or _selected_id.is_empty() or not use_button.visible:
		return
	Inventory.use_item(_selected_id, _actor)
	feedback.text = Inventory.last_use_message


func _on_item_added(item_id: StringName, amount: int) -> void:
	var item: ItemData = ItemDatabase.get_item(item_id)
	if item == null:
		return
	var message: String = "Obtained %s ×%d" % [item.display_name, amount]
	if active:
		feedback.text = message
	else:
		var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
		# Chests already use shared dialogue; avoid a second overlapping message.
		if is_instance_valid(player) and player.state == player.PlayerState.NORMAL:
			show_notification(message)


func show_notification(message: String) -> void:
	$Notification/Label.text = message
	acquired_notification.show()
	notification_timer.start()

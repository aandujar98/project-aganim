extends CanvasLayer

var active: bool = false
var _actor: CharacterBody2D
var _shop_id: StringName
var _ids: Array[StringName] = []
var _selected: int = 0
var _confirm_down: bool = false

@onready var screen: Control = $Screen
@onready var list: ItemList = $Screen/Panel/ItemList
@onready var heading: Label = $Screen/Panel/ShopName
@onready var yen: Label = $Screen/Panel/Yen
@onready var empty: Label = $Screen/Panel/EmptyLabel
@onready var icon: TextureRect = $Screen/Panel/Details/Icon
@onready var item_name: Label = $Screen/Panel/Details/ItemName
@onready var description: Label = $Screen/Panel/Details/Description
@onready var price: Label = $Screen/Panel/Details/Price
@onready var owned: Label = $Screen/Panel/Details/Owned
@onready var stock: Label = $Screen/Panel/Details/Stock
@onready var status: Label = $Screen/Panel/Details/Status
@onready var buy: Button = $Screen/Panel/Buy
@onready var close: Button = $Screen/Panel/Close


func _ready() -> void:
	screen.hide()
	list.item_selected.connect(_on_selected)
	buy.pressed.connect(_purchase)
	close.pressed.connect(close_shop)
	Wallet.yen_changed.connect(_on_yen_changed)
	Inventory.inventory_changed.connect(_on_inventory_changed)
	ShopManager.stock_changed.connect(_on_stock_changed)


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action("ui_cancel"):
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			close_shop()
		get_viewport().set_input_as_handled()
	elif event.is_action("ui_accept"):
		if event.is_action_released("ui_accept"):
			_confirm_down = false
		if list.has_focus() or buy.has_focus():
			if event.is_action_pressed("ui_accept") and not event.is_echo() and not _confirm_down:
				_confirm_down = true
				_purchase()
			get_viewport().set_input_as_handled()


func open_shop(id: StringName, actor: CharacterBody2D) -> bool:
	var data: ShopData = ShopManager.get_shop(id)
	if active or data == null or SceneTransitions.busy or not is_instance_valid(actor) or not actor.is_in_group("player"):
		return false
	if get_tree().current_scene == null or not get_tree().current_scene.is_ancestor_of(actor) or not actor.begin_interaction(self):
		return false
	_actor = actor
	_actor.interaction_cancelled.connect(_on_cancelled)
	_actor.tree_exiting.connect(close_shop)
	_shop_id = id
	_selected = 0
	_confirm_down = Input.is_action_pressed("ui_accept")
	active = true
	heading.text = data.display_name
	screen.show()
	_refresh()
	if _ids.is_empty():
		close.grab_focus()
	else:
		list.grab_focus()
	return true


func close_shop() -> void:
	if not active:
		return
	active = false
	screen.hide()
	# Confirm/close shares the attack binding; do not leak that press into gameplay.
	Input.action_release("attack")
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null and screen.is_ancestor_of(focused):
		focused.release_focus()
	if is_instance_valid(_actor):
		if _actor.interaction_cancelled.is_connected(_on_cancelled):
			_actor.interaction_cancelled.disconnect(_on_cancelled)
		if _actor.tree_exiting.is_connected(close_shop):
			_actor.tree_exiting.disconnect(close_shop)
		_actor.end_interaction(self)
	_actor = null
	_shop_id = &""


func _on_cancelled(interaction_owner: Node) -> void:
	if interaction_owner == self:
		close_shop()


func _on_yen_changed(_amount: int) -> void:
	_refresh()
	_refresh.call_deferred()


func _on_inventory_changed() -> void:
	_refresh()
	_refresh.call_deferred()


func _on_stock_changed(id: StringName, _item_id: StringName, _remaining: int) -> void:
	if id == _shop_id:
		_refresh()
		_refresh.call_deferred()


func _refresh() -> void:
	if not active:
		return
	var data: ShopData = ShopManager.get_shop(_shop_id)
	list.clear()
	_ids.clear()
	yen.text = YenFormat.format(Wallet.get_yen())
	for entry: ShopEntryData in data.entries:
		var item: ItemData = ItemDatabase.get_item(entry.item_id)
		var remaining: int = ShopManager.get_stock(_shop_id, entry.item_id)
		var cost: int = ShopManager.resolve_price(entry)
		var suffix: String = " · SOLD OUT" if remaining == 0 else " · Stock %d" % remaining if remaining > 0 else ""
		_ids.append(entry.item_id)
		list.add_item(item.display_name + "\n" + YenFormat.format(cost) + suffix, item.icon)
		list.set_item_custom_fg_color(_ids.size() - 1, Color(0.6, 0.62, 0.65) if remaining == 0 or Wallet.get_yen() < cost else Color.WHITE)
	empty.visible = _ids.is_empty()
	if _ids.is_empty():
		icon.texture = null
		item_name.text = ""
		description.text = ""
		price.text = ""
		owned.text = ""
		stock.text = ""
		status.text = "Nothing is available right now."
		buy.disabled = true
		return
	_selected = clampi(_selected, 0, _ids.size() - 1)
	list.select(_selected)
	list.ensure_current_is_visible()
	_show_details()


func _on_selected(index: int) -> void:
	_selected = index
	_show_details()


func _show_details() -> void:
	var id: StringName = _ids[_selected]
	var item: ItemData = ItemDatabase.get_item(id)
	var remaining: int = ShopManager.get_stock(_shop_id, id)
	icon.texture = item.icon
	item_name.text = item.display_name
	description.text = item.description
	price.text = "Price: " + YenFormat.format(ShopManager.resolve_price(ShopManager.get_entry(_shop_id, id)))
	owned.text = "Owned: %d" % Inventory.get_quantity(id)
	stock.text = "SOLD OUT" if remaining == 0 else "Stock: %d" % remaining if remaining > 0 else "Unlimited stock"
	status.text = ShopManager.purchase_reason(_shop_id, id)
	if status.text.is_empty():
		status.text = "Confirm / Buy: purchase one"
	buy.disabled = remaining == 0


func _purchase() -> void:
	if not active or _ids.is_empty():
		return
	ShopManager.buy_item(_shop_id, _ids[_selected])
	var message: String = ShopManager.last_message
	_refresh()
	if active:
		status.text = message
	InventoryScreen.show_notification(message)

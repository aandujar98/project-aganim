extends Node

signal stock_changed(shop_id: StringName, item_id: StringName, remaining: int)
signal item_purchased(shop_id: StringName, item_id: StringName, price: int)

const SHOP_PATHS: Array[String] = ["res://game/items/data/shops/dev_convenience_store.tres"]
var last_message: String = ""
var _shops: Dictionary = {}
var _stocks: Dictionary = {}
var _buying: bool = false


func _ready() -> void:
	for path: String in SHOP_PATHS:
		register_shop(load(path) as ShopData)


func register_shop(data: ShopData) -> bool:
	if data == null or not data.is_valid_definition() or _shops.has(data.id):
		push_warning("ShopManager rejected invalid/duplicate shop ID.")
		return false
	var stocks: Dictionary = {}
	for entry: ShopEntryData in data.entries:
		if entry == null or not entry.is_valid_definition() or stocks.has(entry.item_id):
			push_warning("ShopManager rejected malformed/duplicate entry in " + str(data.id))
			return false
		var item: ItemData = ItemDatabase.get_item(entry.item_id)
		if item == null or resolve_price(entry) < 0 or resolve_price(entry) > Wallet.MAX_YEN:
			push_warning("ShopManager rejected item/price in " + str(data.id))
			return false
		stocks[entry.item_id] = entry.stock
	_shops[data.id] = data
	_stocks[data.id] = stocks
	return true


func get_shop(id: StringName) -> ShopData:
	return _shops.get(id) as ShopData


func get_entry(shop_id: StringName, item_id: StringName) -> ShopEntryData:
	var data: ShopData = get_shop(shop_id)
	if data != null:
		for entry: ShopEntryData in data.entries:
			if entry.item_id == item_id:
				return entry
	return null


func resolve_price(entry: ShopEntryData) -> int:
	if entry == null:
		return -1
	if entry.price_override >= 0:
		return entry.price_override
	var item: ItemData = ItemDatabase.get_item(entry.item_id)
	return item.buy_price if item != null and item.buy_price > 0 else -1


func get_stock(shop_id: StringName, item_id: StringName) -> int:
	return int(_stocks[shop_id].get(item_id, 0)) if _stocks.has(shop_id) else 0


func purchase_reason(shop_id: StringName, item_id: StringName) -> String:
	if _buying:
		return "A purchase is already in progress."
	var entry: ShopEntryData = get_entry(shop_id, item_id)
	if entry == null or ItemDatabase.get_item(item_id) == null or resolve_price(entry) < 0:
		return "That item is unavailable."
	if get_stock(shop_id, item_id) == 0:
		return "SOLD OUT"
	if Wallet.get_yen() < resolve_price(entry):
		return "You don't have enough Yen."
	if not Inventory.can_add_item(item_id):
		return "Your inventory cannot hold another of this item."
	return ""


func buy_item(shop_id: StringName, item_id: StringName) -> bool:
	last_message = purchase_reason(shop_id, item_id)
	if not last_message.is_empty():
		return false
	var price: int = resolve_price(get_entry(shop_id, item_id))
	var stock: int = get_stock(shop_id, item_id)
	_buying = true
	# Reserve stock/balance before Inventory emits; listeners see all three committed.
	if stock > 0:
		_stocks[shop_id][item_id] = stock - 1
	if not Wallet.exchange_yen(price, 0, Inventory.add_item.bind(item_id, 1)):
		_stocks[shop_id][item_id] = stock
		_buying = false
		last_message = "Purchase failed; your Yen and stock were kept."
		return false
	if stock > 0:
		stock_changed.emit(shop_id, item_id, stock - 1)
	item_purchased.emit(shop_id, item_id, price)
	last_message = "Bought %s for %s." % [ItemDatabase.get_item(item_id).display_name, YenFormat.format(price)]
	_buying = false
	return true


func to_save_data() -> Dictionary:
	var data: Dictionary = {}
	for shop: ShopData in _shops.values():
		var limited: Dictionary = {}
		for entry: ShopEntryData in shop.entries:
			if entry.stock >= 0:
				limited[str(entry.item_id)] = get_stock(shop.id, entry.item_id)
		data[str(shop.id)] = limited
	return data


func load_save_data(data: Dictionary) -> void:
	_stocks.clear()
	_buying = false
	for shop: ShopData in _shops.values():
		var saved: Dictionary = SaveValues.dictionary(data.get(str(shop.id), {}))
		var stocks: Dictionary = {}
		for entry: ShopEntryData in shop.entries:
			stocks[entry.item_id] = SaveValues.integer(saved.get(str(entry.item_id), entry.stock), entry.stock, 0, entry.stock) if entry.stock >= 0 else -1
		_stocks[shop.id] = stocks
	last_message = ""


func reset_runtime_state() -> void:
	load_save_data({})

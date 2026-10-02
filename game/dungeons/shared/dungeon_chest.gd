extends TreasureChest

enum RewardKind { INVENTORY_ITEM, SMALL_KEY, DUNGEON_ITEM }

@export var dungeon_id: StringName
@export var chest_id: StringName
@export var reward_kind: RewardKind = RewardKind.INVENTORY_ITEM


func _ready() -> void:
	if dungeon_id.is_empty() or chest_id.is_empty():
		enabled = false
		push_error("Persistent dungeon chest needs stable IDs.")
		return
	is_open = DungeonManager.has_flag(dungeon_id, &"opened_chests", chest_id)
	if is_open:
		enabled = false
		$Lid.position.y = -10.0


func _can_grant_reward() -> bool:
	if reward_kind == RewardKind.SMALL_KEY:
		return reward_amount > 0
	if reward_kind == RewardKind.DUNGEON_ITEM:
		var item: ItemData = ItemDatabase.get_item(reward_item_id)
		return item != null and item.category == ItemData.ItemCategory.DUNGEON_ITEM and reward_amount == 1 and (Inventory.has_item(reward_item_id) or Inventory.can_add_item(reward_item_id))
	return super._can_grant_reward()


func _reward_message() -> String:
	if reward_kind == RewardKind.SMALL_KEY:
		return "You found a Small Key!" if reward_amount == 1 else "You found %d Small Keys!" % reward_amount
	return super._reward_message()


func _grant_reward() -> bool:
	if not _can_grant_reward():
		return false
	if reward_kind == RewardKind.SMALL_KEY:
		return DungeonManager.add_small_keys(dungeon_id, reward_amount)
	if reward_kind == RewardKind.DUNGEON_ITEM and Inventory.has_item(reward_item_id):
		return true # A development state reset never duplicates a unique item.
	return super._grant_reward()


func _reward_committed() -> void:
	DungeonManager.set_flag(dungeon_id, &"opened_chests", chest_id)
	if reward_kind == RewardKind.DUNGEON_ITEM:
		DungeonManager.mark_item_obtained(dungeon_id)

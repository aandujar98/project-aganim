class_name QuestRewardData
extends Resource

enum RewardType { ITEM, HEALTH_RESTORE, NOTHING, YEN }

@export var type: RewardType = RewardType.ITEM
@export var item_id: StringName
@export_range(1, 999999999, 1) var amount: int = 1


func is_valid_definition() -> bool:
	return type >= RewardType.ITEM and type <= RewardType.YEN and (type == RewardType.NOTHING or amount > 0) and (type != RewardType.ITEM or not item_id.is_empty())

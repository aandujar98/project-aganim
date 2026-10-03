class_name QuestDatabase
extends RefCounted

const QUEST_PATHS: Array[String] = [
	"res://game/quests/data/a_small_favor.tres",
	"res://game/quests/data/shrine_rumors_followup.tres"
]
var _quests: Dictionary = {}


func load_definitions() -> void:
	for path: String in QUEST_PATHS:
		register_quest(load(path) as QuestData)
	validate_prerequisites()


func register_quest(data: QuestData) -> bool:
	if data == null or not data.is_valid_definition():
		push_warning("QuestDatabase rejected invalid quest data.")
		return false
	if _quests.has(data.id):
		push_warning("Duplicate quest ID: " + str(data.id))
		return false
	for objective: QuestObjectiveData in data.objectives:
		if objective.type == QuestObjectiveData.ObjectiveType.COLLECT_ITEM:
			var item: ItemData = ItemDatabase.get_item(objective.target_id)
			if item == null or (objective.consume_on_turn_in and (item.category != ItemData.ItemCategory.QUEST_ITEM or objective.required_amount > item.quantity_limit())):
				push_warning("Invalid quest collection/turn-in item: " + str(objective.target_id))
				return false
	for reward: QuestRewardData in data.rewards:
		if reward.type == QuestRewardData.RewardType.ITEM and ItemDatabase.get_item(reward.item_id) == null:
			return false
	_quests[data.id] = data
	return true


func validate_prerequisites() -> bool:
	var valid: bool = true
	for data: QuestData in _quests.values():
		for prerequisite: StringName in data.prerequisite_quest_ids:
			if not _quests.has(prerequisite) or _has_cycle(data.id, prerequisite, {}):
				push_warning("Missing/cyclic quest prerequisite: %s -> %s" % [data.id, prerequisite])
				valid = false
	return valid


func _has_cycle(start: StringName, id: StringName, visited: Dictionary) -> bool:
	if id == start:
		return true
	if visited.has(id) or not _quests.has(id):
		return false
	visited[id] = true
	for next_id: StringName in get_quest(id).prerequisite_quest_ids:
		if _has_cycle(start, next_id, visited):
			return true
	return false


func get_quest(id: StringName) -> QuestData:
	return _quests.get(id) as QuestData


func get_all() -> Array[QuestData]:
	var data: Array[QuestData] = []
	for quest: QuestData in _quests.values():
		data.append(quest)
	return data

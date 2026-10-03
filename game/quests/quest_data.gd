class_name QuestData
extends Resource

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var objectives: Array[QuestObjectiveData] = []
@export var rewards: Array[QuestRewardData] = []
@export var prerequisite_quest_ids: Array[StringName] = []
@export var auto_complete: bool = true
@export var require_turn_in: bool = false
@export var turn_in_npc_id: StringName
@export var turn_in_description: String
@export var ready_message: String


func is_valid_definition() -> bool:
	if id.is_empty() or title.is_empty() or objectives.is_empty() or (require_turn_in and turn_in_npc_id.is_empty()):
		return false
	for objective: QuestObjectiveData in objectives:
		if objective == null or not objective.is_valid_definition() or (objective.consume_on_turn_in and not require_turn_in):
			return false
	for reward: QuestRewardData in rewards:
		if reward == null or not reward.is_valid_definition():
			return false
	return true

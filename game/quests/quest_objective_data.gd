class_name QuestObjectiveData
extends Resource

enum ObjectiveType { TALK_TO_NPC, COLLECT_ITEM, DEFEAT_ENEMY, REACH_LOCATION, INTERACT_WITH_OBJECT }

@export var type: ObjectiveType = ObjectiveType.COLLECT_ITEM
@export var target_id: StringName
@export_range(1, 999, 1) var required_amount: int = 1
@export_multiline var description: String
@export var consume_on_turn_in: bool = false


func is_valid_definition() -> bool:
	return not target_id.is_empty() and required_amount >= 1 and type >= 0 and type <= ObjectiveType.INTERACT_WITH_OBJECT and (not consume_on_turn_in or type == ObjectiveType.COLLECT_ITEM)

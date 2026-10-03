class_name QuestRuntime
extends RefCounted

enum QuestState { UNAVAILABLE, AVAILABLE, ACTIVE, COMPLETED, FAILED }

var quest_id: StringName
var state: QuestState = QuestState.UNAVAILABLE
var objective_progress: Array[int] = []
var objectives_complete: bool = false


func _init(id: StringName = &"") -> void:
	quest_id = id


func snapshot() -> QuestRuntime:
	var copy: QuestRuntime = QuestRuntime.new(quest_id)
	copy.state = state
	copy.objective_progress = objective_progress.duplicate()
	copy.objectives_complete = objectives_complete
	return copy

extends Area2D

@export var location_id: StringName
@export var trigger_once: bool = true
var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_try_player)
	SceneTransitions.transition_finished.connect(_on_arrival)


func _try_player(body: Node2D) -> void:
	if (trigger_once and _triggered) or not body.is_in_group("player"):
		return
	if body.state != body.PlayerState.NORMAL or body.is_transition_locked() or SceneTransitions.busy:
		return
	_triggered = true
	QuestManager.record_event(QuestObjectiveData.ObjectiveType.REACH_LOCATION, location_id)


func _on_arrival(_destination: String, _spawn_id: StringName) -> void:
	for body: Node2D in get_overlapping_bodies():
		_try_player(body)

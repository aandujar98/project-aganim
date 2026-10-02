class_name SceneEntrance
extends Interactable

enum TransitionMode { INTERACTION, AUTOMATIC }

@export_file("*.tscn") var destination_scene: String = ""
@export var destination_spawn_id: StringName = &"default"
@export var transition_mode: TransitionMode = TransitionMode.INTERACTION
@export var use_facing_override: bool = false
@export var facing_override: Vector2 = Vector2.DOWN

var _inside: bool = false
var _attempted: bool = false


func _ready() -> void:
	if transition_mode == TransitionMode.AUTOMATIC:
		collision_layer = 0
		collision_mask = 2
		monitorable = false
		monitoring = true


func interact(actor: Node, _manager: DialogueManager) -> void:
	if enabled and transition_mode == TransitionMode.INTERACTION:
		_request(actor as CharacterBody2D)


func _physics_process(_delta: float) -> void:
	if transition_mode != TransitionMode.AUTOMATIC or not enabled:
		return
	var actor: CharacterBody2D = null
	for body: Node2D in get_overlapping_bodies():
		if body is CharacterBody2D and body.is_in_group("player"):
			actor = body as CharacterBody2D
			break
	if actor == null:
		_inside = false
		_attempted = false
		return
	# Arrival overlaps must first leave the trigger; normal approaches can wait
	# for attack/hurt recovery before starting. Failed configuration logs once.
	if not _inside:
		_inside = true
		_attempted = SceneTransitions.busy or SceneTransitions.cooldown_remaining > 0.0
	if _attempted or SceneTransitions.busy or SceneTransitions.cooldown_remaining > 0.0:
		return
	if actor.state == actor.PlayerState.NORMAL and not actor.is_transition_locked():
		_attempted = true
		_request(actor)


func _request(actor: CharacterBody2D) -> void:
	var direction: Vector2 = facing_override if use_facing_override else Vector2.ZERO
	SceneTransitions.request_transition(destination_scene, destination_spawn_id, actor, direction)

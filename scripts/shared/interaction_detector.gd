class_name InteractionDetector
extends Node2D

signal target_changed(target: Interactable)

@export_range(8.0, 48.0, 1.0) var reach: float = 30.0
@export_range(8.0, 32.0, 1.0) var width: float = 20.0
@export_flags_2d_physics var interaction_mask: int = 128
@export_flags_2d_physics var world_mask: int = 1

var target: Interactable
var dialogue_manager: DialogueManager
var _shape: RectangleShape2D = RectangleShape2D.new()


func refresh(facing: Vector2, available: bool) -> void:
	var selected: Interactable = _find_target(facing) if available else null
	if selected != target:
		target = selected
		target_changed.emit(target)


func try_interact(actor: Node) -> bool:
	if not is_instance_valid(target) or not target.enabled:
		return false
	target.interact(actor, dialogue_manager)
	return true


func _find_target(facing: Vector2) -> Interactable:
	# Query the current transform directly, avoiding one-tick stale Area2D overlaps.
	_shape.size = Vector2(reach, width)
	var origin: Vector2 = global_position
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.transform = Transform2D(facing.angle(), origin + facing * reach * 0.5)
	query.collision_mask = interaction_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var selected: Interactable = null
	var best_distance: float = INF
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var candidate: Interactable = result.collider as Interactable
		if candidate == null or not candidate.enabled:
			continue
		var offset: Vector2 = candidate.global_position - origin
		if offset.dot(facing) <= 0.0 or not _unobstructed(origin, candidate):
			continue
		var distance: float = offset.length_squared()
		# Scene paths provide a stable tie-break independent of physics query order.
		if distance < best_distance or (is_equal_approx(distance, best_distance) and str(candidate.get_path()) < str(selected.get_path())):
			selected = candidate
			best_distance = distance
	return selected


func _unobstructed(origin: Vector2, candidate: Interactable) -> bool:
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, candidate.global_position, world_mask)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		return true
	var body: Node = hit.collider as Node
	if candidate.is_ancestor_of(body):
		return true
	# Coincident interactables share an endpoint; let the stable tie-break decide.
	var other: Interactable = body.get_parent() as Interactable
	return other != null and other.enabled and other.global_position.is_equal_approx(candidate.global_position)

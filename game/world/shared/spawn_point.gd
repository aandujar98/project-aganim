class_name SpawnPoint
extends Marker2D

@export var spawn_id: StringName = &"default"
@export var use_facing_direction: bool = true
@export var facing_direction: Vector2 = Vector2.DOWN


func arrival_facing(previous: Vector2, override_direction: Vector2) -> Vector2:
	var direction: Vector2 = override_direction
	if direction.is_zero_approx():
		direction = facing_direction if use_facing_direction else previous
	# Match the Player's existing cardinal facing convention.
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y >= 0.0 else Vector2.UP

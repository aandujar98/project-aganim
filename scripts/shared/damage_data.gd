class_name DamageData
extends RefCounted

var amount: int
var direction: Vector2
var knockback_force: float
var source_position: Vector2
var source_actor: Node2D


func _init(damage: int, source: Node2D, target_position: Vector2, force: float) -> void:
	amount = damage
	source_actor = source
	source_position = source.global_position
	knockback_force = force
	direction = source_position.direction_to(target_position)
	if direction.is_zero_approx():
		direction = Vector2.DOWN

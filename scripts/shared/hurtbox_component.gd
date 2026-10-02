class_name HurtboxComponent
extends Area2D

signal hit_received(hit: DamageData)

@export var health_path: NodePath = NodePath("../HealthComponent")
@export_range(0.0, 3.0, 0.05) var invulnerability_duration: float = 0.75
var enabled: bool = true
var invulnerability_remaining: float = 0.0

@onready var health: HealthComponent = get_node(health_path) as HealthComponent


func _physics_process(delta: float) -> void:
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)


func receive_hit(hit: DamageData) -> bool:
	if not enabled or invulnerability_remaining > 0.0 or not health.is_alive():
		return false
	if hit.amount <= 0 or hit.source_actor == get_parent():
		return false
	# Set the guard before emitting any damage signals.
	invulnerability_remaining = invulnerability_duration
	if not health.take_damage(hit.amount):
		return false
	hit_received.emit(hit)
	return true

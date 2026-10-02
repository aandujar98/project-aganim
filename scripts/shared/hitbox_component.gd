class_name HitboxComponent
extends Area2D

@export_range(1, 100, 1) var damage: int = 1
@export_range(0.0, 300.0, 5.0) var knockback_force: float = 110.0
@export var source_path: NodePath = NodePath("..")
@export_flags_2d_physics var world_mask: int = 1

var active: bool = false
var _active_remaining: float = 0.0
var _hit_targets: Dictionary = {}

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var source_actor: Node2D = get_node(source_path) as Node2D


func _ready() -> void:
	visible = false


func begin_attack(active_time: float) -> void:
	_hit_targets.clear()
	_active_remaining = maxf(active_time, 0.0)
	active = _active_remaining > 0.0
	visible = active


func end_attack() -> void:
	active = false
	_active_remaining = 0.0
	visible = false


func _physics_process(delta: float) -> void:
	if not active:
		return
	# Use the current shape transform; cached Area2D overlaps can lag a turn.
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var hurtbox: HurtboxComponent = result["collider"] as HurtboxComponent
		if hurtbox != null:
			_try_hit(hurtbox)
	_active_remaining -= delta
	if _active_remaining <= 0.0:
		end_attack()


func _try_hit(hurtbox: HurtboxComponent) -> void:
	var target: Node2D = hurtbox.get_parent() as Node2D
	if not active or target == source_actor or _hit_targets.has(hurtbox.get_instance_id()):
		return
	# World obstruction prevents melee damage through solid walls.
	var source_hurtbox: Node2D = source_actor.get_node_or_null("HurtboxComponent") as Node2D
	var origin: Vector2 = source_hurtbox.global_position if source_hurtbox != null else source_actor.global_position
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		origin, hurtbox.global_position, world_mask
	)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		return
	var hit: DamageData = DamageData.new(damage, source_actor, target.global_position, knockback_force)
	if hurtbox.receive_hit(hit):
		_hit_targets[hurtbox.get_instance_id()] = true

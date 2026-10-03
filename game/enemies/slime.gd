extends CharacterBody2D

enum EnemyState { IDLE, CHASING, ATTACKING, HURT, DEAD }

@export var persistent: bool = false
@export var persistent_id: StringName
@export var enemy_type_id: StringName = &"slime"
@export var movement_speed: float = 35.0
@export_range(8.0, 48.0, 1.0) var attack_range: float = 24.0
@export_range(0.05, 1.0, 0.01) var attack_duration: float = 0.25
@export_range(0.02, 0.5, 0.01) var attack_active_time: float = 0.10
@export_range(0.3, 3.0, 0.05) var attack_cooldown: float = 1.0
@export_range(0.05, 1.0, 0.01) var hurt_duration: float = 0.18
@export_range(0.05, 1.0, 0.01) var death_delay: float = 0.25

var state: EnemyState = EnemyState.IDLE
var target: CharacterBody2D
var _state_remaining: float = 0.0
var _cooldown_remaining: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _knockback_speed: float = 0.0

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var attack: HitboxComponent = $AttackHitbox
@onready var detection: Area2D = $DetectionArea
@onready var visuals: Node2D = $Visuals


func _ready() -> void:
	if persistent and persistent_id.is_empty():
		push_warning("Persistent enemy needs a stable ID: " + str(get_path()))
	if persistent and (persistent_id.is_empty() or get_node("/root/WorldState").has_flag(&"defeated_unique_enemies", persistent_id)):
		queue_free()
		return
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit)
	detection.body_exited.connect(_on_target_exited)


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	match state:
		EnemyState.DEAD:
			_state_remaining -= delta
			if _state_remaining <= 0.0:
				queue_free()
			return
		EnemyState.HURT:
			velocity = _knockback
			_knockback = _knockback.move_toward(Vector2.ZERO, _knockback_speed * delta / hurt_duration)
			_state_remaining -= delta
			if _state_remaining <= 0.0:
				state = EnemyState.IDLE
		EnemyState.ATTACKING:
			velocity = Vector2.ZERO
			_state_remaining -= delta
			if _state_remaining <= 0.0:
				attack.end_attack()
				state = EnemyState.IDLE
		_:
			_update_chase()
	move_and_slide()
	visuals.modulate = Color(1.0, 0.35, 0.35) if hurtbox.invulnerability_remaining > 0.0 else Color.WHITE


func _update_chase() -> void:
	if not is_instance_valid(target) or not target.is_in_group("player"):
		target = null
		for body: Node2D in detection.get_overlapping_bodies():
			if body is CharacterBody2D and body.is_in_group("player"):
				target = body as CharacterBody2D
				break
	if target == null:
		state = EnemyState.IDLE
		velocity = Vector2.ZERO
		return
	var distance: float = global_position.distance_to(target.global_position)
	if distance <= attack_range:
		velocity = Vector2.ZERO
		if _cooldown_remaining <= 0.0:
			state = EnemyState.ATTACKING
			_state_remaining = attack_duration
			_cooldown_remaining = attack_cooldown
			attack.begin_attack(minf(attack_active_time, attack_duration))
	else:
		state = EnemyState.CHASING
		velocity = global_position.direction_to(target.global_position) * movement_speed


func _on_target_exited(body: Node2D) -> void:
	if body == target:
		target = null


func _on_hit(hit: DamageData) -> void:
	if state == EnemyState.DEAD:
		return
	attack.end_attack()
	state = EnemyState.HURT
	_state_remaining = hurt_duration
	_knockback_speed = hit.knockback_force
	_knockback = hit.direction * _knockback_speed


func _on_died() -> void:
	if state == EnemyState.DEAD:
		return
	if persistent:
		get_node("/root/WorldState").set_flag(&"defeated_unique_enemies", persistent_id)
	get_node("/root/QuestManager").record_event(QuestObjectiveData.ObjectiveType.DEFEAT_ENEMY, enemy_type_id)
	state = EnemyState.DEAD
	_state_remaining = death_delay
	velocity = Vector2.ZERO
	attack.end_attack()
	hurtbox.enabled = false
	collision_layer = 0
	collision_mask = 0
	visuals.modulate = Color(0.35, 0.35, 0.35)


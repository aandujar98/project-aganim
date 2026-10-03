extends CharacterBody2D

signal state_changed(value: int)
signal attack_started
signal attack_finished
signal interaction_cancelled(interaction_owner: Node)

enum PlayerState { NORMAL, ATTACKING, HURT, DEAD, INTERACTING }

@export var movement_speed: float = 90.0
## Speed while the sprint action is held; plays the run_* animations.
@export var run_speed: float = 135.0
@export_range(0.05, 1.0, 0.01) var attack_duration: float = 0.25
@export_range(0.02, 0.5, 0.01) var attack_active_time: float = 0.10
@export_range(0.05, 1.0, 0.01) var hurt_duration: float = 0.18
## Sword placement relative to the feet origin: center of the body plus reach along facing.
@export var sword_origin: Vector2 = Vector2(0, -10)
@export_range(8.0, 40.0, 1.0) var sword_reach: float = 20.0

const SPRITE_DIRECTIONS: Array[String] = ["right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right"]

var facing_direction: Vector2 = Vector2.DOWN
## Eight-way facing used only to pick sprite animations; gameplay facing stays cardinal.
var sprite_direction: Vector2 = Vector2.DOWN
var _sprite_synced_facing: Vector2 = Vector2.DOWN
var _running: bool = false
var state: PlayerState = PlayerState.NORMAL
var _transition_owner: Node
var _interaction_owner: Node
var _state_remaining: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _knockback_speed: float = 0.0

@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var visuals: Node2D = $Visuals
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var interaction_detector: InteractionDetector = $InteractionDetector
@onready var sword: HitboxComponent = $SwordHitbox


func _ready() -> void:
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit)
	_update_animation(false)


func _physics_process(delta: float) -> void:
	match state:
		PlayerState.NORMAL:
			if is_transition_locked():
				velocity = Vector2.ZERO
			else:
				_move_normal()
		PlayerState.ATTACKING:
			velocity = Vector2.ZERO
			_state_remaining -= delta
			if _state_remaining <= 0.0:
				_finish_attack()
		PlayerState.HURT:
			velocity = _knockback
			_knockback = _knockback.move_toward(Vector2.ZERO, _knockback_speed * delta / hurt_duration)
			_state_remaining -= delta
			if _state_remaining <= 0.0:
				_set_state(PlayerState.NORMAL)
		PlayerState.INTERACTING:
			velocity = Vector2.ZERO
			if not is_instance_valid(_interaction_owner):
				_set_state(PlayerState.NORMAL)
		PlayerState.DEAD:
			velocity = Vector2.ZERO
	if state != PlayerState.DEAD:
		move_and_slide()
	if state == PlayerState.NORMAL:
		_update_animation(get_real_velocity().length_squared() > 0.01)
	interaction_detector.refresh(facing_direction, state == PlayerState.NORMAL and not is_transition_locked())
	_update_damage_feedback()


func _move_normal() -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not direction.is_zero_approx():
		# Horizontal wins only when stronger; equal diagonals face vertically.
		if absf(direction.x) > absf(direction.y):
			facing_direction = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
		else:
			facing_direction = Vector2.DOWN if direction.y > 0.0 else Vector2.UP
		sprite_direction = Vector2.from_angle(roundi(direction.angle() / (PI / 4.0)) * (PI / 4.0))
		_sprite_synced_facing = facing_direction
	_running = not direction.is_zero_approx() and Input.is_action_pressed("sprint")
	velocity = direction * (run_speed if _running else movement_speed)
	if Input.is_action_just_pressed("attack"):
		_begin_attack()


func _begin_attack() -> void:
	_set_state(PlayerState.ATTACKING)
	_state_remaining = attack_duration
	velocity = Vector2.ZERO
	_update_animation(false)
	# Freeze the stored facing for the whole swing; no diagonal attack shapes.
	sword.position = sword_origin + facing_direction * sword_reach
	sword.rotation = facing_direction.angle() - PI / 2.0
	sword.begin_attack(minf(attack_active_time, attack_duration))
	attack_started.emit()


func _finish_attack() -> void:
	sword.end_attack()
	_set_state(PlayerState.NORMAL)
	attack_finished.emit()


func _on_hit(hit: DamageData) -> void:
	if state == PlayerState.DEAD:
		return
	if state == PlayerState.ATTACKING:
		sword.end_attack()
		attack_finished.emit()
	_set_state(PlayerState.HURT)
	_cancel_interaction()
	_state_remaining = hurt_duration
	_knockback_speed = hit.knockback_force
	_knockback = hit.direction * _knockback_speed
	_update_animation(false)


func _on_died() -> void:
	if state == PlayerState.ATTACKING:
		attack_finished.emit()
	sword.end_attack()
	hurtbox.enabled = false
	_set_state(PlayerState.DEAD)
	_cancel_interaction()
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	remove_from_group("player")
	animations.stop()
	print("Player defeated. Stop and run DevTest again (F6) to restart.")


func _set_state(value: PlayerState) -> void:
	if state != value:
		state = value
		state_changed.emit(state)


func _update_damage_feedback() -> void:
	if state == PlayerState.DEAD:
		visuals.modulate = Color(0.4, 0.4, 0.4)
	elif state == PlayerState.HURT:
		visuals.modulate = Color(1.0, 0.35, 0.35)
	elif hurtbox.invulnerability_remaining > 0.0:
		visuals.modulate = Color(1, 1, 1, 0.4 if int(hurtbox.invulnerability_remaining * 12) % 2 == 0 else 1.0)
	else:
		visuals.modulate = Color.WHITE


func _update_animation(is_moving: bool) -> void:
	# Facing set from outside (spawns, transitions, loads) overrides the last movement direction.
	if facing_direction != _sprite_synced_facing:
		sprite_direction = facing_direction
		_sprite_synced_facing = facing_direction
	var index: int = wrapi(roundi(sprite_direction.angle() / (PI / 4.0)), 0, 8)
	var prefix: String = "idle_"
	if is_moving:
		prefix = "run_" if _running else "walk_"
	var animation: StringName = StringName(prefix + SPRITE_DIRECTIONS[index])
	if animations.current_animation != animation:
		animations.play(animation)
		animations.advance(0.0)


func _unhandled_input(event: InputEvent) -> void:
	if state != PlayerState.NORMAL or is_transition_locked() or not event.is_action_pressed("interact") or event.is_echo():
		return
	# Update immediately to prevent stale selection after a turn/teleport.
	interaction_detector.refresh(facing_direction, true)
	if interaction_detector.try_interact(self):
		get_viewport().set_input_as_handled()


func begin_interaction(interaction_owner: Node) -> bool:
	if state != PlayerState.NORMAL or is_transition_locked():
		return false
	_interaction_owner = interaction_owner
	_set_state(PlayerState.INTERACTING)
	velocity = Vector2.ZERO
	_update_animation(false)
	return true


func end_interaction(interaction_owner: Node) -> void:
	if interaction_owner != _interaction_owner:
		return
	_interaction_owner = null
	# A late UI callback must never restore control over hurt/death.
	if state == PlayerState.INTERACTING:
		_set_state(PlayerState.NORMAL)


func _cancel_interaction() -> void:
	if is_instance_valid(_interaction_owner):
		var interaction_owner: Node = _interaction_owner
		_interaction_owner = null
		interaction_cancelled.emit(interaction_owner)


func is_transition_locked() -> bool:
	return is_instance_valid(_transition_owner)


func begin_transition(lock_owner: Node) -> bool:
	if not begin_interaction(lock_owner):
		return false
	_transition_owner = lock_owner
	return true


func end_transition(lock_owner: Node) -> void:
	if lock_owner != _transition_owner:
		return
	end_interaction(lock_owner)
	_transition_owner = null


func capture_runtime_state() -> Dictionary:
	return {"health": health.current_health, "max_health": health.max_health,
		"facing": facing_direction, "invulnerability": hurtbox.invulnerability_remaining}


func apply_runtime_state(data: Dictionary) -> void:
	health.max_health = int(data["max_health"])
	health.current_health = clampi(int(data["health"]), 1, health.max_health)
	hurtbox.invulnerability_remaining = float(data["invulnerability"])
	facing_direction = data["facing"] as Vector2
	health.health_changed.emit(health.current_health, health.max_health)

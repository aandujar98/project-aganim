extends CanvasLayer

signal transition_started(destination: String, spawn_id: StringName)
signal transition_finished(destination: String, spawn_id: StringName)
signal transition_failed(reason: String)

@export_range(0.0, 1.0, 0.05) var fade_out_duration: float = 0.25
@export_range(0.0, 1.0, 0.05) var fade_in_duration: float = 0.25
@export_range(0.0, 1.0, 0.05) var arrival_cooldown: float = 0.25

var busy: bool = false
var cooldown_remaining: float = 0.0
var _cancelled: bool = false
var _actor: CharacterBody2D

@onready var fade: ColorRect = $Fade


func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)


func request_transition(destination: String, spawn_id: StringName, actor: CharacterBody2D, facing: Vector2 = Vector2.ZERO) -> bool:
	if busy or cooldown_remaining > 0.0:
		return false
	if not is_instance_valid(actor) or not actor.is_in_group("player"):
		_fail("Transition needs a living Player reference.")
		return false
	var source: Node = get_tree().current_scene
	if source == null or not source.is_ancestor_of(actor):
		_fail("Player must belong to the current scene.")
		return false
	if actor.state != actor.PlayerState.NORMAL or actor.is_transition_locked():
		return false
	# Preflight before fading/removing anything. Destinations use a WorldArea root.
	if not ResourceLoader.exists(destination, "PackedScene"):
		_fail("Destination scene does not exist: " + destination)
		return false
	var packed: PackedScene = load(destination) as PackedScene
	if packed == null:
		_fail("Destination could not load: " + destination)
		return false
	var candidate: Node = packed.instantiate()
	var area: WorldArea = candidate as WorldArea
	if area == null or area.find_player() == null or area.resolve_spawn(area.default_spawn_id) == null:
		candidate.free()
		_fail("Destination requires WorldArea, one Player, and a default spawn: " + destination)
		return false
	var bounds: CameraBounds = area.get_camera_bounds()
	var spawn: SpawnPoint = area.resolve_spawn(spawn_id)
	if bounds == null or not bounds.is_valid() or spawn == null:
		candidate.free()
		_fail("Destination needs viewport-sized camera bounds and a safe spawn: " + destination)
		return false
	if not actor.begin_transition(self):
		candidate.free()
		return false
	busy = true
	_cancelled = false
	_watch_actor(actor)
	transition_started.emit(destination, spawn_id)
	print("Transition: %s -> %s; requested '%s', resolved '%s'." % [source.scene_file_path, destination, spawn_id, spawn.spawn_id])
	# Entrance calls can occur during physics; scene mutations must be deferred.
	_travel.call_deferred(source, area, spawn, facing)
	return true


func _travel(source: Node, area: WorldArea, spawn: SpawnPoint, facing: Vector2) -> void:
	await _fade_to(1.0, fade_out_duration)
	if _cancelled or not is_instance_valid(_actor) or not is_instance_valid(source) or get_tree().current_scene != source:
		area.free()
		_fail("Transition cancelled before scene replacement.")
	else:
		var runtime: Dictionary = _actor.capture_runtime_state()
		var direction: Vector2 = spawn.arrival_facing(_actor.facing_direction, facing)
		_unwatch_actor()
		# Detach old scene before adding the new one: never two live Players.
		get_tree().root.remove_child(source)
		source.queue_free()
		get_tree().root.add_child(area)
		get_tree().current_scene = area
		var arriving: CharacterBody2D = area.find_player()
		arriving.apply_runtime_state(runtime)
		arriving.begin_transition(self)
		_watch_actor(arriving)
		area.place_player(arriving, spawn, direction)
		# Let camera/physics register before revealing the destination.
		await get_tree().physics_frame
	await _fade_to(0.0, fade_in_duration)
	if is_instance_valid(_actor):
		_actor.end_transition(self)
	_unwatch_actor()
	busy = false
	cooldown_remaining = arrival_cooldown
	if _cancelled and is_instance_valid(area):
		_fail("Player interrupted the transition after arrival; keeping the loaded area.")
	if not _cancelled and is_instance_valid(area):
		transition_finished.emit(area.scene_file_path, spawn.spawn_id)


func _fade_to(alpha: float, duration: float) -> void:
	fade.show()
	if duration > 0.0:
		var tween: Tween = create_tween()
		tween.tween_property(fade, "color:a", alpha, duration)
		await tween.finished
	else:
		fade.color.a = alpha
	if alpha == 0.0:
		fade.hide()


func _watch_actor(actor: CharacterBody2D) -> void:
	_actor = actor
	_actor.interaction_cancelled.connect(_on_cancelled)


func _unwatch_actor() -> void:
	if is_instance_valid(_actor) and _actor.interaction_cancelled.is_connected(_on_cancelled):
		_actor.interaction_cancelled.disconnect(_on_cancelled)
	_actor = null


func _on_cancelled(interaction_owner: Node) -> void:
	if interaction_owner == self:
		_cancelled = true


func _fail(reason: String) -> void:
	push_warning(reason)
	transition_failed.emit(reason)

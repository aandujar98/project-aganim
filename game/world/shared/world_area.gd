class_name WorldArea
extends Node2D

@export var dungeon_id: StringName = &""
@export var default_spawn_id: StringName = &"default"
@export var camera_bounds_path: NodePath = ^"CameraBounds"


func _ready() -> void:
	DungeonManager.enter_dungeon(dungeon_id)
	var player: CharacterBody2D = find_player()
	var spawn: SpawnPoint = resolve_spawn(default_spawn_id)
	if player == null or spawn == null:
		push_error("WorldArea needs one Player and a default spawn: " + scene_file_path)
		return
	place_player(player, spawn, spawn.arrival_facing(player.facing_direction, Vector2.ZERO))
	var dialogue: DialogueManager = get_node_or_null("DialogueUI") as DialogueManager
	player.interaction_detector.dialogue_manager = dialogue
	player.health.health_changed.connect(_refresh_debug.unbind(2))
	player.state_changed.connect(_refresh_debug.unbind(1))
	player.interaction_detector.target_changed.connect(_refresh_debug.unbind(1))
	_refresh_debug()


func find_player() -> CharacterBody2D:
	var found: CharacterBody2D = null
	for node: Node in find_children("*", "", true, false):
		if node is CharacterBody2D and node.is_in_group("player"):
			if found != null:
				return null # Reject duplicate players rather than silently picking one.
			found = node as CharacterBody2D
	return found


func resolve_spawn(requested_id: StringName) -> SpawnPoint:
	var points: Dictionary = {}
	for node: Node in find_children("*", "", true, false):
		if node is SpawnPoint:
			var spawn: SpawnPoint = node as SpawnPoint
			if points.has(spawn.spawn_id):
				push_warning("Duplicate spawn ID '%s' in %s" % [spawn.spawn_id, scene_file_path])
				return null
			points[spawn.spawn_id] = spawn
	if points.has(requested_id):
		return points[requested_id] as SpawnPoint
	if points.has(default_spawn_id):
		push_warning("Spawn '%s' missing in %s; using '%s'." % [requested_id, scene_file_path, default_spawn_id])
		return points[default_spawn_id] as SpawnPoint
	push_warning("Spawn '%s' and default '%s' are missing in %s." % [requested_id, default_spawn_id, scene_file_path])
	return null


func get_camera_bounds() -> CameraBounds:
	return get_node_or_null(camera_bounds_path) as CameraBounds


func place_player(player: CharacterBody2D, spawn: SpawnPoint, facing: Vector2) -> void:
	player.global_position = spawn.global_position.round()
	player.velocity = Vector2.ZERO
	player.facing_direction = facing
	player.call("_update_animation", false)
	player.camera.global_position = player.global_position.round()
	var camera_bounds: CameraBounds = get_camera_bounds()
	if camera_bounds != null:
		camera_bounds.apply_to(player.camera)
	player.camera.make_current()
	player.camera.reset_smoothing()
	player.camera.force_update_scroll()


func _refresh_debug() -> void:
	var label: Label = get_node_or_null("DebugOverlay/Status") as Label
	var player: CharacterBody2D = find_player()
	if label == null or player == null:
		return
	var target: Interactable = player.interaction_detector.target
	label.text = "%s · HP %d/%d\n%s" % [name, player.health.current_health, player.health.max_health,
		"Interact · " + target.interaction_text if is_instance_valid(target) else "Move: WASD / arrows / stick"]

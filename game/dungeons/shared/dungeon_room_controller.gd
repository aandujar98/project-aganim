extends Node

enum Encounter { NORMAL, MINIBOSS, BOSS }

@export var dungeon_id: StringName
@export var room_id: StringName
@export var clear_required: bool = false
@export var enemies_path: NodePath = ^"../Enemies"
@export var encounter: Encounter = Encounter.NORMAL

var _alive: Dictionary = {}


func _ready() -> void:
	if dungeon_id.is_empty() or room_id.is_empty():
		push_error("Dungeon room controller requires stable dungeon and room IDs.")
		return
	if not clear_required:
		return
	var enemies: Node = get_node_or_null(enemies_path)
	if enemies == null:
		push_error("Clear-required room needs a designated enemy container.")
		return
	if DungeonManager.has_flag(dungeon_id, &"cleared_rooms", room_id):
		for enemy: Node in enemies.get_children():
			enemies.remove_child(enemy)
			enemy.queue_free()
		return
	var registered: Dictionary = {}
	for enemy: Node in enemies.get_children():
		var health: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
		if health == null:
			push_error("Every required enemy needs a HealthComponent.")
			return # Validate the entire container before connecting any death signals.
		if health.is_alive():
			registered[enemy.get_instance_id()] = health
	for enemy_id: int in registered:
		var health: HealthComponent = registered[enemy_id]
		_alive[enemy_id] = true
		health.died.connect(_on_enemy_died.bind(enemy_id), CONNECT_ONE_SHOT)
	_check_clear()


func _on_enemy_died(enemy_id: int) -> void:
	_alive.erase(enemy_id)
	_check_clear()


func _check_clear() -> void:
	if _alive.is_empty():
		DungeonManager.finish_room(dungeon_id, room_id, encounter)

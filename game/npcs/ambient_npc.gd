@tool
class_name AmbientNPC
extends StaticBody2D
## Background pedestrian: a character sheet, a facing row, a looping 4-frame idle,
## and an optional accessory (umbrella, speech bubble). Not interactive; use
## npc.tscn for anyone the player can talk to.

const ROWS: Dictionary = {"down": 0, "right": 2, "up": 4, "left": 6}

@export var sheet: Texture2D:
	set(value):
		sheet = value
		_apply()
@export_enum("down", "right", "up", "left") var facing: String = "down":
	set(value):
		facing = value
		_apply()
@export var accessory: Texture2D:
	set(value):
		accessory = value
		_apply()
@export var accessory_offset: Vector2i = Vector2i(0, -28):
	set(value):
		accessory_offset = value
		_apply()
@export_range(0.1, 1.0, 0.05) var frame_time: float = 0.25

var _elapsed: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var accessory_sprite: Sprite2D = $Accessory


func _ready() -> void:
	# Desynchronize idle loops so a crowd does not breathe in unison.
	_elapsed = fposmod(global_position.x * 0.37 + global_position.y * 0.11, frame_time * 4.0)
	_apply()


func _process(delta: float) -> void:
	_elapsed += delta
	sprite.frame_coords = Vector2i(int(_elapsed / frame_time) % 4, ROWS[facing])


func _apply() -> void:
	if not is_node_ready():
		return
	sprite.texture = sheet
	sprite.frame_coords = Vector2i(0, ROWS[facing])
	accessory_sprite.texture = accessory
	accessory_sprite.position = Vector2(accessory_offset)

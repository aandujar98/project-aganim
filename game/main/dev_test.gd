extends Node2D

@export var show_combat_debug: bool = true

@onready var player: CharacterBody2D = $Player
@onready var health: HealthComponent = $Player/HealthComponent
@onready var label: Label = $DebugOverlay/HealthLabel


func _ready() -> void:
	$DebugOverlay.visible = show_combat_debug
	health.health_changed.connect(_on_health_changed)
	player.state_changed.connect(_on_state_changed)

	player.interaction_detector.dialogue_manager = $DialogueUI
	player.interaction_detector.target_changed.connect(_on_target_changed)
	_refresh_debug()


func _on_target_changed(target: Interactable) -> void:
	$DebugOverlay/InteractionPrompt.text = "Interact · " + target.interaction_text if is_instance_valid(target) else ""


func _on_health_changed(_current: int, _maximum: int) -> void:
	_refresh_debug()


func _on_state_changed(_state: int) -> void:
	_refresh_debug()


func _refresh_debug() -> void:
	var state_names: Array[String] = ["NORMAL", "ATTACKING", "HURT", "DEAD", "INTERACTING"]
	label.text = "HP %d/%d · %s\nAttack: Space / J / gamepad south\nInventory: I / gamepad Back" % [
		health.current_health, health.max_health, state_names[player.state]
	]

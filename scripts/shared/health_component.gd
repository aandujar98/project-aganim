class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal died

@export_range(1, 100, 1) var max_health: int = 3
var current_health: int


func _ready() -> void:
	current_health = max_health


func is_alive() -> bool:
	return current_health > 0


func take_damage(amount: int) -> bool:
	if amount <= 0 or not is_alive():
		return false
	var applied: int = mini(amount, current_health)
	current_health -= applied
	health_changed.emit(current_health, max_health)
	damaged.emit(applied)
	if current_health == 0:
		died.emit()
	return true


func heal(amount: int) -> int:
	if amount <= 0 or not is_alive():
		return 0
	var restored: int = mini(amount, maxi(0, max_health - current_health))
	if restored > 0:
		current_health += restored
		health_changed.emit(current_health, max_health)
	return restored

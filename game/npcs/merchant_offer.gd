class_name MerchantOffer
extends Node

@export var shop_id: StringName
@export var greeting: DialogueData
var _actor: CharacterBody2D
var _manager: DialogueManager
var _buy_requested: bool = false


func interact(actor: Node, manager: DialogueManager) -> bool:
	var npc: Interactable = get_parent() as Interactable
	if npc == null or not is_instance_valid(manager) or not manager.can_start(greeting):
		return false
	if not npc._begin(actor):
		return false
	_actor = actor as CharacterBody2D
	_manager = manager
	_buy_requested = false
	npc._dialogue = manager
	if not manager.start(greeting, actor, npc, _on_finished, "Need anything?", _on_choice, "Buy", "Leave"):
		npc._finish()
		return false
	return true


func _on_choice(buy: bool) -> void:
	_buy_requested = buy


func _on_finished() -> void:
	var open_shop: bool = _buy_requested and is_instance_valid(_manager) and not _manager.last_cancelled
	var actor: CharacterBody2D = _actor
	get_parent()._finish()
	_actor = null
	_manager = null
	_buy_requested = false
	if open_shop and is_instance_valid(actor):
		get_node("/root/ShopScreen").open_shop(shop_id, actor)

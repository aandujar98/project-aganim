class_name QuestOffer
extends Node

@export var quest_id: StringName
@export var offer_dialogue: DialogueData
@export var active_dialogue: DialogueData
@export var turn_in_dialogue: DialogueData
@export var completed_dialogue: DialogueData
@export var unavailable_dialogue: DialogueData
@export var offer_prompt: String = "Will you help?"

var _manager: DialogueManager
var _actor: CharacterBody2D


func interact(actor: Node, manager: DialogueManager) -> bool:
	var npc: Interactable = get_parent() as Interactable
	if npc == null or not is_instance_valid(manager):
		return false
	var data: DialogueData
	var finished: Callable = npc._finish
	var prompt: String = ""
	var chosen: Callable
	match QuestManager.get_state(quest_id):
		QuestRuntime.QuestState.AVAILABLE:
			data = offer_dialogue
			prompt = offer_prompt
			chosen = _on_choice
		QuestRuntime.QuestState.ACTIVE:
			data = turn_in_dialogue if QuestManager.is_ready_to_turn_in(quest_id) else active_dialogue
			if QuestManager.is_ready_to_turn_in(quest_id):
				finished = _on_turn_in_finished
		QuestRuntime.QuestState.COMPLETED:
			data = completed_dialogue
		_:
			data = unavailable_dialogue
	if not manager.can_start(data) or not npc._begin(actor):
		return false
	_actor = actor as CharacterBody2D
	_manager = manager
	npc._dialogue = manager
	if not manager.start(data, actor, npc, finished, prompt, chosen):
		npc._finish()
		return false
	return true


func _on_choice(accepted: bool) -> void:
	if accepted:
		QuestManager.accept_quest(quest_id)


func _on_turn_in_finished() -> void:
	# Cancel/damage/death/removal closes dialogue without handing anything in.
	if is_instance_valid(_manager) and not _manager.last_cancelled and is_instance_valid(_actor):
		QuestManager.turn_in_quest(quest_id, get_parent().npc_id, _actor)
	get_parent()._finish()
	_actor = null
	_manager = null

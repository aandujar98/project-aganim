class_name Interactable
extends Area2D

signal interaction_started
signal interaction_finished

@export var object_id: StringName
@export var interaction_text: String = "Interact"
@export var enabled: bool = true

var _player: Node
var _dialogue: DialogueManager


# All world objects use this contract; the Player never branches on object type.
func interact(_actor: Node, _manager: DialogueManager) -> void:
	pass


func _begin(actor: Node) -> bool:
	if not enabled or is_instance_valid(_player):
		return false
	if not actor.call("begin_interaction", self):
		return false
	_player = actor
	_player.interaction_cancelled.connect(_on_cancelled)
	interaction_started.emit()
	get_node("/root/QuestManager").record_event(QuestObjectiveData.ObjectiveType.INTERACT_WITH_OBJECT, object_id)
	# Event listeners may cancel interaction through hurt/death or scene removal.
	return is_instance_valid(_player) and _player.is_inside_tree()


func _show_dialogue(actor: Node, manager: DialogueManager, data: DialogueData) -> bool:
	if not is_instance_valid(manager) or not manager.can_start(data):
		return false
	if _begin(actor):
		_dialogue = manager
		if manager.start(data, actor, self, _finish):
			return true
		_finish()
	return false


func _finish() -> void:
	if is_instance_valid(_player):
		if _player.interaction_cancelled.is_connected(_on_cancelled):
			_player.interaction_cancelled.disconnect(_on_cancelled)
		_player.call("end_interaction", self)
	_player = null
	_dialogue = null
	interaction_finished.emit()


func _on_cancelled(interaction_owner: Node) -> void:
	if interaction_owner == self:
		_cancel()


func _cancel() -> void:
	if is_instance_valid(_dialogue) and _dialogue.active:
		_dialogue.cancel(self)
	else:
		_finish()


func _exit_tree() -> void:
	if is_instance_valid(_player):
		_cancel()

extends Interactable

@export var message: DialogueData


func interact(actor: Node, manager: DialogueManager) -> void:
	_show_dialogue(actor, manager, message)

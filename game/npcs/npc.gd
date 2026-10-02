extends Interactable

@export var dialogue: DialogueData


func interact(actor: Node, manager: DialogueManager) -> void:
	_show_dialogue(actor, manager, dialogue)

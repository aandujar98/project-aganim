extends SceneEntrance

@export var locked: bool = false
@export var locked_message: DialogueData


func _ready() -> void:
	# Physical scene doors always require the shared facing-based interaction.
	transition_mode = TransitionMode.INTERACTION
	super._ready()
	$Visual.color = Color(0.66, 0.3, 0.35) if locked else Color(0.3, 0.65, 0.72)


func interact(actor: Node, manager: DialogueManager) -> void:
	if locked:
		_show_dialogue(actor, manager, locked_message)
	else:
		super.interact(actor, manager)

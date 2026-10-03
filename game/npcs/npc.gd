extends Interactable

@export var npc_id: StringName
@export var dialogue: DialogueData
@export var merchant_offer_path: NodePath = ^"MerchantOffer"
@export var quest_offer_path: NodePath = ^"QuestOffer"


func interact(actor: Node, manager: DialogueManager) -> void:
	var offer: QuestOffer = get_node_or_null(quest_offer_path) as QuestOffer
	var merchant: MerchantOffer = get_node_or_null(merchant_offer_path) as MerchantOffer
	var started: bool
	if merchant != null:
		started = merchant.interact(actor, manager)
	else:
		started = offer.interact(actor, manager) if offer != null else _show_dialogue(actor, manager, dialogue)
	if started:
		QuestManager.record_event(QuestObjectiveData.ObjectiveType.TALK_TO_NPC, npc_id)

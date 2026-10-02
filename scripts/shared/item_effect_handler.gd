class_name ItemEffectHandler
extends RefCounted


static func failure_reason(item: ItemData, actor: CharacterBody2D) -> String:
	if not is_instance_valid(actor) or not actor.is_in_group("player"):
		return "No living player can use this item."
	if actor.is_transition_locked() or SceneTransitions.busy:
		return "Items cannot be used during a transition."
	if actor.state != actor.PlayerState.NORMAL and actor.state != actor.PlayerState.INTERACTING:
		return "Items cannot be used in the current player state."
	var health: HealthComponent = actor.get_node_or_null("HealthComponent") as HealthComponent
	if health == null or not health.is_alive():
		return "No living player can use this item."
	if item.category != ItemData.ItemCategory.CONSUMABLE or item.use_effect.is_empty():
		return "This item cannot be used."
	match item.use_effect:
		&"heal_player":
			if item.effect_value <= 0:
				return "The healing effect is not configured."
			if health.current_health >= health.max_health:
				return "Health is already full."
		_:
			push_warning("Unsupported item effect: " + str(item.use_effect))
			return "This item effect is not supported yet."
	return ""


static func apply(item: ItemData, actor: CharacterBody2D) -> bool:
	if not failure_reason(item, actor).is_empty():
		return false
	match item.use_effect:
		&"heal_player":
			var health: HealthComponent = actor.get_node("HealthComponent") as HealthComponent
			return health.heal(item.effect_value) > 0
	return false

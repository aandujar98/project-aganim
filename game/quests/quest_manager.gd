extends Node

signal quest_state_changed(quest_id: StringName)
signal objective_updated(quest_id: StringName, objective_index: int)
signal notification_requested(message: String)

var database: QuestDatabase = QuestDatabase.new()
var last_error: String = ""
var _runtime: Dictionary = {}
var _pending_completion: Dictionary = {}
var _reward_in_progress: bool = false
var _restore_epoch: int = 0


func _ready() -> void:
	database.load_definitions()
	for data: QuestData in database.get_all():
		_runtime[data.id] = QuestRuntime.new(data.id)
	_refresh_availability()
	Inventory.item_added.connect(_on_item_added)
	Inventory.inventory_changed.connect(_retry_auto_completion)
	Wallet.yen_changed.connect(_retry_auto_completion.unbind(1))


func register_quest(data: QuestData) -> bool:
	if not database.register_quest(data):
		return false
	_runtime[data.id] = QuestRuntime.new(data.id)
	database.validate_prerequisites()
	make_available(data.id)
	return true


func get_definition(id: StringName) -> QuestData:
	return database.get_quest(id)


func get_runtime(id: StringName) -> QuestRuntime:
	var runtime: QuestRuntime = _runtime.get(id) as QuestRuntime
	return runtime.snapshot() if runtime != null else null


func get_state(id: StringName) -> QuestRuntime.QuestState:
	var runtime: QuestRuntime = _runtime.get(id) as QuestRuntime
	return runtime.state if runtime != null else QuestRuntime.QuestState.UNAVAILABLE


func is_active(id: StringName) -> bool:
	return get_state(id) == QuestRuntime.QuestState.ACTIVE


func is_completed(id: StringName) -> bool:
	return get_state(id) == QuestRuntime.QuestState.COMPLETED


func is_ready_to_turn_in(id: StringName) -> bool:
	var runtime: QuestRuntime = _runtime.get(id) as QuestRuntime
	var data: QuestData = get_definition(id)
	return runtime != null and data != null and is_active(id) and data.require_turn_in and runtime.objectives_complete


func make_available(id: StringName) -> bool:
	var data: QuestData = get_definition(id)
	if data == null or get_state(id) != QuestRuntime.QuestState.UNAVAILABLE:
		return false
	for prerequisite: StringName in data.prerequisite_quest_ids:
		if not is_completed(prerequisite):
			return false
	var runtime: QuestRuntime = _runtime[id]
	runtime.state = QuestRuntime.QuestState.AVAILABLE
	quest_state_changed.emit(id)
	return true


func _refresh_availability() -> void:
	for data: QuestData in database.get_all():
		make_available(data.id)


func accept_quest(id: StringName) -> bool:
	if get_state(id) != QuestRuntime.QuestState.AVAILABLE:
		return false
	var data: QuestData = get_definition(id)
	var runtime: QuestRuntime = _runtime[id]
	runtime.state = QuestRuntime.QuestState.ACTIVE
	runtime.objective_progress.clear()
	for objective: QuestObjectiveData in data.objectives:
		var initial: int = Inventory.get_quantity(objective.target_id) if objective.type == QuestObjectiveData.ObjectiveType.COLLECT_ITEM else 0
		runtime.objective_progress.append(mini(initial, objective.required_amount))
	quest_state_changed.emit(id)
	notification_requested.emit("Quest Accepted: " + data.title)
	_update_completion(data, runtime)
	return true


func record_event(type: QuestObjectiveData.ObjectiveType, target_id: StringName, amount: int = 1) -> void:
	if target_id.is_empty() or amount <= 0:
		return
	for id: StringName in _runtime.keys():
		if not is_active(id):
			continue
		var data: QuestData = get_definition(id)
		var runtime: QuestRuntime = _runtime[id]
		var changed: bool = false
		for index: int in range(data.objectives.size()):
			if not is_active(id):
				break
			var objective: QuestObjectiveData = data.objectives[index]
			if objective.type != type or objective.target_id != target_id:
				continue
			var progress: int = mini(objective.required_amount, runtime.objective_progress[index] + mini(amount, objective.required_amount))
			if progress != runtime.objective_progress[index]:
				runtime.objective_progress[index] = progress
				changed = true
				objective_updated.emit(id, index)
		if changed and is_active(id):
			quest_state_changed.emit(id)
			notification_requested.emit("Quest Updated: " + data.title)
			_update_completion(data, runtime)


func _on_item_added(id: StringName, amount: int) -> void:
	record_event(QuestObjectiveData.ObjectiveType.COLLECT_ITEM, id, amount)


func _update_completion(data: QuestData, runtime: QuestRuntime) -> void:
	if runtime.state != QuestRuntime.QuestState.ACTIVE:
		return
	var was_complete: bool = runtime.objectives_complete
	runtime.objectives_complete = true
	for index: int in range(data.objectives.size()):
		runtime.objectives_complete = runtime.objectives_complete and runtime.objective_progress[index] >= data.objectives[index].required_amount
	if not runtime.objectives_complete:
		return
	if not was_complete:
		quest_state_changed.emit(data.id)
		notification_requested.emit(data.ready_message if not data.ready_message.is_empty() else "Ready to Turn In: " + data.title if data.require_turn_in else "Objectives Complete: " + data.title)
	if data.auto_complete and not data.require_turn_in:
		_queue_auto_completion(data.id)


func _queue_auto_completion(id: StringName) -> void:
	if not _pending_completion.has(id):
		_pending_completion[id] = true
		_auto_complete.call_deferred(id, _restore_epoch)


func _retry_auto_completion() -> void:
	# Retry capacity-blocked rewards on inventory/currency changes, never per frame.
	for id: StringName in _runtime.keys():
		var runtime: QuestRuntime = _runtime[id]
		var data: QuestData = get_definition(id)
		if is_active(id) and runtime.objectives_complete and data.auto_complete and not data.require_turn_in:
			_queue_auto_completion(id)


func _auto_complete(id: StringName, epoch: int) -> void:
	if epoch != _restore_epoch:
		return
	_pending_completion.erase(id)
	var actor: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	complete_quest(id, actor)


func complete_quest(id: StringName, actor: CharacterBody2D = null) -> bool:
	var data: QuestData = get_definition(id)
	if data == null or data.require_turn_in:
		return false
	return _complete(data, actor)


func turn_in_quest(id: StringName, npc_id: StringName, actor: CharacterBody2D) -> bool:
	var data: QuestData = get_definition(id)
	if data == null or not is_ready_to_turn_in(id) or data.turn_in_npc_id != npc_id:
		return false
	if not is_instance_valid(actor) or not actor.is_in_group("player") or not actor.health.is_alive() or actor.is_transition_locked() or SceneTransitions.busy:
		return false
	if actor.state not in [actor.PlayerState.NORMAL, actor.PlayerState.INTERACTING]:
		return false
	return _complete(data, actor)


func _complete(data: QuestData, actor: CharacterBody2D) -> bool:
	last_error = ""
	var runtime: QuestRuntime = _runtime.get(data.id) as QuestRuntime
	if _reward_in_progress or runtime == null or not is_active(data.id) or not runtime.objectives_complete:
		return false
	var removals: Dictionary = {}
	var additions: Dictionary = {}
	var healing: int = 0
	var yen: int = 0
	for objective: QuestObjectiveData in data.objectives:
		if objective.consume_on_turn_in:
			removals[objective.target_id] = int(removals.get(objective.target_id, 0)) + objective.required_amount
	for reward: QuestRewardData in data.rewards:
		if reward.type == QuestRewardData.RewardType.ITEM:
			additions[reward.item_id] = int(additions.get(reward.item_id, 0)) + reward.amount
		elif reward.type == QuestRewardData.RewardType.HEALTH_RESTORE:
			healing += reward.amount
		elif reward.type == QuestRewardData.RewardType.YEN:
			if reward.amount > Wallet.MAX_YEN - yen:
				last_error = "Yen reward is too large."
				return false
			yen += reward.amount
	if healing > 0 and (not is_instance_valid(actor) or not actor.is_in_group("player") or not actor.health.is_alive()):
		last_error = "Health rewards need a living Player."
		return false
	if not Wallet.can_add_yen(yen):
		last_error = "The wallet cannot accept the reward right now."
		notification_requested.emit(last_error)
		return false
	if not Inventory.can_exchange_quest_items(removals, additions):
		last_error = "Keep the quest item and make room for the rewards."
		notification_requested.emit(last_error)
		return false
	_reward_in_progress = true
	# Reserve terminal state before Inventory emits synchronous gameplay events.
	runtime.state = QuestRuntime.QuestState.COMPLETED
	if not Wallet.exchange_yen(0, yen, Inventory.exchange_quest_items.bind(removals, additions)):
		runtime.state = QuestRuntime.QuestState.ACTIVE
		_reward_in_progress = false
		return false
	if healing > 0 and is_instance_valid(actor):
		actor.health.heal(healing) # HealthComponent clamps and never revives.
	_reward_in_progress = false
	quest_state_changed.emit(data.id)
	notification_requested.emit("Quest Completed: " + data.title + (" · " + YenFormat.format(yen) if yen > 0 else ""))
	_refresh_availability()
	return true


func fail_quest(id: StringName) -> bool:
	if _reward_in_progress or not is_active(id):
		return false
	var runtime: QuestRuntime = _runtime[id]
	runtime.state = QuestRuntime.QuestState.FAILED
	quest_state_changed.emit(id)
	return true


func to_save_data() -> Dictionary:
	var data: Dictionary = {}
	for id: StringName in _runtime:
		var runtime: QuestRuntime = _runtime[id]
		data[str(id)] = {"state": QuestRuntime.QuestState.keys()[runtime.state],
			"objective_progress": runtime.objective_progress.duplicate(), "objectives_complete": runtime.objectives_complete}
	return data


func load_save_data(data: Dictionary) -> void:
	_restore_epoch += 1
	_pending_completion.clear()
	_runtime.clear()
	_reward_in_progress = false
	for definition: QuestData in database.get_all():
		var saved: Dictionary = SaveValues.dictionary(data.get(str(definition.id), {}))
		var runtime: QuestRuntime = QuestRuntime.new(definition.id)
		var index: int = QuestRuntime.QuestState.keys().find(saved.get("state", "UNAVAILABLE"))
		runtime.state = index if index >= 0 else QuestRuntime.QuestState.UNAVAILABLE
		# Recompute availability from restored prerequisites, never trust a stale flag.
		if runtime.state == QuestRuntime.QuestState.AVAILABLE:
			runtime.state = QuestRuntime.QuestState.UNAVAILABLE
		if runtime.state in [QuestRuntime.QuestState.ACTIVE, QuestRuntime.QuestState.COMPLETED, QuestRuntime.QuestState.FAILED]:
			var progress: Array = SaveValues.array(saved.get("objective_progress", []))
			runtime.objectives_complete = true
			for objective_index: int in range(definition.objectives.size()):
				var required: int = definition.objectives[objective_index].required_amount
				var value: int = required if runtime.state == QuestRuntime.QuestState.COMPLETED else SaveValues.integer(progress[objective_index] if objective_index < progress.size() else 0, 0, 0, required)
				runtime.objective_progress.append(value)
				runtime.objectives_complete = runtime.objectives_complete and value >= required
		_runtime[definition.id] = runtime
	for raw: Variant in data:
		if database.get_quest(StringName(str(raw))) == null:
			push_warning("Ignoring unknown saved quest: " + str(raw))
	_refresh_availability()
	for definition: QuestData in database.get_all():
		quest_state_changed.emit(definition.id)


func reset_runtime_state() -> void:
	load_save_data({})

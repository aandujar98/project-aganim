class_name TreasureChest
extends Interactable

signal opened(reward_item_id: StringName)

@export var reward_item_id: StringName = &"shrine_charm"
@export_range(1, 999, 1) var reward_amount: int = 1
@export_range(0.1, 2.0, 0.05) var opening_duration: float = 0.45

var is_open: bool = false
var is_opening: bool = false
var _tween: Tween
var _reward_data: DialogueData


func interact(actor: Node, manager: DialogueManager) -> void:
	if is_open or is_opening or not is_instance_valid(manager):
		return
	if not _can_grant_reward():
		push_warning("Chest reward cannot be added; keeping chest closed: %s ×%d" % [reward_item_id, reward_amount])
		return
	var line: DialogueLine = DialogueLine.new()
	line.text = _reward_message()
	_reward_data = DialogueData.new()
	_reward_data.lines.append(line)
	if not manager.can_start(_reward_data) or not _begin(actor):
		return
	_dialogue = manager
	is_opening = true
	_tween = create_tween()
	_tween.tween_property($Lid, "position:y", -10.0, opening_duration)
	_tween.tween_callback(_complete_open)


func _complete_open() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_dialogue):
		_cancel()
		return
	# Recheck on completion; inventory may have changed during the animation.
	if not _grant_reward():
		push_warning("Chest reward failed after opening; keeping chest closed: " + str(reward_item_id))
		_cancel()
		return
	is_opening = false
	is_open = true
	enabled = false
	$Lid.position.y = -10.0
	_reward_committed()
	opened.emit(reward_item_id)
	# Reward signals may cancel interaction (damage/death). Never start late UI.
	if not is_instance_valid(_player) or not is_instance_valid(_dialogue):
		return
	if not _dialogue.start(_reward_data, _player, self, _finish):
		_finish()


func _cancel() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	is_opening = false
	if not is_open:
		$Lid.position.y = 0.0
		_reward_data = null
	super._cancel()


func _can_grant_reward() -> bool:
	return ItemDatabase.get_item(reward_item_id) != null and Inventory.can_add_item(reward_item_id, reward_amount)


func _reward_message() -> String:
	return "Obtained %s ×%d" % [ItemDatabase.get_item(reward_item_id).display_name, reward_amount]


func _grant_reward() -> bool:
	return Inventory.add_item(reward_item_id, reward_amount)


func _reward_committed() -> void:
	pass

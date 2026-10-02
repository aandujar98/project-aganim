extends Area2D

signal collected(pickup: Area2D)

@export var item_id: StringName = &"spirit_fragment"
@export_range(1, 999, 1) var amount: int = 1
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var item: ItemData = ItemDatabase.get_item(item_id)
	$Orb.visible = item == null or item.icon == null
	if item != null:
		$Icon.texture = item.icon


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	if body.state != body.PlayerState.NORMAL or body.is_transition_locked():
		return
	if not Inventory.add_item(item_id, amount):
		return # Invalid/full/duplicate rewards remain in the world for retry.
	_collected = true
	collected.emit(self)
	set_deferred("monitoring", false)
	hide()
	queue_free()

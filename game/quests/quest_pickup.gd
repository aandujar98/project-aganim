extends "res://game/items/pickup.gd"

@export var required_quest_id: StringName
var _available: bool = false


func _ready() -> void:
	super._ready()
	QuestManager.quest_state_changed.connect(_on_quest_changed)
	_restore()


func _on_quest_changed(id: StringName) -> void:
	if id == required_quest_id:
		_restore()


func _restore() -> void:
	var runtime: QuestRuntime = QuestManager.get_runtime(required_quest_id)
	_available = runtime != null and QuestManager.is_active(required_quest_id) and not runtime.objectives_complete and not Inventory.has_item(item_id)
	visible = _available and not _collected
	set_deferred("monitoring", visible)


func _on_body_entered(body: Node2D) -> void:
	if _available:
		super._on_body_entered(body)

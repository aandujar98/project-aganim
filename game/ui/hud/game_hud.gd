class_name GameHUD
extends CanvasLayer
## Exploration HUD: hearts and magic top-left, quick slots and minimap top-right.
## Instanced per WorldArea (like DialogueUI) so the area can supply its own
## minimap and name. It reads existing managers and never owns gameplay state.

## Temporary preview values for the magic meter until a magic system exists.
## Leave at (0, 0) to keep the meter hidden.
@export var magic_preview: Vector2i = Vector2i.ZERO
@export var area_name: String = ""
@export var minimap_texture: Texture2D
## Presentation-only slot contents for visual test scenes, keyed by slot node name:
## {"SlotY": [icon: Texture2D, quantity: int]}. Real loadouts come from item_id.
@export var slot_previews: Dictionary = {}

var _player: CharacterBody2D

@onready var hearts: HeartMeter = $TopLeft/Hearts
@onready var magic: MagicMeter = $TopLeft/Magic
@onready var yen: PixelText = $TopLeft/Yen
@onready var minimap: Minimap = $TopRight/Minimap


func _ready() -> void:
	# The always-on CurrencyHUD sits where the quick slots go; this HUD shows Yen instead.
	CurrencyHUD.visible = false
	Wallet.yen_changed.connect(_on_yen_changed)
	_on_yen_changed(Wallet.get_yen())
	magic.set_values(magic_preview.x, magic_preview.y)
	minimap.area_name = area_name
	minimap.map_texture = minimap_texture
	for slot_name: String in slot_previews:
		var slot: QuickSlot = get_node_or_null("TopRight/" + slot_name) as QuickSlot
		var preview: Array = slot_previews[slot_name]
		if slot == null or preview.size() < 2:
			push_warning("GameHUD slot preview ignored: " + slot_name)
			continue
		slot.item_id = &""
		slot.icon = preview[0] as Texture2D
		slot.preview_quantity = int(preview[1])
		slot.refresh()
	# WorldArea places the Player during its own _ready; bind after that settles.
	_bind_player.call_deferred()


func _exit_tree() -> void:
	CurrencyHUD.visible = true


func _bind_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if _player == null:
		return
	var health: HealthComponent = _player.health
	health.health_changed.connect(hearts.set_values)
	hearts.set_values(health.current_health, health.max_health)
	minimap.target = _player


func _on_yen_changed(amount: int) -> void:
	yen.text = YenFormat.format(amount)

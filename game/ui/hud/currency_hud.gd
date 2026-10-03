extends CanvasLayer

@onready var yen: Label = $Yen


func _ready() -> void:
	Wallet.yen_changed.connect(_refresh)
	_refresh(Wallet.get_yen())


func _refresh(amount: int) -> void:
	yen.text = YenFormat.format(amount)

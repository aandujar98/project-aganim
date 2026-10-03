extends Node

signal yen_changed(new_amount: int)

const MAX_YEN: int = 999999999
@export_range(0, 999999999, 1) var starting_yen: int = 3000
var _yen: int = 0
var _changing: bool = false


func _ready() -> void:
	_yen = clampi(starting_yen, 0, MAX_YEN)


func get_yen() -> int:
	return _yen


func can_afford(amount: int) -> bool:
	return not _changing and amount >= 0 and amount <= _yen


func can_add_yen(amount: int) -> bool:
	return not _changing and amount >= 0 and amount <= MAX_YEN - _yen


func add_yen(amount: int) -> bool:
	return exchange_yen(0, amount)


func spend_yen(amount: int) -> bool:
	return exchange_yen(amount, 0)


func can_exchange_yen(cost: int, reward: int) -> bool:
	return can_afford(cost) and reward >= 0 and reward <= MAX_YEN - (_yen - cost)


func exchange_yen(cost: int, reward: int, commit: Callable = Callable()) -> bool:
	# Reserve balance before inventory signals; synchronous re-entry cannot spend it.
	if not can_exchange_yen(cost, reward):
		return false
	var previous: int = _yen
	_changing = true
	_yen = _yen - cost + reward
	if commit.is_valid() and not bool(commit.call()):
		_yen = previous
		_changing = false
		return false
	if _yen != previous:
		yen_changed.emit(_yen)
	_changing = false
	return true


func to_save_data() -> Dictionary:
	return {"yen": _yen}


func load_save_data(data: Dictionary) -> void:
	_yen = SaveValues.integer(data.get("yen", starting_yen), starting_yen, 0, MAX_YEN)
	_changing = false
	yen_changed.emit(_yen)


func reset_runtime_state() -> void:
	load_save_data({})

class_name SaveValues
extends RefCounted


static func integer(value: Variant, fallback: int = 0, minimum: int = 0, maximum: int = 999999999) -> int:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
		return fallback
	return int(clampf(float(value), float(minimum), float(maximum)))


static func dictionary(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}


static func array(value: Variant) -> Array:
	return value as Array if value is Array else []


static func identifier(value: Variant) -> StringName:
	return StringName(value) if typeof(value) in [TYPE_STRING, TYPE_STRING_NAME] and not str(value).is_empty() and str(value).length() <= 160 else &""


static func flags(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	for raw: Variant in array(value):
		var id: StringName = identifier(raw)
		if not id.is_empty():
			result[id] = true
	return result

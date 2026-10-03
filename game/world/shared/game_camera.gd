class_name GameCamera
extends Camera2D
## Follows its parent (normally the Player) on whole pixels using a CameraProfile.
## Movement code never touches zoom, framing, or snapping.

const DEFAULT_PROFILE: CameraProfile = preload("res://resources/shared/camera/default_camera_profile.tres")

@export var profile: CameraProfile


func _ready() -> void:
	apply_profile(profile if profile != null else DEFAULT_PROFILE)
	snap_to_target()


func apply_profile(value: CameraProfile) -> void:
	profile = value
	zoom = Vector2.ONE * profile.zoom
	offset = Vector2(profile.framing_offset)


func _physics_process(_delta: float) -> void:
	# Children process after their parent, so the target has already moved this tick.
	snap_to_target()


func snap_to_target() -> void:
	var target: Node2D = get_parent() as Node2D
	if target == null:
		return
	global_position = target.global_position.round() if profile.snap_to_pixels else target.global_position

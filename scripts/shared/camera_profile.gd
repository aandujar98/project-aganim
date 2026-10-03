class_name CameraProfile
extends Resource
## Data-only framing settings for GameCamera. Keep all camera tuning here rather
## than scattering zoom/offset values through gameplay scripts.

## Integer zoom keeps every art pixel the same size on screen. Fractional values
## (e.g. 1.25 or 1.33) are allowed for experiments but resample the 384x216
## viewport unevenly; see docs/ART_DIRECTION.md before changing this.
@export_range(1.0, 4.0, 0.05) var zoom: float = 1.0
## Screen-space framing offset applied through Camera2D.offset. The player's
## origin is at their feet, so a small upward offset centers the body.
@export var framing_offset: Vector2i = Vector2i(0, -10)
## Round the follow position to whole world pixels to prevent subpixel shimmer.
@export var snap_to_pixels: bool = true

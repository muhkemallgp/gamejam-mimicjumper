class_name ExitGuard
extends RefCounted

# Stops the player jumping over a level exit and soft-locking.
# The auto-runner only moves right and jumps, so a short exit trigger cleared
# mid-jump leaves the player stuck against the end wall. We replace it with a
# tall vertical band that catches every pass-through, grounded or airborne.

const BAND_HEIGHT: float = 260.0
const BAND_OFFSET_Y: float = -90.0   # keeps band bottom near the door base, top well above jump apex
const MIN_WIDTH: float = 24.0


static func make_unskippable(door: Area2D) -> void:
	var col: CollisionShape2D = _find_shape(door)
	if col == null:
		return
	var rect := col.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()  # bonus exit had no real shape, so build one
	else:
		rect = rect.duplicate()  # avoid mutating a shape shared via the .tscn
	var width: float = max(rect.size.x, MIN_WIDTH)
	rect.size = Vector2(width, BAND_HEIGHT)
	col.shape = rect
	col.position.y += BAND_OFFSET_Y
	col.disabled = false


static func _find_shape(node: Node) -> CollisionShape2D:
	for child in node.get_children():
		if child is CollisionShape2D:
			return child
	return null

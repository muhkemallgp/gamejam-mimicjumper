extends Camera2D

# Mario-style camera, fully manual:
# - top_level = true → decouples camera from Player parent transform so
#   player jumps DON'T translate the camera vertically (no floor jitter).
# - X follows player (with lookahead offset), clamped so the camera's right
#   edge sits at the pillar's left edge — pillar stays flush at screen right
#   and nothing behind it (to its right) is ever revealed.
# - Y locked at locked_y, but follows player when falling into a pit.

@export var locked_y: float = 16.0
@export var x_offset: float = 70.0
@export var follow_x_speed: float = 0.3
@export var follow_y_speed: float = 0.18
@export var fall_threshold: float = 130.0
@export var follow_offset: float = 50.0

var pillar_clamp_x: float = INF
var half_view_w: float = 213.33


func _ready() -> void:
	# Decouple from Player parent — camera Y won't inherit player jumps.
	top_level = true
	# Disable Camera2D's built-in smoothing — we lerp manually for finer control.
	position_smoothing_enabled = false
	# Zero the node's offset; we apply lookahead via x_offset in _process so
	# the pillar clamp math stays correct (otherwise the visible right edge
	# would be position + offset + half_view_w, overshooting the pillar).
	offset = Vector2.ZERO
	# Defer so the scene tree is fully loaded before reading EndPillar position.
	_init_camera.call_deferred()


func _init_camera() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	half_view_w = (viewport_size.x / zoom.x) * 0.5

	var scene: Node = get_tree().current_scene
	if scene:
		var pillar: Node2D = scene.get_node_or_null("Floors/EndPillar") as Node2D
		if pillar:
			var visual: Node2D = pillar.get_node_or_null("Visual") as Node2D
			var pillar_world_x: float = pillar.global_position.x
			if visual:
				pillar_world_x = visual.global_position.x
			# Clamp the camera's RIGHT edge to the pillar's LEFT edge
			# (visual is 16px wide, half-width = 8). View past the pillar
			# stays hidden when the player approaches.
			pillar_clamp_x = pillar_world_x - 8.0
			# Use Camera2D's built-in hard limit so even smoothing/lookahead
			# can't overshoot past the pillar at any point.
			limit_right = int(pillar_clamp_x)

	# Snap camera to player initial position so first frame isn't at (0, 0).
	var player: Node = get_parent()
	if player:
		global_position = Vector2(
			player.global_position.x + x_offset,
			locked_y
		)


func _process(_delta: float) -> void:
	var player: Node = get_parent()
	if player == null:
		return

	# X: follow player + lookahead, clamped so the camera's right edge
	# stops at the pillar's left edge (nothing past the pillar is shown).
	var target_x: float = player.global_position.x + x_offset
	var camera_x_max: float = pillar_clamp_x - half_view_w
	target_x = min(target_x, camera_x_max)

	# Y: locked, except follow player down when they're falling past floor.
	var target_y: float = locked_y
	if player.global_position.y > fall_threshold:
		target_y = player.global_position.y - follow_offset

	global_position.x = lerp(global_position.x, target_x, follow_x_speed)
	global_position.y = lerp(global_position.y, target_y, follow_y_speed)

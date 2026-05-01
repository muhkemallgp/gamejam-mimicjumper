extends Area2D

# MimicChest — D46 Credens Justitiam.
# Looks identical to NormalChest. Shakes subtly while IDLE.
# When player enters DetectionArea: flash red → 0.4s later transform to trap.
# Hits player in SPIKE state = instakill.
#
# Scene needs: Sprite2D (or AnimatedSprite2D), CollisionShape2D,
#              DetectionArea (Area2D with larger CollisionShape2D child),
#              Timer (one_shot, wait_time=0.4),
#              and optionally a child Sprite2D named "MimicSprite"
#              that shows the revealed maw (hidden until SPIKE state).

@onready var main_sprite: Node = _find_display_sprite()
@onready var mimic_sprite: Node = get_node_or_null("MimicSprite")
@onready var detection_area: Area2D = $DetectionArea
@onready var transform_timer: Timer = $Timer

enum State { IDLE, WARNING, SPIKE }
var current_state: State = State.IDLE

@export var shake_amplitude: float = 0.6
var base_position: Vector2


func _find_display_sprite() -> Node:
	if has_node("AnimatedSprite2D"):
		return $AnimatedSprite2D
	elif has_node("Sprite2D"):
		return $Sprite2D
	return null


func _ready() -> void:
	base_position = position
	if mimic_sprite:
		mimic_sprite.visible = false
	detection_area.body_entered.connect(_on_player_nearby)
	transform_timer.timeout.connect(_transform_to_spike)
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if current_state == State.IDLE:
		position = base_position + Vector2(
			randf_range(-shake_amplitude, shake_amplitude),
			randf_range(-shake_amplitude, shake_amplitude)
		)


func _on_player_nearby(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.IDLE:
		current_state = State.WARNING
		if main_sprite:
			main_sprite.modulate = Color(1.3, 0.7, 0.7)
		position = base_position
		transform_timer.start()


func _transform_to_spike() -> void:
	current_state = State.SPIKE
	# Swap main sprite with mimic sprite if available.
	if mimic_sprite:
		if main_sprite:
			main_sprite.visible = false
		mimic_sprite.visible = true
	elif main_sprite:
		main_sprite.modulate = Color(1.0, 0.2, 0.2)
	if has_node("RevealSFX"):
		$RevealSFX.play()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if current_state == State.SPIKE:
			if body.has_method("die"):
				body.die("mimic_chest")
		else:
			# Grabbed before reveal — same reward as NormalChest (+1 life or +5 coins fallback).
			if not Global.gain_life():
				Global.total_coins += 5
			queue_free()

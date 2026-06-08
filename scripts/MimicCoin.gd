extends Area2D

# MimicCoin — D46 Credens Justitiam.
# Looks like a regular Coin until player gets close.
# Shakes subtly in idle state (visual hint for observant players).
# When player enters DetectionArea: flash red → 0.12s later transform to monster.
# Touching revealed mimic = -1 life for player.

@onready var coin_sprite: AnimatedSprite2D = $CoinSprite
@onready var revealed_sprite: AnimatedSprite2D = $RevealedSprite
@onready var detection_area: Area2D = $DetectionArea
@onready var transform_timer: Timer = $Timer

enum State { IDLE, WARNING, REVEALED }
var current_state: State = State.IDLE

@export var shake_amplitude: float = 0.4
var base_position: Vector2


func _ready() -> void:
	base_position = position
	revealed_sprite.visible = false
	# virtual_guy ability: wider detection so mimics reveal from farther.
	detection_area.scale *= Global.get_mimic_detection_scale()
	detection_area.body_entered.connect(_on_player_nearby)
	transform_timer.timeout.connect(_transform)
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
		coin_sprite.modulate = Color(1.5, 0.5, 0.5)
		position = base_position
		transform_timer.start()


func _transform() -> void:
	current_state = State.REVEALED
	coin_sprite.visible = false
	revealed_sprite.visible = true
	if has_node("RevealSFX"):
		$RevealSFX.play()
	# Punchy reveal — quick scale tween + camera shake on player
	var tween: Tween = create_tween()
	revealed_sprite.scale = Vector2(0.3, 0.3)
	tween.tween_property(revealed_sprite, "scale", Vector2(0.6, 0.6), 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_shake_player_camera()


func _shake_player_camera() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node2D = players[0]
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam == null:
		return
	var base_offset: Vector2 = cam.offset
	var t: Tween = create_tween()
	t.tween_property(cam, "offset", base_offset + Vector2(4, 0), 0.04)
	t.tween_property(cam, "offset", base_offset + Vector2(-4, 0), 0.04)
	t.tween_property(cam, "offset", base_offset, 0.08)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if current_state == State.REVEALED:
			if body.has_method("die"):
				body.die("mimic_coin")
		else:
			# Player grabbed before transform — reward as regular coin.
			Global.total_coins += 1
			Global.level_coins_collected += 1
			coin_sprite.visible = false
			$CollisionShape2D.set_deferred("disabled", true)
			queue_free()

extends Node2D

# Level controller — handles respawn, game over, level progression, and
# hands off to IntermissionScreen on completion (threshold check).

const GAME_OVER_PATH: String = "res://scenes/GameOverScreen.tscn"
const INTERMISSION_PATH: String = "res://scenes/IntermissionScreen.tscn"

const RESUME_COUNTDOWN_SECONDS: int = 3

var player: CharacterBody2D
var finish: Area2D
var player_start_position: Vector2
var resume_countdown_label: Label = null


func _ready() -> void:
	player = $Player
	finish = $FinishDoor
	player_start_position = player.global_position
	# Reset safe-spot checkpoint. Stays ZERO until the player's first ground
	# frame captures a real safe spot. Don't seed with start_position — that
	# would block the progression check from updating it for the first ~36px
	# of travel, causing early-death Resumes to teleport to start.
	if "last_safe_position" in player:
		player.last_safe_position = Vector2.ZERO
		player.time_grounded = 0.0
	# Pre-seed Global.resume_position too so a death in the very first
	# frame still has a non-ZERO target. SKIP when arriving via resume —
	# that flow already populated resume_position with the death-time spot.
	if not Global.pending_resume:
		Global.resume_position = player_start_position
	player.player_died.connect(_on_player_died)
	finish.reached.connect(_on_finish_reached)

	# Count pickups (for level_coins_max). Don't reset level_coins on resume — player
	# already collected some this attempt and we want to preserve that count.
	if not Global.pending_resume:
		Global.reset_level_coins()
	if has_node("Pickups"):
		Global.level_coins_max = $Pickups.get_child_count()
	else:
		Global.level_coins_max = 0

	# Hide secret-path signs ("SECRET PATH ↓↓↓") once the bonus has been
	# claimed this run — prevents pit-farming that can't reward anything.
	# SecretWall + SecretTrigger stay active (cheap to leave), they just
	# silently lead nowhere.
	if Global.bonus_visited_this_run and has_node("Signs"):
		$Signs.visible = false

	# If player paid to resume, teleport to last death position instead of level start.
	if Global.pending_resume:
		var pos: Vector2 = Global.consume_resume_position()
		if pos != Vector2.ZERO:
			player.global_position = pos
			player.velocity = Vector2.ZERO
			# Brief invincibility so player isn't insta-killed from same spot.
			player.is_invincible = true
			player.invincibility_time_left = player.invincibility_duration
			# Seed last_safe_position to the resumed spot so any later pit-fall
			# respawn within this level returns HERE, not the level start —
			# otherwise paying 10 coins to resume gets undone the moment you
			# misjudge the same pit again.
			if "last_safe_position" in player:
				player.last_safe_position = pos
			# Freeze + countdown so the player has a moment to orient themselves
			# before auto-run resumes.
			_start_resume_countdown()

	_enable_bgm_loop()


func _start_resume_countdown() -> void:
	if "is_frozen" in player:
		player.is_frozen = true
	_ensure_countdown_label()
	for n in range(RESUME_COUNTDOWN_SECONDS, 0, -1):
		_set_countdown_text(str(n))
		await get_tree().create_timer(1.0).timeout
		# Bail if the player navigated away mid-countdown.
		if not is_inside_tree() or player == null or not is_instance_valid(player):
			return
	_set_countdown_text("GO!")
	if "is_frozen" in player:
		player.is_frozen = false
	await get_tree().create_timer(0.4).timeout
	if resume_countdown_label and is_instance_valid(resume_countdown_label):
		resume_countdown_label.queue_free()
		resume_countdown_label = null


func _ensure_countdown_label() -> void:
	if resume_countdown_label and is_instance_valid(resume_countdown_label):
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var lbl: Label = Label.new()
	lbl.text = ""
	lbl.add_theme_font_size_override("font_size", 64)
	lbl.add_theme_color_override("font_color", Color(1, 0.95, 0.55, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchor_left = 0.5
	lbl.anchor_right = 0.5
	lbl.anchor_top = 0.5
	lbl.anchor_bottom = 0.5
	lbl.offset_left = -120
	lbl.offset_right = 120
	lbl.offset_top = -60
	lbl.offset_bottom = 20
	layer.add_child(lbl)
	resume_countdown_label = lbl


func _set_countdown_text(s: String) -> void:
	if resume_countdown_label and is_instance_valid(resume_countdown_label):
		resume_countdown_label.text = s


func _enable_bgm_loop() -> void:
	if not has_node("BGM"):
		return
	var bgm: AudioStreamPlayer = $BGM
	if bgm.stream and "loop" in bgm.stream:
		bgm.stream.loop = true


func _on_player_died(reason: String) -> void:
	if Global.is_game_over():
		get_tree().change_scene_to_file.call_deferred(GAME_OVER_PATH)
		return
	# Only respawn if player physically fell off the world (pit fall).
	# For hazard hits (spike/mimic), player keeps running — i-frames in Player.gd protect them.
	if reason == "pit" or reason == "secret_pit":
		_respawn_player.call_deferred()


func _respawn_player() -> void:
	# Pit-fall respawn (lives still > 0). Send back to level start as the
	# punishment for missing a jump — only paid Resume (from GameOver) gets
	# the death-spot teleport. Also reset last_safe_position so the next
	# safe-spot capture starts fresh from the player's new (start) location.
	player.global_position = player_start_position
	player.velocity = Vector2.ZERO
	if "last_safe_position" in player:
		player.last_safe_position = Vector2.ZERO
		player.time_grounded = 0.0
	if Global.secret_unlocked and has_node("SecretWall"):
		$SecretWall.queue_free()


func _on_finish_reached() -> void:
	# Route through IntermissionScreen for threshold check.
	Global.prepare_intermission(false)
	get_tree().change_scene_to_file.call_deferred(INTERMISSION_PATH)

extends CharacterBody2D

# MIMIC! Player — one-button auto-runner (D24).
# Works with either AnimatedSprite2D or plain Sprite2D child (auto-detected).

@export var run_speed: float = 130.0
@export var jump_velocity: float = -330.0
@export var gravity: float = 900.0
@export var max_fall_speed: float = 500.0

@export var coyote_time: float = 0.1
var coyote_timer: float = 0.0

@export var jump_buffer_time: float = 0.1
var jump_buffer_timer: float = 0.0

@export var invincibility_duration: float = 1.4
var is_invincible: bool = false
var invincibility_time_left: float = 0.0

# Frozen state — player stands still (no run, no gravity, no input) while
# the Resume countdown plays. Set true by Level.gd after teleporting on a
# paid Resume; cleared automatically when the countdown ends.
var is_frozen: bool = false

# Confirmed-safe position — captured every frame on floor with a backward
# offset (SAFE_BACKWARD_OFFSET) so a cliff-edge capture still lands the
# resume teleport on solid ground a few px behind the edge. Stays at
# Vector2.ZERO until the first ground frame, so die() can detect "no safe
# spot ever captured" and fall back appropriately.
var last_safe_position: Vector2 = Vector2.ZERO
var time_grounded: float = 0.0
const SAFE_CAPTURE_DELAY: float = 0.0
const SAFE_BACKWARD_OFFSET: float = 36.0

var animated_sprite: AnimatedSprite2D = null
var plain_sprite: Sprite2D = null

signal player_died(reason: String)


func _ready() -> void:
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	plain_sprite = get_node_or_null("Sprite2D")
	_apply_skin()


func _apply_skin() -> void:
	if animated_sprite == null:
		return
	if Global.selected_skin == "mask_dude":
		return  # default already in scene
	var sf: SpriteFrames = _build_sprite_frames(Global.selected_skin)
	if sf and sf.has_animation("idle"):
		animated_sprite.sprite_frames = sf
		animated_sprite.play("idle")


func _build_sprite_frames(skin: String) -> SpriteFrames:
	var base: String = "res://assets/sprites/player/" + skin + "/"
	var sf: SpriteFrames = SpriteFrames.new()
	_add_anim(sf, "idle", base + "idle.png", 11, 10.0, true)
	_add_anim(sf, "run", base + "run.png", 12, 18.0, true)
	_add_anim(sf, "jump", base + "jump.png", 1, 5.0, false)
	_add_anim(sf, "fall", base + "fall.png", 1, 5.0, false)
	_add_anim(sf, "hit", base + "hit.png", 7, 15.0, false)
	return sf


func _add_anim(sf: SpriteFrames, anim: String, path: String, frames: int, fps: float, loop: bool) -> void:
	if sf.has_animation(anim):
		sf.remove_animation(anim)
	sf.add_animation(anim)
	sf.set_animation_loop(anim, loop)
	sf.set_animation_speed(anim, fps)
	var tex = load(path)
	if tex == null:
		return
	for i in range(frames):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		sf.add_frame(anim, atlas)


func _physics_process(delta: float) -> void:
	# Frozen during Resume countdown: stand still, ignore input, but stay
	# pinned to the floor (no gravity drift). i-frames still tick down.
	if is_frozen:
		velocity = Vector2.ZERO
		_play_anim("idle")
		_tick_invincibility(delta)
		return

	velocity.x = run_speed

	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		_play_anim("jump")
		if has_node("JumpSFX"):
			$JumpSFX.play()

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	move_and_slide()
	_update_animation()
	_tick_invincibility(delta)
	# Track confirmed-safe spot for Resume teleport.
	# - Capture position OFFSET BACKWARD so cliff-edge frames still resolve
	#   to a spot back on the platform.
	# - First capture (last_safe == ZERO) always wins so we never get stuck.
	# - Otherwise only PROGRESS forward — per-level pit respawns at start
	#   shouldn't overwrite a deeper checkpoint we already earned.
	if is_on_floor():
		time_grounded += delta
		var candidate: Vector2 = Vector2(
			global_position.x - SAFE_BACKWARD_OFFSET,
			global_position.y
		)
		if last_safe_position == Vector2.ZERO or candidate.x > last_safe_position.x:
			last_safe_position = candidate
	else:
		time_grounded = 0.0

	# Player fell off the world — any fall past y=500 is unrecoverable
	# (play area is y=0..120, pit goes to y=260 via SecretTrigger).
	if global_position.y > 500:
		die("pit")


func _tick_invincibility(delta: float) -> void:
	if not is_invincible:
		return
	invincibility_time_left -= delta
	if invincibility_time_left <= 0:
		is_invincible = false
		if animated_sprite:
			animated_sprite.modulate.a = 1.0
	else:
		# Flicker visual — alpha 1.0 / 0.35 alternating fast
		var flicker: bool = sin(invincibility_time_left * 35.0) > 0
		if animated_sprite:
			animated_sprite.modulate.a = 1.0 if flicker else 0.35


func _update_animation() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		# Placeholder: tint plain sprite based on state.
		if plain_sprite:
			if not is_on_floor():
				plain_sprite.modulate = Color(1.2, 1.2, 0.9)
			else:
				plain_sprite.modulate = Color(1, 1, 1)
		return
	if not is_on_floor():
		if velocity.y < 0:
			_play_anim("jump")
		else:
			_play_anim("fall")
	else:
		_play_anim("run")


func _play_anim(anim_name: String) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if animated_sprite.animation != anim_name and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)


func die(reason: String = "generic") -> void:
	# I-frames: ignore additional damage during brief window after a hit.
	# Pit fall always counts (it's a positional reset trigger).
	if is_invincible and reason != "pit" and reason != "secret_pit":
		return
	Global.lose_life()
	if has_node("HitSFX") and reason != "pit":
		$HitSFX.play()
	_play_anim("hit")
	_shake_camera()
	emit_signal("player_died", reason)
	# Start invincibility window (only if still alive — otherwise scene changes anyway).
	if not Global.is_game_over():
		is_invincible = true
		invincibility_time_left = invincibility_duration
	else:
		# Capture position for the Resume option. Always prefer the last
		# confirmed-safe ground spot (a few px behind player) so the teleport
		# lands BEFORE the death — not at the cliff edge or on the spike.
		if last_safe_position != Vector2.ZERO:
			Global.resume_position = last_safe_position
		elif reason == "pit" or reason == "secret_pit":
			# Off-world fall with no safe capture — leave resume_position as
			# whatever Level._ready seeded (player_start_position).
			pass
		else:
			# Hazard hit before any safe capture — best estimate is "a bit
			# behind where the spike caught us."
			Global.resume_position = Vector2(
				global_position.x - SAFE_BACKWARD_OFFSET,
				global_position.y
			)
	print("💀 Player died: ", reason, " | Lives left: ", Global.lives)


func _shake_camera() -> void:
	var cam: Camera2D = get_node_or_null("Camera2D")
	if cam == null:
		return
	var base_offset: Vector2 = cam.offset
	var tween: Tween = create_tween()
	tween.tween_property(cam, "offset", base_offset + Vector2(6, -4), 0.05)
	tween.tween_property(cam, "offset", base_offset + Vector2(-5, 3), 0.05)
	tween.tween_property(cam, "offset", base_offset, 0.1)

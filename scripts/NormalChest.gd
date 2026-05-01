extends Area2D

# LifeChest — rare pickup that grants +1 life (capped at MAX_LIVES).
# Pulses gently to catch the eye.

@onready var sprite: Sprite2D = $Sprite2D
var collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_pulse()


func _start_pulse() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(sprite, "modulate", Color(1.6, 1.3, 0.6, 1), 0.7)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.9, 0.5, 1), 0.7)


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	var gained: bool = Global.gain_life()
	# If lives already maxed, fall back to a small coin reward so player isn't punished.
	if not gained:
		Global.total_coins += 5
	sprite.visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("PickupSFX") and $PickupSFX.stream:
		$PickupSFX.play()
		await $PickupSFX.finished
	queue_free()

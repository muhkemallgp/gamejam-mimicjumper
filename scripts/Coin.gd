extends Area2D

# Coin — safe pickup. +1 to both level and total counters.

var collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	Global.total_coins += 1
	Global.level_coins_collected += 1
	# Hide visuals & disable collision instantly, but wait for SFX before freeing.
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.visible = false
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if has_node("PickupSFX") and $PickupSFX.stream:
		$PickupSFX.play()
		await $PickupSFX.finished
	queue_free()

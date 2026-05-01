extends Area2D

# SecretDoor — hidden exit unlocked only via D29 (breaking SecretWall).
# Invisible and non-interactive until Global.secret_unlocked == true.


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visibility()


func _process(_delta: float) -> void:
	# Poll for state change (D29 unlock happens via Global signal-less mutation).
	_update_visibility()


func _update_visibility() -> void:
	# Accessible only if D29 completed AND bonus not yet visited this run.
	# Hidden completely until unlocked — wall break + door appear is the
	# "reveal" moment, makes the secret unlock feel dramatic.
	var accessible: bool = Global.secret_unlocked and not Global.bonus_visited_this_run
	if has_node("Sprite2D"):
		$Sprite2D.visible = accessible
		$Sprite2D.modulate = Color(1.5, 1.2, 0.4, 1.0)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", not accessible)


func _on_body_entered(body: Node2D) -> void:
	# Double-check: only trigger if unlocked (Godot may still fire during transition frame).
	if body.is_in_group("player") and Global.secret_unlocked and not Global.bonus_visited_this_run:
		get_tree().change_scene_to_file.call_deferred(Global.enter_bonus_level())

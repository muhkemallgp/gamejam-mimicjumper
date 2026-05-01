extends Area2D

# SecretTrigger — D29 Trash Enjoyer.
# Place at the bottom of the cursed pit.

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Global.trigger_secret_fall()
		if body.has_method("die"):
			body.die("secret_pit")

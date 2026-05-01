extends StaticBody2D

# SecretWall — crumbles when secret unlocked (D29).

func _ready() -> void:
	if Global.secret_unlocked:
		queue_free()

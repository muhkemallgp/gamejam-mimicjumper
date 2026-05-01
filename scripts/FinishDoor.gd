extends Area2D

# FinishDoor — regular level exit. Goes to next regular level.

signal reached


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		emit_signal("reached")

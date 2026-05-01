extends Area2D

# BonusFinishDoor — exit from BonusLevel.
# Routes through IntermissionScreen with from_bonus flag so player sees their haul.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var root: Node = get_tree().current_scene
		if root and root.has_node("Pickups"):
			# Count remaining + already-collected. We approximate via current node count.
			# level_coins_collected reflects what was picked up; max = collected + remaining.
			var remaining: int = root.get_node("Pickups").get_child_count()
			Global.level_coins_max = Global.level_coins_collected + remaining
		Global.prepare_intermission(true)
		get_tree().change_scene_to_file.call_deferred("res://scenes/IntermissionScreen.tscn")

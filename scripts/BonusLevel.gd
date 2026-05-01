extends Node2D

# BonusLevel root controller.
# Without this, level_coins_collected and level_coins_max carry over from
# the regular level the player jumped in from, so the HUD shows e.g. "8 / 14"
# from Level 2 instead of "0 / 30" for the bonus haul. We reset both here
# and recount pickups from this scene.


func _ready() -> void:
	Global.level_coins_collected = 0
	if has_node("Pickups"):
		Global.level_coins_max = $Pickups.get_child_count()
	else:
		Global.level_coins_max = 0

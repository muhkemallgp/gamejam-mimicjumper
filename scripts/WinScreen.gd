extends Control

const LEVEL_PATH: String = "res://scenes/Level1.tscn"
const MENU_PATH: String = "res://scenes/MainMenu.tscn"


func _ready() -> void:
	$VBoxContainer/ScoreLabel.text = "Gems:  %d" % Global.total_coins
	$VBoxContainer/SecretLabel.text = (
		"Vault:  FOUND" if Global.bonus_visited_this_run
		else "Vault:  hidden"
	)
	$VBoxContainer/PlayAgainButton.pressed.connect(_on_play_again)
	$VBoxContainer/MenuButton.pressed.connect(_on_menu)


# Note: no SPACE auto-trigger here. Play Again is destructive (resets run + saves)
# so we require an explicit button click to avoid accidental fires from
# residual SPACE presses leaking from Epilog scene.


func _on_play_again() -> void:
	Global.reset_for_new_game()
	get_tree().change_scene_to_file(LEVEL_PATH)


func _on_menu() -> void:
	get_tree().change_scene_to_file(MENU_PATH)

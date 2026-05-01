extends Control

# IntermissionScreen — shown between levels after FinishDoor.
# Reads Global intermission state and shows coin stats + threshold check.


@onready var title_label: Label = $CenterPanel/MarginContainer/VBox/TitleLabel
@onready var coin_label: Label = $CenterPanel/MarginContainer/VBox/CoinLabel
@onready var threshold_label: Label = $CenterPanel/MarginContainer/VBox/ThresholdLabel
@onready var status_label: Label = $CenterPanel/MarginContainer/VBox/StatusLabel
@onready var cumulative_label: Label = $CenterPanel/MarginContainer/VBox/CumulativeLabel
@onready var continue_button: Button = $CenterPanel/MarginContainer/VBox/ContinueButton
@onready var retry_button: Button = $CenterPanel/MarginContainer/VBox/RetryButton
@onready var menu_button: Button = $CenterPanel/MarginContainer/VBox/MenuButton


func _ready() -> void:
	var lvl: int = Global.intermission_level_num
	var got: int = Global.intermission_coins_collected
	var max_c: int = Global.intermission_coins_max
	var threshold: int = Global.get_current_threshold()
	var from_bonus: bool = Global.intermission_came_from_bonus
	var passed: bool = from_bonus or got >= threshold

	coin_label.text = "Level Gems:  %d / %d" % [got, max_c]
	cumulative_label.text = "Total Run:  %d" % Global.total_coins
	cumulative_label.visible = true

	if from_bonus:
		title_label.text = "BONUS CLEAR!"
		title_label.modulate = Color(1, 0.85, 0.3, 1)
		threshold_label.visible = false
		status_label.text = "Lucky you found this."
		status_label.modulate = Color(1, 0.85, 0.3, 1)
		continue_button.visible = true
		retry_button.visible = false
	elif passed:
		threshold_label.text = "Need:  %d" % threshold
		title_label.text = "LEVEL %d CLEAR!" % lvl
		title_label.modulate = Color(0.4, 1, 0.5, 1)
		status_label.text = "Nice run!"
		status_label.modulate = Color(0.4, 1, 0.5, 1)
		continue_button.visible = true
		retry_button.visible = false
	else:
		threshold_label.text = "Need:  %d" % threshold
		title_label.text = "NOT ENOUGH"
		title_label.modulate = Color(1, 0.5, 0.5, 1)
		status_label.text = "Need %d more gems." % (threshold - got)
		status_label.modulate = Color(1, 0.5, 0.5, 1)
		continue_button.visible = false
		retry_button.visible = true

	continue_button.pressed.connect(_on_continue)
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)


func _input(event: InputEvent) -> void:
	# Keyboard-only SPACE shortcut. Don't listen to the "jump" action here
	# because it's also bound to Mouse-Left — clicking the Continue button
	# would fire BOTH the button's pressed signal AND this shortcut, causing
	# advance_level_after_intermission() to run twice and double-increment
	# current_level (skipping a level).
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_menu()
			accept_event()
		elif event.keycode == KEY_SPACE:
			if continue_button.visible:
				_on_continue()
			else:
				_on_retry()
			accept_event()


func _on_continue() -> void:
	get_tree().change_scene_to_file(Global.advance_level_after_intermission())


func _on_retry() -> void:
	get_tree().change_scene_to_file(Global.retry_current_level())


func _on_menu() -> void:
	# Save preserved — player can resume from MainMenu Continue button.
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

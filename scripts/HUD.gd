extends CanvasLayer

# HUD — shows Global state + level indicator + pause overlay.

const CONFIRM_SCENE: PackedScene = preload("res://scenes/ConfirmDialog.tscn")

@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var coin_label: Label = $MarginContainer/VBoxContainer/CoinLabel
@onready var hearts: Array[TextureRect] = [
	$MarginContainer/VBoxContainer/LivesRow/Heart1,
	$MarginContainer/VBoxContainer/LivesRow/Heart2,
	$MarginContainer/VBoxContainer/LivesRow/Heart3,
	$MarginContainer/VBoxContainer/LivesRow/Heart4,
	$MarginContainer/VBoxContainer/LivesRow/Heart5,
	$MarginContainer/VBoxContainer/LivesRow/Heart6,
]
@onready var secret_label: Label = $MarginContainer/VBoxContainer/SecretLabel
@onready var pause_overlay: Control = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/Panel/Margin/VBox/ResumeButton
@onready var menu_button: Button = $PauseOverlay/Panel/Margin/VBox/MenuButton
@onready var quit_button: Button = $PauseOverlay/Panel/Margin/VBox/QuitButton


func _ready() -> void:
	pause_overlay.visible = false
	resume_button.pressed.connect(_resume)
	menu_button.pressed.connect(_ask_menu)
	quit_button.pressed.connect(_ask_quit)


func _process(_delta: float) -> void:
	level_label.text = "LEVEL %d / %d" % [Global.current_level, Global.MAX_LEVEL]
	# Per-level progress (resets each level). Total only shown at Intermission/GameOver.
	if Global.level_coins_max > 0:
		coin_label.text = "COINS: %d / %d" % [Global.level_coins_collected, Global.level_coins_max]
	else:
		coin_label.text = "COINS: %d" % Global.level_coins_collected
	for i in hearts.size():
		hearts[i].visible = i < Global.lives

	# Hide secret hint entirely once the player has already cashed in the bonus
	# this run — there's no second visit, so don't tempt them into pit-farming.
	if Global.bonus_visited_this_run:
		secret_label.visible = false
	elif Global.secret_unlocked:
		secret_label.visible = true
		secret_label.text = "SECRET PATH OPEN"
		secret_label.modulate = Color(1, 0.9, 0.3, 1)
	elif Global.secret_fall_count > 0:
		secret_label.visible = true
		secret_label.text = "DEEPER... %d/%d" % [Global.secret_fall_count, Global.get_secret_fall_requirement()]
		secret_label.modulate = Color(0.9, 0.6, 1, 1)
	else:
		secret_label.visible = true
		secret_label.text = "Secret: ???"
		secret_label.modulate = Color(0.6, 0.6, 0.7, 1)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_toggle_pause()


func _toggle_pause() -> void:
	if pause_overlay.visible:
		_resume()
	else:
		_pause()


func _pause() -> void:
	pause_overlay.visible = true
	get_tree().paused = true


func _resume() -> void:
	pause_overlay.visible = false
	get_tree().paused = false


func _ask_menu() -> void:
	_show_confirm("Lose this attempt?\nLevel coins won't be saved.", _to_menu)


func _ask_quit() -> void:
	_show_confirm("Quit game?\nProgress saved at last level start.", _quit_game)


func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/MainMenu.tscn")


func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()


func _show_confirm(msg: String, on_yes: Callable) -> void:
	var dlg = CONFIRM_SCENE.instantiate()
	add_child(dlg)
	dlg.set_message(msg)
	dlg.confirmed.connect(on_yes)

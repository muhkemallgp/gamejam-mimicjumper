extends Control

const MENU_PATH: String = "res://scenes/MainMenu.tscn"

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var play_button: Button = $VBoxContainer/PlayAgainButton
@onready var menu_button: Button = $VBoxContainer/MenuButton


func _ready() -> void:
	$VBoxContainer/ScoreLabel.text = "Gems:  %d" % Global.total_coins
	$VBoxContainer/LevelLabel.text = "Level:  %d / %d" % [Global.current_level, Global.MAX_LEVEL]
	resume_button.visible = Global.can_resume() and Global.resume_position != Vector2.ZERO
	resume_button.pressed.connect(_on_resume)
	play_button.pressed.connect(_on_play_again)
	menu_button.pressed.connect(_on_menu)


func _input(event: InputEvent) -> void:
	# Keyboard SPACE shortcut → Play Again. Don't use the "jump" action here
	# because it's also bound to Mouse-Left, which would fire alongside the
	# Resume button's pressed signal and stomp pending_resume back to false
	# (causing paid Resume to silently fall through to level start).
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_SPACE:
		_on_play_again()
		accept_event()


func _on_resume() -> void:
	var path: String = Global.try_resume()
	if path != "":
		get_tree().change_scene_to_file(path)


func _on_play_again() -> void:
	get_tree().change_scene_to_file(Global.retry_after_gameover())


func _on_menu() -> void:
	get_tree().change_scene_to_file(MENU_PATH)

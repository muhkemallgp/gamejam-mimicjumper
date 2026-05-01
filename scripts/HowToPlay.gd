extends Control

# How To Play screen — explains controls, objective, and what each entity does.
# Reachable from MainMenu via the "How to Play" button. Returns to MainMenu
# on Back button or ESC.

const MENU_PATH: String = "res://scenes/MainMenu.tscn"

@onready var back_button: Button = $CenterPanel/MarginContainer/OuterVBox/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back)
	# Continue the same BGM playing in MainMenu (autoload at /root/MenuMusic) — no restart.
	var menu_music: Node = get_node_or_null("/root/MenuMusic")
	if menu_music and menu_music.has_method("ensure_playing"):
		menu_music.ensure_playing()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
		_on_back()
		accept_event()


func _on_back() -> void:
	get_tree().change_scene_to_file(MENU_PATH)

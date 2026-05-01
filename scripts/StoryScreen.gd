extends Control

# Reusable story screen — used for IntroScene and EpilogScene.
# Override `pages` and `next_scene_path` per use.

@export var pages: Array[String] = []
@export var next_scene_path: String = "res://scenes/MainMenu.tscn"
@export var title_text: String = ""

var current_page: int = 0


func _ready() -> void:
	$VBox/SkipButton.pressed.connect(_finish)
	$VBox/NextButton.pressed.connect(_next_page)
	if title_text != "":
		$VBox/TitleLabel.text = title_text
	_render_page()


func _render_page() -> void:
	if pages.is_empty():
		_finish()
		return
	$VBox/Body.text = pages[current_page]
	var is_last: bool = current_page >= pages.size() - 1
	$VBox/NextButton.text = "  Begin   [ Space ]  " if is_last else "  Next   [ Space ]  "


func _next_page() -> void:
	current_page += 1
	if current_page >= pages.size():
		_finish()
	else:
		_render_page()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			get_viewport().set_input_as_handled()
			_next_page()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_finish()


func _finish() -> void:
	get_tree().change_scene_to_file(next_scene_path)

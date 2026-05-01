extends Control

const FIRST_LEVEL: String = "res://scenes/Level1.tscn"
const INTRO_SCENE: String = "res://scenes/IntroScene.tscn"
const HOW_TO_PLAY_SCENE: String = "res://scenes/HowToPlay.tscn"
const CONFIRM_SCENE: PackedScene = preload("res://scenes/ConfirmDialog.tscn")

@onready var continue_button: Button = $CenterPanel/MarginContainer/VBoxContainer/ContinueButton
@onready var start_button: Button = $CenterPanel/MarginContainer/VBoxContainer/StartButton
@onready var shop_button: Button = $CenterPanel/MarginContainer/VBoxContainer/ShopButton
@onready var how_to_play_button: Button = $CenterPanel/MarginContainer/VBoxContainer/HowToPlayButton
@onready var quit_button: Button = $CenterPanel/MarginContainer/VBoxContainer/QuitButton


func _ready() -> void:
	continue_button.visible = Global.has_save()
	continue_button.pressed.connect(_on_continue)
	start_button.pressed.connect(_on_start_pressed)
	shop_button.pressed.connect(_on_shop)
	how_to_play_button.pressed.connect(_on_how_to_play)
	quit_button.pressed.connect(_on_quit)
	# Persistent menu BGM (autoload at /root/MenuMusic). Continues across
	# MainMenu ↔ Shop ↔ HowToPlay without restarting the track. Resolved
	# dynamically so parser doesn't choke when autoload isn't yet registered.
	var menu_music: Node = get_node_or_null("/root/MenuMusic")
	if menu_music and menu_music.has_method("ensure_playing"):
		menu_music.ensure_playing()


func _on_shop() -> void:
	get_tree().change_scene_to_file("res://scenes/ShopScreen.tscn")


func _on_how_to_play() -> void:
	get_tree().change_scene_to_file(HOW_TO_PLAY_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	# SPACE only resumes existing save. Starting a new run is destructive and must
	# be an explicit button click — prevents accidents from SPACE leaking out of
	# Epilog/Win scenes into MainMenu.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if continue_button.visible:
			_on_continue()


func _on_continue() -> void:
	if Global.load_progress():
		get_tree().change_scene_to_file("res://scenes/Level%d.tscn" % Global.current_level)
	else:
		_start_new_run()


func _on_start_pressed() -> void:
	if Global.has_save():
		_show_confirm("Erase saved run?\nThis can't be undone.", _start_new_run)
	else:
		_start_new_run()


func _start_new_run() -> void:
	Global.reset_for_new_game()
	get_tree().change_scene_to_file(INTRO_SCENE)


func _on_quit() -> void:
	_show_confirm("Quit game?\nProgress & coins are saved.", _do_quit)


func _do_quit() -> void:
	get_tree().quit()


func _show_confirm(msg: String, on_yes: Callable) -> void:
	var dlg = CONFIRM_SCENE.instantiate()
	add_child(dlg)
	dlg.set_message(msg)
	dlg.confirmed.connect(on_yes)

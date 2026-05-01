extends CanvasLayer

# Reusable yes/no confirmation. Instance, add_child, set_message, connect signals.

signal confirmed
signal cancelled


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Root/Panel/Margin/VBox/Buttons/YesButton.pressed.connect(_yes)
	$Root/Panel/Margin/VBox/Buttons/NoButton.pressed.connect(_no)


func set_message(msg: String) -> void:
	$Root/Panel/Margin/VBox/Message.text = msg


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Y or event.keycode == KEY_ENTER:
			_yes()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_N or event.keycode == KEY_ESCAPE:
			_no()
			get_viewport().set_input_as_handled()


func _yes() -> void:
	confirmed.emit()
	queue_free()


func _no() -> void:
	cancelled.emit()
	queue_free()

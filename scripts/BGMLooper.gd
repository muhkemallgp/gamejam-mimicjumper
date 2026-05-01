extends AudioStreamPlayer

func _ready() -> void:
	if stream and "loop" in stream:
		stream.loop = true
	# Silence the persistent menu BGM autoload — this scene is taking over.
	# Resolved by node path so the parser doesn't require autoload registration.
	var menu_music: Node = get_node_or_null("/root/MenuMusic")
	if menu_music and menu_music.has_method("stop_bgm"):
		menu_music.stop_bgm()

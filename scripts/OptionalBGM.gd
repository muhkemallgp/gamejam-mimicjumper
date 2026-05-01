extends AudioStreamPlayer

# OptionalBGM — loads a BGM file at runtime IF it exists, else stays silent.
# Lets us wire scenes to expected filenames (e.g. assets/audio/bgm/intro.mp3)
# before the file has been downloaded — no missing-resource error on play.
# Also enables looping for stream types that support it.

@export_file("*.mp3", "*.ogg", "*.wav") var bgm_path: String = ""
@export var auto_loop: bool = true
@export var play_on_ready: bool = true


func _ready() -> void:
	if bgm_path.is_empty():
		return
	if not ResourceLoader.exists(bgm_path):
		# File hasn't been downloaded yet — silent fallback.
		return
	var s: AudioStream = load(bgm_path) as AudioStream
	if s == null:
		return
	stream = s
	if auto_loop and "loop" in stream:
		stream.loop = true
	# Silence the persistent menu BGM autoload — this scene's track is taking over.
	var menu_music: Node = get_node_or_null("/root/MenuMusic")
	if menu_music and menu_music.has_method("stop_bgm"):
		menu_music.stop_bgm()
	if play_on_ready:
		play()

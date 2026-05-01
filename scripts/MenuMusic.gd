extends AudioStreamPlayer

# Autoload singleton (registered in project.godot as "MenuMusic").
# Holds ONE persistent AudioStreamPlayer that survives scene changes, so the
# menu BGM keeps playing seamlessly when navigating MainMenu ↔ Shop ↔ HowToPlay.
# Gameplay/story scenes call stop_bgm() in their own BGM's _ready so this
# track doesn't overlap with their scene-specific tracks.

const MENU_TRACK_PATH: String = "res://assets/audio/bgm/dungeon_loop.mp3"


func _ready() -> void:
	bus = &"Master"
	volume_db = -10.0
	# Don't autoplay — wait for the first menu scene to call ensure_playing().


func ensure_playing() -> void:
	# Called by menu scenes. No-op if already playing → music doesn't restart
	# when the scene changes between menus.
	if playing:
		return
	if stream == null:
		var s: AudioStream = load(MENU_TRACK_PATH) as AudioStream
		if s == null:
			return
		stream = s
		if "loop" in stream:
			stream.loop = true
	play()


func stop_bgm() -> void:
	if playing:
		stop()

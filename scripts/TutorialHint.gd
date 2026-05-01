extends Label

# Show for ~3s, fade out over 1s, then hide.

@export var visible_duration: float = 3.0
@export var fade_duration: float = 1.0


func _ready() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(visible_duration)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(queue_free)

extends ColorRect

func _ready() -> void:
	visible = true
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "position:y", get_viewport_rect().size.y, 1.0)

extends RichTextLabel

var target_y_pos: float
var addition_offset: float = 20.0
var tween: Tween

func _ready() -> void:
	target_y_pos = global_position.y
	global_position.y = target_y_pos - get_viewport_transform().origin.y - size.y
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "global_position:y", target_y_pos, 1.0)

func animate() -> void:
	global_position.y = target_y_pos - addition_offset
	tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "global_position:y", target_y_pos, 1.0)

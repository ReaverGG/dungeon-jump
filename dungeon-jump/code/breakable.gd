extends Node2D

@onready var right: Sprite2D = $Right
@onready var left: Sprite2D = $Left

var breakable_rotation: float = 55.5
func _ready() -> void:
	var tween: Tween = create_tween()
	var tween_time: float = 1.0
	tween.set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(right, "rotation_degrees", -breakable_rotation, tween_time)
	tween.tween_property(left, "rotation_degrees", breakable_rotation, tween_time)

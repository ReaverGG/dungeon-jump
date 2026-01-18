extends Node


func _hit_stop() -> void:
	var tween: Tween = create_tween()
	Engine.time_scale = 0.1
	tween.tween_property(Engine, "time_scale", 1.0, 0.25)

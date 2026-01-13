extends ColorRect

var player: CharacterBody2D

func _ready() -> void:
	# Player is injected by player.gd before added to tree
	if player:
		_animate()
	else:
		# Fallback just in case
		queue_free()

func _process(_delta: float) -> void:
	if not player: return
		
	var canvas_transform = player.get_global_transform_with_canvas()
	var screen_position = canvas_transform.origin
	var viewport_size = get_viewport_rect().size
	
	if viewport_size.x != 0 and viewport_size.y != 0:
		var uv_center = Vector2(
			screen_position.x / viewport_size.x,
			screen_position.y / viewport_size.y
		)
		material.set_shader_parameter("center", uv_center)

func _animate() -> void:
	material.set_shader_parameter("size", 0.0)
	var tween = create_tween()
	tween.tween_method(
		func(val): material.set_shader_parameter("size", val), 
		0.0, 3.5, 2.0
	).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	queue_free()

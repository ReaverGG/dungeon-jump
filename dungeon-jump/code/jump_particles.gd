extends GPUParticles2D

func _ready() -> void:
	emitting = true
	global_position.y -= 50
	
func _physics_process(delta: float) -> void:
	var canvas_transform = get_canvas_transform()
	var top_left = -canvas_transform.origin / canvas_transform.get_scale()
	var bottom_y = top_left.y + (get_viewport_rect().size.y / canvas_transform.get_scale().y)
	
	if global_position.y > bottom_y + 200:
		queue_free()

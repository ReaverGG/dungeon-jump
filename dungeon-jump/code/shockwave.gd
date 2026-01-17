extends ColorRect

var player: CharacterBody2D

func _ready() -> void:
	# Safety check: if player wasn't injected, delete self to prevent crash
	if player:
		_animate()
	else:
		queue_free()

func _process(_delta: float) -> void:
	# 1. Safety Check: Stop if player is dead/freed
	if not is_instance_valid(player):
		queue_free()
		return

	# 2. Get Viewport and Camera safely
	# This replaces the brittle "get_parent().get_parent().get_node('Camera')"
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d()
	var viewport_size = viewport.get_visible_rect().size
	
	if player.global_position.y < camera.global_position.y + 500:
		# 3. Calculate Screen Position
		# We use the Camera's smooth position to determine where the player is on screen.
		var screen_position = Vector2.ZERO
		
		if camera:
			# Math: (Player World Pos) - (Camera Top-Left Corner)
			# camera.get_screen_center_position() accounts for Smoothing/Interpolation
			var camera_top_left = camera.get_screen_center_position() - (viewport_size / 2.0)
			screen_position = player.global_position - camera_top_left
		else:
			# Fallback if no camera exists (rare)
			screen_position = player.get_global_transform_with_canvas().origin

		# 4. Normalize to UV (0.0 to 1.0) and update shader
		if viewport_size.x != 0 and viewport_size.y != 0:
			var uv_center = screen_position / viewport_size
			material.set_shader_parameter("center", uv_center)

func _animate() -> void:
	var tween = create_tween()
	tween.tween_method(
		func(val): material.set_shader_parameter("size", val), 
		0.0, 1.5, 5.0
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	queue_free()

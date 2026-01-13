class_name Shockwave
extends ColorRect

# Injected by Player.gd
var player: Node2D

# Shader Uniforms
const PARAM_CENTER: String = "center"
const PARAM_SIZE: String = "size"

func _ready() -> void:
	if not player:
		# Safety fallback: Only search if absolutely necessary
		player = get_tree().get_first_node_in_group("player")
		
	if player:
		start_animation()
	else:
		queue_free()

func _process(_delta: float) -> void:
	if not player:
		return
		
	update_shader_position()

func update_shader_position() -> void:
	# Calculate where the shockwave center (player) is on the screen (0.0 to 1.0)
	var screen_pos: Vector2 = player.get_global_transform_with_canvas().origin
	var viewport_size: Vector2 = get_viewport_rect().size
	
	if viewport_size.x > 0 and viewport_size.y > 0:
		var uv_center: Vector2 = Vector2(
			screen_pos.x / viewport_size.x,
			screen_pos.y / viewport_size.y
		)
		material.set_shader_parameter(PARAM_CENTER, uv_center)

func start_animation() -> void:
	material.set_shader_parameter(PARAM_SIZE, 0.0)
	
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	# Animate the "size" parameter from 0.0 to 1.5 over 3.5 seconds
	tween.tween_method(set_shockwave_size, 0.0, 1.5, 3.5)
	
	await tween.finished
	queue_free()

func set_shockwave_size(value: float) -> void:
	material.set_shader_parameter(PARAM_SIZE, value)

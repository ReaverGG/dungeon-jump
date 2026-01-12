class_name Tile
extends AnimatableBody2D

@export var sprite: Sprite2D
@export var wall_distance: float = 50.0

var direction: float = 1.0
var current_speed: float
var min_x: float
var max_x: float
var spawner: Node2D
var can_move: bool

var squish_tween: Tween
var base_scale: Vector2

var screen_offset: float = 200.0

func _ready() -> void:
	base_scale = sprite.scale
	spawner = get_parent().get_node("Spawner")
	can_move = randi() % 2 == 0 and name != "BaseTile"
	
	if randf() > 0.5:
		direction = 1.0
	else:
		direction = -1.0
		
	var collider_size = get_node("Collider").shape.size.x / 2
	var viewport_width = get_viewport_rect().size.x
	
	min_x = wall_distance + collider_size
	max_x = viewport_width - wall_distance - collider_size
	
	if sprite.texture.resource_path.ends_with("moving.png"):
		can_move = true
		current_speed = 200.0
	else:
		current_speed = 100.0

func _physics_process(delta: float) -> void:
	if can_move:
		global_position.x += current_speed * direction * spawner.speed_multiplier * delta
		
		if global_position.x < min_x:
			global_position.x = min_x
			direction = 1.0
		elif global_position.x > max_x:
			global_position.x = max_x
			direction = -1.0

	var screen_bottom = get_viewport_transform().affine_inverse().origin.y + get_viewport_rect().size.y

	if global_position.y > screen_bottom + screen_offset:
		queue_free()

func boing() -> void:
	if squish_tween:
		squish_tween.kill()
	
	sprite.scale = Vector2(randf_range(0.9, 1.1), randf_range(0.9, 1.1))
	
	squish_tween = create_tween()
	squish_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	squish_tween.tween_property(sprite, "scale", base_scale, 1.5)

func effect() -> String:
	var clean_name: String = sprite.texture.resource_path.get_file().get_basename()
	return clean_name

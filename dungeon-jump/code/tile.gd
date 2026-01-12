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

# Optimization: Cache the tile type string
var _tile_type: String

func _ready() -> void:
	base_scale = sprite.scale
	spawner = get_parent().get_node("Spawner")
	
	# Initial calculation
	_refresh_tile_data()
	
	# Random movement logic (Keep this separate from forced movement)
	can_move = randi() % 2 == 0 and name != "BaseTile"
	
	# Force movement if it is specifically a "moving" tile
	if _tile_type.ends_with("moving"):
		can_move = true
	
	if randf() > 0.5:
		direction = 1.0
	else:
		direction = -1.0
		
	var collider_size = get_node("Collider").shape.size.x / 2
	var viewport_width = get_viewport_rect().size.x
	
	min_x = wall_distance + collider_size
	max_x = viewport_width - wall_distance - collider_size
	
	update_speed()

func _physics_process(delta: float) -> void:
	if can_move:
		move_horizontal(delta)

	check_bounds()

# --- NEW FUNCTION FOR RUNTIME CHANGES ---
func change_type(new_texture: Texture2D) -> void:
	sprite.texture = new_texture
	# We MUST refresh the cached data immediately, or the game will
	# still think this is the old tile type.
	_refresh_tile_data()
	update_speed()

func _refresh_tile_data() -> void:
	# Parse the string again based on the NEW texture
	_tile_type = sprite.texture.resource_path.get_file().get_basename()

func update_speed() -> void:
	if _tile_type.ends_with("moving"):
		can_move = true
		current_speed = 200.0
	else:
		# Reset speed if we changed AWAY from a moving tile
		current_speed = 100.0
# ----------------------------------------

func move_horizontal(delta: float) -> void:
	global_position.x += current_speed * direction * spawner.speed_multiplier * delta
	
	if global_position.x < min_x:
		global_position.x = min_x
		direction = 1.0
	elif global_position.x > max_x:
		global_position.x = max_x
		direction = -1.0

func check_bounds() -> void:
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

# Returns the cached string instantly
func effect() -> String:
	return _tile_type

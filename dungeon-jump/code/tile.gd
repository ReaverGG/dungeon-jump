class_name Tile
extends AnimatableBody2D

enum Type { NORMAL, BREAKABLE, BOUNCY, MOVING, SPIKE, RED, STICKY, BLUE, MYSTERY, GOLDEN, DIAMOND }

@export var sprite: Sprite2D
@export var wall_distance: float = 50.0

@onready var collider: CollisionShape2D = $Collider
@onready var spawner: Spawner = get_parent().get_node("Spawner")

var type: Type = Type.NORMAL
var breakable_scene: PackedScene = preload("res://scenes/tile/breakable.tscn")
var should_move: bool
var direction: float = 1.0
var move_speed: float = 0.0
var min_x: float
var max_x: float
var base_scale: Vector2

var _squish_tween: Tween

func _ready() -> void:
	base_scale = sprite.scale
	_calculate_bounds()

func _physics_process(delta: float) -> void:
	if move_speed > 0:
		_handle_movement(delta)
	_check_bounds()

# Called by Spawner to initialize the tile
func setup(new_texture: Texture2D, new_type: Type) -> void:
	sprite.texture = new_texture
	type = new_type
	
	# Default behavior: 50% chance to move slowly
	should_move = randf() > 0.5
	var target_speed: float = 100.0

	match type:
		Type.MOVING:
			should_move = true   # ALWAYS moves
			target_speed = 200.0 # Fast speed
		
		Type.SPIKE:
			should_move = false

	if should_move:
		move_speed = target_speed
		direction = 1.0 if randf() > 0.5 else -1.0
	else:
		move_speed = 0.0

func crack() -> void:
	collider.set_deferred("disabled", true)
	should_move = false
	var breakable: Node2D = breakable_scene.instantiate()
	add_child(breakable)
	breakable.global_position = global_position
	sprite.visible = false
	await breakable.ready
	queue_free()
	

func boing() -> void:
	if _squish_tween:
		_squish_tween.kill()
	
	sprite.scale = Vector2(randf_range(0.9, 1.1), randf_range(0.9, 1.1))
	
	_squish_tween = create_tween()
	_squish_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_squish_tween.tween_property(sprite, "scale", base_scale, 1.5)

func _calculate_bounds() -> void:
	var collider_half_width = collider.shape.size.x / 2
	var viewport_width = get_viewport_rect().size.x
	min_x = wall_distance + collider_half_width
	max_x = viewport_width - wall_distance - collider_half_width

func _handle_movement(delta: float) -> void:
	if should_move:
		global_position.x += move_speed * direction * spawner.speed_multiplier * delta
	else:
		return
	
	if global_position.x < min_x:
		global_position.x = min_x
		direction = 1.0
	elif global_position.x > max_x:
		global_position.x = max_x
		direction = -1.0

func _check_bounds() -> void:
	var screen_bottom = get_viewport_transform().affine_inverse().origin.y + get_viewport_rect().size.y
	if global_position.y > screen_bottom + 200.0:
		queue_free()

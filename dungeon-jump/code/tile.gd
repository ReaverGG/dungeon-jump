class_name Tile
extends AnimatableBody2D

enum Type { NORMAL, BREAKABLE, BOUNCY, MOVING, SPIKE, RED, STICKY, BLUE, MYSTERY, GOLDEN, DIAMOND }

@export var sprite: Sprite2D
@export var wall_distance: float = 50.0
@export var screen_deletion_offset: float = 500.0

@onready var collider: CollisionShape2D = $Collider
@onready var spawner: Spawner = get_parent().get_node("Spawner")

# Optimization: Add a notifier to handle screen exit efficiently
var _notifier: VisibleOnScreenNotifier2D

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
	
	# --- FIX START ---
	_notifier = VisibleOnScreenNotifier2D.new()
	# Set a reasonable detection size (relative to tile center)
	_notifier.rect = Rect2(-50, -50, 100, 100)
	add_child(_notifier)
	
	_notifier.screen_entered.connect(func():
		# Only start listening for exit AFTER it has entered the screen once
		if not _notifier.screen_exited.is_connected(_on_screen_exited):
			_notifier.screen_exited.connect(_on_screen_exited)
	)
	# --- FIX END ---
	
	if not should_move:
		set_physics_process(false)

# New dedicated function to check logic before deleting
func _on_screen_exited() -> void:
	# 1. Check if player exists safely
	if not is_instance_valid(spawner.player):
		return

	# 2. Only delete if the tile is BELOW the player (plus a buffer of 500px)
	# If the tile is above the player (exited the top), we KEEP it.
	if global_position.y > spawner.player.global_position.y + screen_deletion_offset:
		queue_free()

func _physics_process(delta: float) -> void:
	# This function now ONLY runs for moving tiles.
	# The _check_bounds call is removed because the Notifier handles it.
	_handle_movement(delta)

# Called by Spawner to initialize the tile (or by change_tile)
func setup(new_texture: Texture2D, new_type: Type) -> void:
	sprite.texture = new_texture
	type = new_type
	
	# Default: 50% chance to move
	should_move = randf() > 0.5
	var target_speed: float = 100.0

	match type:
		Type.MOVING:
			should_move = true
			target_speed = 200.0
		Type.SPIKE:
			should_move = false
			
	# Reset movement properties
	if should_move:
		move_speed = target_speed
		# Randomize direction again so it doesn't get stuck
		direction = 1.0 if randf() > 0.5 else -1.0
	else:
		move_speed = 0.0

	# --- CRITICAL FIX ---
	# We must tell the engine to start/stop the physics loop
	# based on whether the tile is now supposed to move.
	set_physics_process(should_move)

func crack() -> void:
	collider.set_deferred("disabled", true)
	should_move = false
	# Ensure physics stops if it breaks
	set_physics_process(false) 
	
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
	# Safety check in case collider is missing
	if not collider or not collider.shape:
		return
		
	var collider_half_width = collider.shape.size.x / 2
	var viewport_width = get_viewport_rect().size.x
	min_x = wall_distance + collider_half_width
	max_x = viewport_width - wall_distance - collider_half_width

func _handle_movement(delta: float) -> void:
	global_position.x += move_speed * direction * spawner.speed_multiplier * delta
	
	if global_position.x < min_x:
		global_position.x = min_x
		direction = 1.0
	elif global_position.x > max_x:
		global_position.x = max_x
		direction = -1.0

func change_tile(to_tile: String) -> void:
	var new_type: Type = Type.NORMAL
	
	match to_tile.to_lower():
		"normal":    new_type = Type.NORMAL
		"breakable": new_type = Type.BREAKABLE
		"bouncy":    new_type = Type.BOUNCY
		"moving":    new_type = Type.MOVING
		"spike":     new_type = Type.SPIKE
		"red":       new_type = Type.RED
		"sticky":    new_type = Type.STICKY
		"blue":      new_type = Type.BLUE
		"mystery":   new_type = Type.MYSTERY
		"golden":    new_type = Type.GOLDEN
		"diamond":   new_type = Type.DIAMOND
		_:
			push_warning("Unknown tile type: " + to_tile)
			return

	# Debugging: Check if spawner exists
	if not spawner:
		push_error("Tile ERROR: 'spawner' is null. Check node path in Tile.gd: get_parent().get_node('Spawner')")
		return

	var tex_index: int = int(new_type)
	
	if tex_index < spawner.tiles.size():
		var new_texture = spawner.tiles[tex_index]
		setup(new_texture, new_type)
	else:
		push_error("Spawner tiles array is missing texture for index: " + str(tex_index))

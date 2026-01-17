class_name Player
extends CharacterBody2D

@export_group("Components")
@export var sprite: Sprite2D
@export var base_tile: Node2D
@export var spawner: Spawner
@export var label: RichTextLabel

@export_group("Movement")
@export var move_speed: float = 1670.0
@export var acceleration: float = 10.0
@export var deceleration: float = 10.0

@export_group("Physics")
@export var jump_force: float = 3300.0
@export var gravity: float = 5867.0
@export var rotation_divider: float = 80.0

@export_group("Shockwave")
@export var shockwave_scene: PackedScene
@onready var shockwave_container: Node = get_tree().current_scene.get_node("Shockwave") 

var _base_offset: float = 250.0
var _base_scale: Vector2
var _score_origin_y: float
var _record_y: float
var _is_locked: bool = true
var _squish_tween: Tween

var score: int = 0:
	set(value):
		if score != value:
			score = value
			_on_score_changed()

func _ready() -> void:
	_base_scale = sprite.scale
	_score_origin_y = base_tile.global_position.y - _base_offset
	_record_y = _score_origin_y
	
	global_position = Vector2(get_viewport_rect().size.x / 2.0, _score_origin_y + (_base_offset * 10.0))
	_animate_entry()

func _physics_process(delta: float) -> void:
	_handle_screen_wrap()
	_update_score()

	if not _is_locked:
		_handle_movement(delta)
		_handle_gravity(delta)
		sprite.rotation_degrees = velocity.x / rotation_divider
	
	_check_platform_collisions()
	move_and_slide()

func _handle_movement(delta: float) -> void:
	var direction: float = Input.get_axis("left", "right")
	
	if Input.is_action_pressed("click"):
		var center_x = get_viewport_rect().size.x / 2.0
		direction = 1.0 if get_global_mouse_position().x > center_x else -1.0
			
	if direction:
		sprite.flip_h = direction < 0
		velocity.x = lerp(velocity.x, move_speed * direction, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration * delta)

func _handle_gravity(delta: float) -> void:
	velocity.y += gravity * delta
	if is_on_floor():
		_jump()

func _jump() -> void:
	velocity.y = -jump_force
	_animate_squish()

func _check_platform_collisions() -> void:
	var processed_colliders = [] # 1. Create a list to track processed objects
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider() as Tile
		
		# 2. Check if valid AND if we haven't processed it yet
		if collider and not collider in processed_colliders:
			processed_colliders.append(collider) # 3. Mark as processed
			
			_handle_tile_effect(collider.type, collider)
			
			# Only play the boing animation if the tile didn't break
			if collider.type != Tile.Type.BREAKABLE:
				collider.boing()

func _handle_tile_effect(type: Tile.Type, collider: Tile) -> void:
	if type != Tile.Type.BOUNCY:
		gravity = 5867.0
	match type:
		Tile.Type.BOUNCY:
			gravity = 5000.0
			velocity.y = -7000.0
			_spawn_shockwave()
		Tile.Type.SPIKE:
			velocity.y = -jump_force / 1.67
		Tile.Type.BREAKABLE:
			if collider.has_method("crack"):
				velocity.y = -jump_force
				collider.crack()

func _spawn_shockwave() -> void:
	if not shockwave_scene: return
	
	var shockwave = shockwave_scene.instantiate()
	shockwave.player = self
	shockwave_container.add_child(shockwave)

func _update_score() -> void:
	if global_position.y < _record_y:
		_record_y = global_position.y
		score = int((_score_origin_y - _record_y) / spawner.tile_distance)

func _on_score_changed() -> void:
	label.text = str(score)
	label.animate()

func _handle_screen_wrap() -> void:
	global_position.x = wrapf(global_position.x, 0, get_viewport_rect().size.x)

func _animate_squish() -> void:
	if _squish_tween: _squish_tween.kill()
	
	sprite.scale = Vector2(0.5, 1.5)
	_squish_tween = create_tween()
	_squish_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_squish_tween.tween_property(sprite, "scale", _base_scale, 1.0)

func _animate_entry() -> void:
	sprite.rotation_degrees = 360 if randf() > 0.5 else -360
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
	tween.tween_property(self, "global_position:y", _score_origin_y, 1.0)
	tween.tween_property(sprite, "rotation_degrees", 0.0, 1.0)
	await tween.finished
	_is_locked = false

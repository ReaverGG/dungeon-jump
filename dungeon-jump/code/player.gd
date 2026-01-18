class_name Player
extends CharacterBody2D

@export_group("Components")
@export var sprite: Sprite2D
@export var base_tile: Node2D
@export var spawner: Spawner
@export var label: RichTextLabel
@export var animator: AnimationPlayer

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


var death_offset: float = Tile.new().screen_deletion_offset
var dead: bool = false

var _base_offset: float = 250.0
var _base_scale: Vector2
var _score_origin_y: float
var _record_y: float
var _is_locked: bool = true
var _squish_tween: Tween
var _processed_colliders: Array[Object] = []
var particle_scene: PackedScene = preload("res://scenes/player/jump_particles.tscn")

var max_health: int = 10
var health: int = 3:
	set(value):
		if value > max_health:
			value = max_health
		elif value < 0:
			value = 0
		health = value
		print(health)
var hearts_list: Array[Control]

var score: int = 0:
	set(value):
		if score != value:
			score = value
			_on_score_changed()

func _ready() -> void:
	var hearts_container = $"../UI/HeartContainer"
	for i in hearts_container.get_children():
		hearts_list.append(i)
	_update_heart_display()
	_base_scale = sprite.scale
	_score_origin_y = base_tile.global_position.y - _base_offset
	_record_y = _score_origin_y
	
	global_position = Vector2(get_viewport_rect().size.x / 2.0, _score_origin_y + (_base_offset * 10.0))
	_animate_entry()

func _physics_process(delta: float) -> void:
	_handle_screen_wrap()
	_update_score()
	if _is_locked == false and !dead:
		_handle_death()

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

func _jump() -> void:
	velocity.y = -jump_force

func _check_platform_collisions() -> void:
	# Clear the array to reuse it instead of creating a new one
	_processed_colliders.clear()
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider() as Tile
		
		# Check if valid and not processed
		if collider and not collider in _processed_colliders:
			_processed_colliders.append(collider)
			
			_handle_tile_effect(collider.type, collider)
			
			# Only play the boing animation if the tile didn't break
			if collider.type != Tile.Type.BREAKABLE:
				if _is_locked == false:
					collider.boing()

func _handle_tile_effect(type: Tile.Type, collider: Tile) -> void:
	var particles := particle_scene.instantiate()
	particles.global_position = get_node("Collider").global_position + Vector2(0, get_node("Collider").shape.size.y)
	get_parent().add_child(particles)
	
	_jump()
	if type != Tile.Type.BOUNCY:
		gravity = 5867.0
	if type != Tile.Type.SPIKE and type != Tile.Type.RED:
		_animate_squish()
	match type:
		Tile.Type.BOUNCY:
			gravity = 4000.0
			velocity.y = -7000.0
			_add_juice()
			_spawn_shockwave()
		Tile.Type.SPIKE:
			take_damage(1)
			velocity.y = -jump_force / 1.2
			GameManager._hit_stop()
		Tile.Type.BREAKABLE:
			if collider.has_method("crack"):
				velocity.y = -jump_force
				collider.crack()
		Tile.Type.RED:
			take_damage(2)
			velocity.y = -jump_force / 1.2
			GameManager._hit_stop()

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
	var viewport_width = get_viewport_rect().size.x
	
	var new_x = wrapf(global_position.x, 0, viewport_width)
	
	if new_x != global_position.x:
		global_position.x = new_x
		reset_physics_interpolation()

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

func _handle_death() -> void:
	var death_line = _record_y + get_viewport_rect().size.y / 2
	if global_position.y > death_line:
		dead = true
		take_damage(max_health)
		GameManager._hit_stop()

func _add_juice() -> void:
	pass
	#modulate = Color.BLACK
	#var modulate_tween: Tween = create_tween()
	#modulate_tween.tween_property(self, "modulate", Color.WHITE, 1.0)

func take_damage(amount: int) -> void:
	if !dead:
		animator.stop()
		animator.play("hit")
		health -= amount
		_update_heart_display()
		
func _update_heart_display() -> void:
	for i in range(hearts_list.size()):
		var should_show: bool = i < health
		if should_show == false:
			hearts_list[i].animator.play("die")
		else:
			hearts_list[i].animator.play("spawn")

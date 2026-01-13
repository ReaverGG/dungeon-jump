class_name Player
extends CharacterBody2D

@export_group("Components")
@export var sprite: Sprite2D
@export var base_tile: Node2D
@export var spawner: Spawner

@export_group("Movement")
@export var move_speed: float = 1670.0
@export var acceleration: float = 10.0
@export var deceleration: float = 10.0

@export_group("Physics")
@export var jump_force: float = 3300.0
@export var gravity: float = 5867.0
@export var rotation_divider: float = 80.0

@export_group("UI")
@export var label: Label

@export_group("Shockwave")
@export var shockwave_spawner: CanvasLayer
@export var shockwave_scene: PackedScene

var base_offset: float = 250.0
var base_scale: Vector2
var score_origin_y: float
var record_y: float
var is_locked: bool = true
var squish_tween: Tween

# Score Logic
var score: int = 0:
	set(value):
		if score != value:
			score = value
			_on_score_increased()
			label.text = str(score)

func _ready() -> void:
	add_to_group("player") # Optimization: Allows easy lookup without tree crawling
	
	base_scale = sprite.scale
	score_origin_y = base_tile.global_position.y - base_offset
	record_y = score_origin_y
	
	# Center player horizontally
	var viewport_x = get_viewport_rect().size.x
	global_position = Vector2(viewport_x / 2.0, score_origin_y + (base_offset * 10.0))
	
	animate_entry()

func _physics_process(delta: float) -> void:
	handle_screen_wrap()
	update_score()

	if not is_locked:
		handle_movement(delta)
		handle_gravity(delta)
		sprite.rotation_degrees = velocity.x / rotation_divider
	
	check_platform_collisions()
	move_and_slide()

# --- Movement & Physics ---

func handle_movement(delta: float) -> void:
	var direction: float = Input.get_axis("left", "right")
	
	# Mobile Touch Input
	if Input.is_action_pressed("click"):
		var viewport_center = get_viewport_rect().size.x / 2.0
		direction = 1.0 if get_global_mouse_position().x > viewport_center else -1.0
			
	if direction:
		sprite.flip_h = direction < 0
		velocity.x = lerp(velocity.x, move_speed * direction, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration * delta)

func handle_gravity(delta: float) -> void:
	velocity.y += gravity * delta
	if is_on_floor():
		jump()

func jump() -> void:
	velocity.y = -jump_force
	animate_squish()

func handle_screen_wrap() -> void:
	var viewport_width = get_viewport_rect().size.x
	global_position.x = wrapf(global_position.x, 0, viewport_width)

# --- Gameplay Logic ---

func update_score() -> void:
	if global_position.y < record_y:
		record_y = global_position.y
		score = int((score_origin_y - record_y) / spawner.tile_distance)

func _on_score_increased() -> void:
	if spawner.speed_multiplier < 2:
		spawner.speed_multiplier += 0.1

func check_platform_collisions() -> void:
	var hit_this_frame: Array[Object] = []
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		
		# Ensure we only process each tile once per frame
		if collider is Tile and not hit_this_frame.has(collider):
			hit_this_frame.append(collider)
			apply_tile_effect(collider)
			collider.boing()

func apply_tile_effect(tile: Tile) -> void:
	var effect_name = tile.effect()
	
	if effect_name == "bouncy":
		velocity.y = -7000
		spawn_shockwave()
		
	elif effect_name == "spike":
		velocity.y = -jump_force / 1.67

func spawn_shockwave() -> void:
	if not shockwave_scene: return
	
	var shockwave = shockwave_scene.instantiate()
	if shockwave is Shockwave:
		shockwave.player = self
		
	get_parent().get_node("Shockwave").add_child(shockwave)

# --- Animations ---

func animate_squish() -> void:
	if squish_tween: squish_tween.kill()
	
	sprite.scale = Vector2(0.5, 1.5)
	squish_tween = create_tween()
	squish_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	squish_tween.tween_property(sprite, "scale", base_scale, 1.0)

func animate_entry() -> void:
	sprite.rotation_degrees = 360 if randf() > 0.5 else -360
	
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
	tween.tween_property(self, "global_position:y", score_origin_y, 1.0)
	tween.tween_property(sprite, "rotation_degrees", 0.0, 1.0)
	
	await tween.finished
	is_locked = false

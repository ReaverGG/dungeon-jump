class_name Spawner
extends Node2D

@export var base_tile: AnimatableBody2D
@export var player: CharacterBody2D
@export var tile_scene: PackedScene
@export var tiles: Array[Texture2D]
@export var max_dangerous_streak: int = 2

var speed_multiplier: float = 1.0
var wall_distance: float = 20.0
var tile_distance: int = 300
var tiles_ahead: int = 5
var spawn_history: Array[bool] = []

# Weights Configuration
var tile_variants: Array[Dictionary] = [
	{ "weight": 35.0, "is_dangerous": false, "texture_index": 0 }, # NORMAL
	{ "weight": 12.0, "is_dangerous": false, "texture_index": 1 }, # BREAKABLE
	{ "weight": 8.0,  "is_dangerous": false, "texture_index": 2 }, # BOUNCY
	{ "weight": 8.0,  "is_dangerous": false, "texture_index": 3 }, # MOVING
	{ "weight": 15.0, "is_dangerous": true,  "texture_index": 4 }, # SPIKE
	{ "weight": 10.0, "is_dangerous": true,  "texture_index": 5 }, # RED
	{ "weight": 8.0,  "is_dangerous": false, "texture_index": 6 }, # STICKY
	{ "weight": 5.0,  "is_dangerous": false, "texture_index": 7 }, # BLUE
	{ "weight": 2.5,  "is_dangerous": false, "texture_index": 8 }, # MYSTERY
	{ "weight": 0.9,  "is_dangerous": false, "texture_index": 9 }, # GOLDEN
	{ "weight": 0.1,  "is_dangerous": false, "texture_index": 10 } # DIAMOND
]

func _ready() -> void:
	global_position.y = base_tile.global_position.y

func _process(delta: float) -> void:
	speed_multiplier += delta / 100.0
	
	if player and should_spawn_tile():
		spawn_next_tile()

func should_spawn_tile() -> bool:
	return global_position.y + tile_distance * tiles_ahead > player.global_position.y

func spawn_next_tile() -> void:
	global_position.y -= tile_distance
	create_tile()

func create_tile() -> void:
	var tile = tile_scene.instantiate()
	var data = pick_variant()

	update_history(data.is_dangerous)

	tile.get_node("Sprite").texture = tiles[data.texture_index]
	tile.global_position = get_random_x_position(tile)
	
	get_parent().add_child(tile)

func update_history(is_dangerous: bool) -> void:
	spawn_history.append(is_dangerous)
	if spawn_history.size() > max_dangerous_streak:
		spawn_history.pop_front()

func pick_variant() -> Dictionary:
	var force_safe: bool = false
	
	# Prevent too many dangerous tiles in a row
	if spawn_history.size() == max_dangerous_streak:
		if spawn_history.all(func(x): return x):
			force_safe = true

	var available_variants: Array = []
	var total_weight: float = 0.0

	for variant in tile_variants:
		if force_safe and variant.is_dangerous:
			continue
		available_variants.append(variant)
		total_weight += variant.weight

	var random_value: float = randf_range(0.0, total_weight)
	var current_weight: float = 0.0

	for variant in available_variants:
		current_weight += variant.weight
		if random_value <= current_weight:
			return variant
	
	return available_variants[0]

func get_random_x_position(tile_object) -> Vector2:
	var collider_width = tile_object.get_node("Collider").shape.size.x
	var min_x = wall_distance + collider_width / 2
	var max_x = get_viewport_rect().size.x - wall_distance - collider_width / 2
	
	return Vector2(randf_range(min_x, max_x), global_position.y)

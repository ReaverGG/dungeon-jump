class_name Spawner
extends Node2D

@export var base_tile: AnimatableBody2D
@export var player: Player
@export var tile_scene: PackedScene
@export var tiles: Array[Texture2D] 
@export var max_dangerous_streak: int = 2

# Speed increases by 0.05 for every 1 score. Maxes out at 2.0x speed.
@export var difficulty_scale: float = 0.05 

var speed_multiplier: float = 1.0
var tile_distance: int = 300
var tiles_ahead: int = 5
var _spawn_history: Array[bool] = []
var _wall_distance: float = 20.0

var tile_variants: Array[Dictionary] = [
	{ "weight": 35.0, "danger": false, "type": Tile.Type.NORMAL,    "tex": 0 },
	{ "weight": 12.0, "danger": false, "type": Tile.Type.BREAKABLE, "tex": 1 },
	{ "weight": 8.0,  "danger": false, "type": Tile.Type.BOUNCY,    "tex": 2 },
	{ "weight": 8.0,  "danger": false, "type": Tile.Type.MOVING,    "tex": 3 },
	{ "weight": 15.0, "danger": true,  "type": Tile.Type.SPIKE,     "tex": 4 },
	{ "weight": 10.0, "danger": true,  "type": Tile.Type.RED,       "tex": 5 },
	{ "weight": 8.0,  "danger": false, "type": Tile.Type.STICKY,    "tex": 6 },
	{ "weight": 5.0,  "danger": false, "type": Tile.Type.BLUE,      "tex": 7 },
	{ "weight": 2.5,  "danger": false, "type": Tile.Type.MYSTERY,   "tex": 8 },
	{ "weight": 0.9,  "danger": false, "type": Tile.Type.GOLDEN,    "tex": 9 },
	{ "weight": 0.1,  "danger": false, "type": Tile.Type.DIAMOND,   "tex": 10 }
]

func _ready() -> void:
	if base_tile:
		global_position.y = base_tile.global_position.y

func _process(_delta: float) -> void:
	if player:
		# Calculate speed based on score: 1.0 + (Score * Scale)
		var target_speed = 1.0 + (float(player.score) * difficulty_scale)
		# Ensure it stays under 2.0
		speed_multiplier = min(target_speed, 2.0)
		
		if _should_spawn_tile():
			_spawn_next_tile()

func _should_spawn_tile() -> bool:
	return global_position.y + (tile_distance * tiles_ahead) > player.global_position.y

func _spawn_next_tile() -> void:
	global_position.y -= tile_distance
	_create_tile()

func _create_tile() -> void:
	var tile = tile_scene.instantiate() as Tile
	var data = _pick_variant()

	_update_history(data.danger)

	# Safety Check: Use texture if available, otherwise default to 0
	if tiles.size() > data.tex:
		tile.setup(tiles[data.tex], data.type)
	else:
		if tiles.size() > 0:
			tile.setup(tiles[0], data.type)
	
	var x_pos = _get_random_x_position(tile)
	tile.global_position = Vector2(x_pos, global_position.y)
	
	get_parent().add_child(tile)

func _pick_variant() -> Dictionary:
	var force_safe: bool = false
	
	if _spawn_history.size() >= max_dangerous_streak:
		if _spawn_history.all(func(x): return x):
			force_safe = true

	var available_variants: Array = []
	var total_weight: float = 0.0

	for variant in tile_variants:
		if force_safe and variant.danger:
			continue
		available_variants.append(variant)
		total_weight += variant.weight

	var random_val: float = randf_range(0.0, total_weight)
	var current_weight: float = 0.0

	for variant in available_variants:
		current_weight += variant.weight
		if random_val <= current_weight:
			return variant
	
	return tile_variants[0]

func _update_history(is_dangerous: bool) -> void:
	_spawn_history.append(is_dangerous)
	if _spawn_history.size() > max_dangerous_streak:
		_spawn_history.pop_front()

func _get_random_x_position(tile: Tile) -> float:
	var width = 100.0
	var collider = tile.get_node_or_null("Collider")
	if collider and collider.shape:
		width = collider.shape.size.x
		
	var min_x = _wall_distance + (width / 2)
	var max_x = get_viewport_rect().size.x - _wall_distance - (width / 2)
	
	return randf_range(min_x, max_x)

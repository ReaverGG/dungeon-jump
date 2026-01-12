extends Camera2D

@export var player: CharacterBody2D
@export var speed: float = 4.0

var last_y_pos: float

func _physics_process(delta: float) -> void:
	if player:
		last_y_pos = player.global_position.y
	global_position.y = lerp(global_position.y, last_y_pos, speed * delta)

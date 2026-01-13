extends Sprite2D

@export var texture_array: Array[Texture2D]

func _ready() -> void:
	if texture_array.size() > 0:
		switch_texture(texture_array[0])

func switch_texture(to_texture: Texture2D) -> void:
	texture = to_texture

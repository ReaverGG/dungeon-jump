extends Control

@onready var texture: Sprite2D = $Texture
# Get the animator to trigger shader-based cracking
@onready var animator: AnimationPlayer = $Animator 

var should_show: bool = true:
	set(value):
		if should_show == value:
			return
		
		should_show = value
		
		if not is_node_ready():
			return
		if should_show:
			# Animate the texture scale back to normal
			animator.play("spawn") # Reset the shader crack
		else:
			# Animate the texture shrinking
			animator.play("die") # Play the shader crack

func _ready() -> void:
	if texture.material:
		texture.material = texture.material.duplicate()
	
	# Set initial state
	if not should_show:
		scale = Vector2.ZERO

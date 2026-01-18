extends Control
var animator: AnimationPlayer

var should_show: bool = true:
	set(value):
		if value == true:
			animator.play("spawn")
		else:
			animator.play("die")
		should_show = value

func _ready() -> void:
	animator = $Animator

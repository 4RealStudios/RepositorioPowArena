extends CharacterBody2D
@export var speed: float = 250

func _physics_process(delta: float) -> void:
	var input_vector = Input.get_vector("p1_left", "p1_right", "p1_up", "p1_down")
	velocity = input_vector * speed
	move_and_slide()

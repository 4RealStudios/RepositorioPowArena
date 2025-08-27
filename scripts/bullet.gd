extends Area2D

@export var speed: float = 600
var direction : Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if direction != Vector2.ZERO:
		position += direction * speed * delta

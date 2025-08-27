extends Area2D

@export var speed: float = 750 
var direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	position += direction * speed * delta

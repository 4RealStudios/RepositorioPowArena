extends Area2D

@export var speed: float = 160
var direction : Vector2

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("Players"):
		body.take_damage()
		queue_free() #destruye la bala al impactar

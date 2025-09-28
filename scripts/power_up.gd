extends Area2D

enum PowerUpType { BOUNCE }

@export var type: PowerUpType
@export var duration := 1

signal picked_up(player, type)

func _on_body_entered(body):
	if body.is_in_group("Players"):
		emit_signal("picked_up", body, type)
		queue_free()

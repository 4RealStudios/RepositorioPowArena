extends Node2D

func _ready():
	for child in get_children():
		if child is Area2D:
			child.connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("Players"):
		body.take_damage()

extends Node2D

func _ready() -> void:
	for wall in get_children():
		if wall.has_node("Area2D"):
			var area: Area2D = wall.get_node("Area2D")
			area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Players"):
		if body.has_method("take_damage"):
			body.take_damage() 

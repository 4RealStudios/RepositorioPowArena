extends Area2D

@export var hud_root: CanvasItem  # arrastrás tu HUD aquí en el editor
@export var faded_alpha := 0.6
@export var normal_alpha := 1.0

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Players"):  # asegurate de que tus players estén en este grupo
		hud_root.modulate.a = faded_alpha

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Players"):
		hud_root.modulate.a = normal_alpha

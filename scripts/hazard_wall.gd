extends StaticBody2D

@export var damage := 1
@export var hazard_type := "wall"  # puede ser "wall" o "corner"

@onready var sprite := $AnimatedSprite2D
@onready var hazard_area := $Area2D

func _ready():
	# Selecciona el sprite/animación
	sprite.play(hazard_type)

	# Conectamos detección de daño
	hazard_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):  # asegurate que tus jugadores estén en este grupo
		if body.has_method("take_damage"):
			body.take_damage(damage)

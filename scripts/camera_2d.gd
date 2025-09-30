extends Camera2D

var shake_strength: float = 0.0
var shake_decay: float = 4.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	make_current()

func _process(delta: float) -> void:
	if shake_strength > 0:
		offset = Vector2(
			rng.randf_range(-shake_strength, shake_strength),
			rng.randf_range(-shake_strength, shake_strength)
		)
		shake_strength = max(shake_strength - shake_decay * delta, 0)
	else:
		offset = Vector2.ZERO

func shake(amount: float = 5.0) -> void:
	shake_strength = amount

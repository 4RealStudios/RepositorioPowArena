extends Area2D

enum PowerUpType { SPEED, HEAL, SHIELD, BOUNCE }

@export var type: PowerUpType = PowerUpType.BOUNCE
@export var duration: float = 8.0
@export var atlas_texture: Texture2D
@onready var sprite: Sprite2D = $Sprite2D

signal picked_up(player, type)

func _ready() -> void:
	_set_icon_from_type()
	#connect("body_entered", Callable(self, "_on_body_entered"))

func _set_icon_from_type() -> void:
	if atlas_texture == null:
		push_warning("⚠️ No hay atlas_texture asignado.")
		return

	var region := Rect2()

	match type:
		PowerUpType.SPEED:
			region = Rect2(48, 0, 14, 14)
		PowerUpType.HEAL:
			region = Rect2(16, 0, 14, 14)
		PowerUpType.SHIELD:
			region = Rect2(32, 0, 14, 14)
		PowerUpType.BOUNCE:
			region = Rect2(0, 0, 14, 14)

	var tex := AtlasTexture.new()
	tex.atlas = atlas_texture
	tex.region = region
	sprite.texture = tex

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Players"):
		print("⚡ PowerUp recogido:", type)
		emit_signal("picked_up", body, type)
		queue_free()

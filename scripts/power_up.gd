extends Area2D

enum PowerUpType { SPEED, HEAL, SHIELD, BOUNCE }

@export var type: PowerUpType = PowerUpType.BOUNCE
@export var duration: float = 8.0
@export var atlas_texture: Texture2D
@export var lifetime: float = 20.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var fx_sprites: AnimatedSprite2D = $AnimatedSprite2D

signal picked_up(player, type)

func _ready() -> void:
	_set_icon_from_type()
	connect("body_entered", Callable(self, "_on_body_entered"))
	_despawn_after_time()

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
	if not body or not body.is_in_group("Players"):
		return
	
	emit_signal("picked_up", body, type)
	_play_pickup_animation(body)
	
	var powerup_name: String = ""
	match type:
		PowerUpType.SPEED:
			powerup_name = "speed"
		PowerUpType.SHIELD:
			powerup_name = "shield"
		PowerUpType.BOUNCE:
			powerup_name = "bounce"

	var player_id: int = 1
	var val = body.get("player_id")
	if val != null:
		player_id = int(val)

	var hud = get_tree().get_first_node_in_group("ui")
	if hud:
		print("[PowerUp] Player", player_id, "picked", powerup_name)
		hud.show_powerup(player_id, powerup_name, duration)
	else:
		print("[PowerUp] ⚠️ HUD no encontrado (group 'ui')")

func _play_pickup_animation(player: Node) -> void:
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = fx_sprites.sprite_frames
	match type:
		PowerUpType.SPEED: fx.animation = "speed_pick"
		PowerUpType.HEAL:  fx.animation = "heal_pick"
		PowerUpType.SHIELD: fx.animation = "shield_pick"
		PowerUpType.BOUNCE: fx.animation = "bounce_pick"
	player.add_child(fx)
	fx.position = Vector2.ZERO
	fx.play()
	
	match type:
		PowerUpType.SHIELD:
			player.activate_shield(duration)
	
	queue_free()


func _despawn_after_time() -> void:
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

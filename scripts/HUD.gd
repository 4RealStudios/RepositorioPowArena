extends CanvasLayer

const BLINK_THRESHOLD := 0.25
const BLINK_SPEED := 0.3
const ICON_ATLAS := preload("res://assets/HUD/hud iconos vida.png")
const ROUND_ICON_ATLAS := preload("res://assets/HUD/hud iconos rondas.png")
const ICON_SIZE := Vector2(22, 22)
const ICON_MAP := {
	"robot": {"default": Vector2(0, 0), "alternate": Vector2(24, 0)},
	"panda": {"default": Vector2(0, 24), "alternate": Vector2(24, 24)},
	"mago": {"default": Vector2(0, 48), "alternate": Vector2(24, 48)},
	"hunter": {"default": Vector2(0, 72), "alternate": Vector2(24, 72)},
}

const ROUND_ICON_SIZE := Vector2(23, 23)
const ROUND_ICON_MAP := {
	"robot": {"default": Vector2(0, 0), "alternate": Vector2(23, 0)},
	"panda": {"default": Vector2(0, 24), "alternate": Vector2(23, 24)},
	"mago": {"default": Vector2(0, 48), "alternate": Vector2(23, 48)},
	"hunter": {"default": Vector2(0, 72), "alternate": Vector2(23, 72)},
} 

@onready var icono_jugador1 = $MarginContainer/HBoxContainer/P1_HUD/P1_ICON/Icon_Player1
@onready var icono_jugador2 = $MarginContainer/HBoxContainer/P2_HUD/P2_ICON/Icon_Player2
@onready var icono_resultado1 = $RoundsResults/RoundsPanel/iconP1
@onready var icono_resultado2 = $RoundsResults/RoundsPanel/iconP2

@onready var vidas_p1 = [
	$"MarginContainer/HBoxContainer/P1_HUD/Vida1_P1",
	$"MarginContainer/HBoxContainer/P1_HUD/Vida2_P1",
	$"MarginContainer/HBoxContainer/P1_HUD/Vida3_P1"
]

@onready var vidas_p2 = [
	$"MarginContainer/HBoxContainer/P2_HUD/Vida1_P2",
	$"MarginContainer/HBoxContainer/P2_HUD/Vida2_P2",
	$"MarginContainer/HBoxContainer/P2_HUD/Vida3_P2"
]

@onready var powerups_p1 = {
	"speed": $MarginContainer/HBoxContainer/P1_HUD/P1_ICON/PowerUpsP1/powerup_speed_p1,
	"shield": $MarginContainer/HBoxContainer/P1_HUD/P1_ICON/PowerUpsP1/powerup_shield_p1,
	"bounce": $MarginContainer/HBoxContainer/P1_HUD/P1_ICON/PowerUpsP1/powerup_bounce_p1,
}

@onready var powerups_p2 = {
	"speed": $MarginContainer/HBoxContainer/P2_HUD/P2_ICON/PowerUpsP2/powerup_speed_p2,
	"shield": $MarginContainer/HBoxContainer/P2_HUD/P2_ICON/PowerUpsP2/powerup_shield_p2,
	"bounce": $MarginContainer/HBoxContainer/P2_HUD/P2_ICON/PowerUpsP2/powerup_bounce_p2,
}

var active_powerups_p1: Dictionary = {}
var active_powerups_p2: Dictionary = {}

func _ready() -> void:
	add_to_group("ui")
	for icon in powerups_p1.values():
		icon.visible = false
		icon.modulate = Color(1, 1, 1, 0.5)
	for icon in powerups_p2.values():
		icon.visible = false
		icon.modulate = Color(1, 1, 1, 0.5)
	
	for vida in vidas_p1:
		vida.modulate = Color(1, 1, 1, 0.6)
	for vida in vidas_p2:
		vida.modulate = Color(1, 1, 1, 0.6)
	
	icono_jugador1.modulate = Color(1, 1, 1, 0.6)
	icono_jugador2.modulate = Color(1, 1, 1, 0.6)
	icono_resultado1.modulate = Color(1, 1, 1, 0.6)
	icono_resultado2.modulate = Color(1, 1, 1, 0.6)
	
	set_player_icon(1, Global.player1_choice, Global.player1_alt)
	set_player_icon(2, Global.player2_choice, Global.player2_alt)
	set_round_result_icon(1, Global.player1_choice, Global.player1_alt)
	set_round_result_icon(2, Global.player2_choice, Global.player2_alt)

func _process(delta: float) -> void:
	update_powerups(active_powerups_p1, powerups_p1, delta)
	update_powerups(active_powerups_p2, powerups_p2, delta)

func update_lives(player_id: int, lives: int) -> void:
	var vidas = vidas_p1 if player_id == 1 else vidas_p2
	for i in range(vidas.size()):
		vidas[i].visible = i < lives

func get_icon_texture(row: int, column: int) -> Texture2D:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = ICON_ATLAS
	atlas_texture.region = Rect2(column * ICON_SIZE.x, row * ICON_SIZE.y, ICON_SIZE.x, ICON_SIZE.y)
	return atlas_texture

func set_player_icon(player_id: int, skin_name: String, is_alternate: bool = false) -> void:
	if not ICON_MAP.has(skin_name):
		print("[HUD] ⚠️ Skin sin ícono definido:", skin_name)
		return
	var region = ICON_MAP[skin_name].get("default")
	if is_alternate:
		region = ICON_MAP[skin_name].get("alternate")
	var tex := AtlasTexture.new()
	tex.atlas = ICON_ATLAS
	tex.region = Rect2(region, ICON_SIZE)
	if player_id == 1:
		icono_jugador1.texture = tex
	else:
		icono_jugador2.texture = tex

func update_player_icons(player1_skin: String, player2_skin: String) -> void:
	var player1_alternate = false
	var player2_alternate = false
	if player1_skin == player2_skin:
		player2_alternate = true  
		set_player_icon(1, player1_skin, false)
		set_player_icon(2, player2_skin, player2_alternate)

func set_round_result_icon(player_id: int, skin_name: String, is_alternate: bool = false) -> void:
	if not ROUND_ICON_MAP.has(skin_name):
		print("[HUD] ⚠️ Skin sin ícono definido para resultados:", skin_name)
		return
	var region = ROUND_ICON_MAP[skin_name].get("default")
	if is_alternate:
		region = ROUND_ICON_MAP[skin_name].get("alternate")
	
	var tex := AtlasTexture.new()
	tex.atlas = ROUND_ICON_ATLAS
	tex.region = Rect2(region, ICON_SIZE)
	
	if player_id == 1:
		icono_resultado1.texture = tex
	else:
		icono_resultado2.texture = tex

func row_for_skin(skin_name: String) -> int:
	match skin_name:
		"robot": return 0
		"mago": return 1
		"panda": return 2
		"hunter": return 3
		_: return 0

func update_powerups(active_dict: Dictionary, icons_dict: Dictionary, delta: float) -> void:
	var to_remove := []
	for name in active_dict.keys():
		if not icons_dict.has(name):
			continue
		var data = active_dict[name]
		data["time_left"] -= delta
		var icon: TextureRect = icons_dict[name]
		if data["time_left"] <= 0.0:
			icon.visible = false
			stop_blink(icon)
			icon.modulate = Color.WHITE
			to_remove.append(name)
			continue
		var percent_left = data["time_left"] / data["duration"]
		if percent_left <= BLINK_THRESHOLD and not data["blinking"]:
			start_blink(icon)
			data["blinking"] = true
		elif percent_left > BLINK_THRESHOLD and data["blinking"]:
			stop_blink(icon)
			data["blinking"] = false
	for k in to_remove:
		active_dict.erase(k)

func start_blink(icon: TextureRect) -> void:
	var prev = icon.get_meta("blink_tween")
	if prev and prev.is_valid() and prev.is_running():
		prev.kill()
	var t = create_tween()
	t.set_loops(-1)
	t.tween_property(icon, "modulate:a", 0.2, BLINK_SPEED).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(icon, "modulate:a", 1.0, BLINK_SPEED)
	icon.set_meta("blink_tween", t)

func stop_blink(icon: TextureRect):
	var tween = icon.get_meta("blink_tween")
	if tween and tween.is_valid() and tween.is_running():
		tween.kill()
	icon.set_meta("blink_tween", null)
	icon.modulate = Color.WHITE

func show_powerup(player_id: int, powerup_name: String, duration: float):
	print("[HUD] show_powerup -> player:", player_id, " powerup:", powerup_name, " duration:", duration)

	var icons_dict = powerups_p1 if player_id == 1 else powerups_p2
	var active_dict = active_powerups_p1 if player_id == 1 else active_powerups_p2

	if not icons_dict.has(powerup_name):
		print("[HUD] ❌ PowerUp no encontrado:", powerup_name)
		return

	var icon = icons_dict[powerup_name]
	if not is_instance_valid(icon):
		print("[HUD] ❌ Icono inválido.")
		return

	icon.visible = true
	icon.modulate = Color(1, 1, 1, 0.5)

	active_dict[powerup_name] = {
		"duration": duration,
		"time_left": duration,
		"blinking": false
	}
	print("[HUD] ✅ Icono mostrado:", powerup_name, "para jugador", player_id)

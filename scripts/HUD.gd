extends CanvasLayer

const BLINK_THRESHOLD := 0.25
const BLINK_SPEED := 0.3

@onready var powerups_p1 = {
	"speed": $MarginContainer/HBoxContainer/Vidas_P1/PowerUpsP1/powerup_speed_p1,
	"shield": $MarginContainer/HBoxContainer/Vidas_P1/PowerUpsP1/powerup_shield_p1,
	"bounce": $MarginContainer/HBoxContainer/Vidas_P1/PowerUpsP1/powerup_bounce_p1,
}

@onready var powerups_p2 = {
	"speed": $MarginContainer/HBoxContainer/Vidas_P2/PowerUpsP2/powerup_speed_p2,
	"shield": $MarginContainer/HBoxContainer/Vidas_P2/PowerUpsP2/powerup_shield_p2,
	"bounce": $MarginContainer/HBoxContainer/Vidas_P2/PowerUpsP2/powerup_bounce_p2,
}

var active_powerups_p1: Dictionary = {}
var active_powerups_p2: Dictionary = {}

func _ready() -> void:
	add_to_group("ui")
	# Ocultamos todos los iconos al iniciar
	for icon in powerups_p1.values():
		icon.visible = false
		icon.modulate = Color.WHITE
	for icon in powerups_p2.values():
		icon.visible = false
		icon.modulate = Color.WHITE
	print("[HUD] Script cargado correctamente.")

func _process(delta: float) -> void:
	update_powerups(active_powerups_p1, powerups_p1, delta)
	update_powerups(active_powerups_p2, powerups_p2, delta)

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
	icon.modulate = Color(1, 1, 1, 1)

	active_dict[powerup_name] = {
		"duration": duration,
		"time_left": duration,
		"blinking": false
	}
	print("[HUD] ✅ Icono mostrado:", powerup_name, "para jugador", player_id)

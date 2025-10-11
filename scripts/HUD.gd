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

func update_lives(player_id: int, lives: int):
	if player_id == 1:
		var hearts = [
			$MarginContainer/HBoxContainer/Vidas_P1/Vida1_P1,
			$MarginContainer/HBoxContainer/Vidas_P1/Vida2_P1,
			$MarginContainer/HBoxContainer/Vidas_P1/Vida3_P1,
		]
		for i in range(hearts.size()):
			hearts[i].visible = i < lives
	else:
		var hearts = [
			$MarginContainer/HBoxContainer/Vidas_P2/Vida1_P2,
			$MarginContainer/HBoxContainer/Vidas_P2/Vida2_P2,
			$MarginContainer/HBoxContainer/Vidas_P2/Vida3_P2,
		]
		for i in range(hearts.size()):
			hearts[i].visible = i < lives

func _process(delta: float) -> void:
	update_powerups(active_powerups_p1, powerups_p1, delta)
	update_powerups(active_powerups_p2, powerups_p2, delta)

func update_powerups(active_dict: Dictionary, icons_dict: Dictionary, delta: float):
	for name in active_dict.keys():
		active_dict[name]["time_left"] -= delta
		var data = active_dict[name]
		var icon = icons_dict[name]

		if data["time_left"] <= 0:
			icon.visible = false
			icon.modulate = Color.WHITE
			active_dict.erase(name)
			continue

		var percent_left = data["time_left"] / data["duration"]
		if percent_left <= BLINK_THRESHOLD and not data["blinking"]:
			start_blink(icon)
			data["blinking"] = true
		elif percent_left > BLINK_THRESHOLD and data["blinking"]:
			stop_blink(icon)
			data["blinking"] = false

func start_blink(icon: TextureRect):
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(icon, "modulate:a", 0.2, BLINK_SPEED).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(icon, "modulate:a", 1.0, BLINK_SPEED)
	icon.set_meta("blink_tween", tween)

func stop_blink(icon: TextureRect):
	var tween = icon.get_meta("blink_tween")
	if tween and tween.is_running():
		tween.kill()
	icon.modulate = Color.WHITE

func show_powerup(player_id: int, powerup_name: String, duration: float):
	var icons_dict = powerups_p1 if player_id == 1 else powerups_p2
	var active_dict = active_powerups_p1 if player_id == 1 else active_powerups_p2

	if not icons_dict.has(powerup_name):
		print("⚠️ PowerUp no encontrado: ", powerup_name)
		return

	var icon = icons_dict[powerup_name]
	icon.visible = true
	icon.modulate = Color.WHITE

	if active_dict.has(powerup_name):
		active_dict[powerup_name]["time_left"] = duration
		active_dict[powerup_name]["duration"] = duration
		active_dict[powerup_name]["blinking"] = false
		stop_blink(icon)
	else:
		active_dict[powerup_name] = {
			"duration": duration,
			"time_left": duration,
			"blinking": false
		}

extends Control

@onready var p1_slots = $P1Rounds.get_children()
@onready var p2_slots = $P2Rounds.get_children()

var rounds_p1 := 0
var rounds_p2 := 0
const MAX_ROUNDS := 5

func _ready() -> void:
	# Aseguramos que arranquen invisibles
	for slot in p1_slots:
		slot.visible = false
	for slot in p2_slots:
		slot.visible = false

func add_round_point(player_id: int) -> void:
	if player_id == 1 and rounds_p1 < MAX_ROUNDS:
		p1_slots[rounds_p1].visible = true
		rounds_p1 += 1
	elif player_id == 2 and rounds_p2 < MAX_ROUNDS:
		p2_slots[rounds_p2].visible = true
		rounds_p2 += 1

	# Chequeo si alguien ganó la partida
	if rounds_p1 == MAX_ROUNDS:
		print("Jugador 1 ganó la partida")
	elif rounds_p2 == MAX_ROUNDS:
		print("Jugador 2 ganó la partida")

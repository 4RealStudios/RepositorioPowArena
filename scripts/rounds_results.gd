extends Control

@onready var p1_slots = $P1Rounds.get_children()
@onready var p2_slots = $P2Rounds.get_children()

var rounds_p1 := 0
var rounds_p2 := 0
const MAX_ROUNDS := 10

func _ready() -> void:
	reset_rounds()
	visible = false 

func add_round_point(player_id: int) -> void:
	if player_id == 1 and rounds_p1 < MAX_ROUNDS:
		p1_slots[rounds_p1].visible = true
		rounds_p1 += 1
	elif player_id == 2 and rounds_p2 < MAX_ROUNDS:
		p2_slots[rounds_p2].visible = true
		rounds_p2 += 1

func show_results(winner_id: int) -> void:
	add_round_point(winner_id)

	visible = true
	await get_tree().create_timer(2.0).timeout
	visible = false

func reset_rounds() -> void:
	rounds_p1 = 0
	rounds_p2 = 0
	for slot in p1_slots:
		slot.visible = false
	for slot in p2_slots:
		slot.visible = false
	visible = false

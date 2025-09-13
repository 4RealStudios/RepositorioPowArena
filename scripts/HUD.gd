extends CanvasLayer

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

func update_rounds(p1_rounds: int, p2_rounds: int):
	$HBoxContainer/RoundsLabelP1.text = "Rondas: %d" % p1_rounds
	$HBoxContainer/RoundsLabelP2.text = "Rondas: %d" % p2_rounds

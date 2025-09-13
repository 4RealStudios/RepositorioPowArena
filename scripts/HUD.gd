extends CanvasLayer

func _ready() -> void:
	add_to_group("ui")

func update_lives(player_id: int, lives: int):
	if player_id == 1:
		$Player1Lives.text = "Player 1: " + str(lives)
	else:
		$Player2Lives.text = "Player 2: " + str(lives)

func update_rounds(p1_rounds: int, p2_rounds: int):
	$HBoxContainer/RoundsLabelP1.text = "Rondas: %d" % p1_rounds
	$HBoxContainer/RoundsLabelP2.text = "Rondas: %d" % p2_rounds

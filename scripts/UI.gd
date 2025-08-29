extends CanvasLayer

func _ready() -> void:
	add_to_group("ui")

func update_lives(player_id: int, lives: int):
	if player_id == 1:
		$Player1Lives.text = "Player 1: " + str(lives)
	else:
		$Player2Lives.text = "Player 2: " + str(lives)

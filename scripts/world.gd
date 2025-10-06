extends Node2D

@onready var player1 = $Player1
@onready var player2 = $Player2

func start_game(p1_char: String, p2_char: String):
	player1.character_name = p1_char
	player1.player_id = 1
	player1._ready() # recarga las skins

	player2.character_name = p2_char
	player2.player_id = 2
	player2._ready()

extends Node2D

var player1: Node
var player2: Node

func _ready() -> void:
	add_to_group("game")
	player1 = $Player1
	player2 = $Player2

func player_died(player_id: int):
	if player_id == 1:
		print("Jugador 2 gana!")
	else:
		print("Jugador 1 gana!")
		reset_round()

func reset_round():
	#reinicia las vidas de los jugadores
	player1.lives = 3
	player2.lives = 3
	
	#respawnea a los jugadores en las posiciones iniciales
	player1.global_position = player1.spawn_position
	player2.global_position = player2.spawn_position
	
	#actualiza el UI del juego
	get_tree().call_group("ui", "update_lives", 1, player1.lives)
	get_tree().call_group("ui", "update_lives", 2, player2.lives)

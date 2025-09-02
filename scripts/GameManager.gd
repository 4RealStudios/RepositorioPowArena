extends Node2D

@onready var player1 = $player1
@onready var player2 = $player2
@onready var countdown_label = $CountdownLabel
@onready var countdown_timer = $CountdownTimer

var countdown_value = 3
var is_counting_down := false
var spawn_p1 := Vector2(16, 90)
var spawn_p2 := Vector2(304, 90)
var rounds_p1: int = 0
var rounds_p2: int = 0
var max_rounds_to_win: int = 3

func _ready() -> void:
	add_to_group("game")
	start_round()
	get_tree().call_group("ui", "update_rounds",rounds_p1, rounds_p2)

func player_died(player_id: int):
	if player_id == 1:
		rounds_p2 += 1
	elif player_id == 2:
		rounds_p1 += 1
	get_tree().call_group("ui","update_rounds", rounds_p1, rounds_p2)
	if check_match_winner():
		end_match()
	else:
		start_round()

func check_match_winner() -> bool:
	if rounds_p1 >= max_rounds_to_win and (rounds_p1 - rounds_p2) >= 2:
		return true
	if rounds_p2 >= max_rounds_to_win and (rounds_p2 - rounds_p1) >= 2:
		return true
	return false

func end_match():
	player1.can_move = false
	player2.can_move = false
	countdown_label.visible = true
	if rounds_p1 > rounds_p2:
		countdown_label.text = "Jugador 1 Gana!"
	elif rounds_p2 > rounds_p1:
		countdown_label.text = "Jugador 2 Gana!"
	else:
		countdown_label.text = "Empate!"

func reset_round():
		#reinicia las vidas de los jugadores
	player1.lives = 3
	player2.lives = 3
		#respawnea a los jugadores en las posiciones iniciales
	player1.global_position = spawn_p1
	player2.global_position = spawn_p2
		#actualiza el UI del juego
	get_tree().call_group("ui", "update_lives", 1, player1.lives)
	get_tree().call_group("ui", "update_lives", 2, player2.lives)
	get_tree().call_group("ui", "update_rounds", rounds_p1, rounds_p2)

func start_round():
	if is_counting_down:
		return
	is_counting_down = true
		#evita que los personajes se muevan mientras esta la cuenta atras
	player1.can_move = false
	player2.can_move = false
		#muestra el contador
	countdown_label.visible = true
		#bucle 3,2,1
	for i in range(3,0,-1): #3,2,1
		countdown_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
		#POW!
	countdown_label.text = "POW!"
	await  get_tree().create_timer(0.5).timeout
	countdown_label.visible = false
	reset_round()
	player1.can_move = true
	player2.can_move = true
	is_counting_down = false

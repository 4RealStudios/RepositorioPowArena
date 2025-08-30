extends Node2D

@onready var player1 = $player1
@onready var player2 = $player2
@onready var countdown_label = $CountdownLabel
@onready var countdown_timer = $CountdownTimer

var countdown_value = 3
var spawn_p1 := Vector2(16, 164)
var spawn_p2 := Vector2(304, 16)

func _ready() -> void:
	add_to_group("game")
	start_round()

func start_round():
	player1.can_move = false
	player2.can_move = false
		#inicia el contador
	countdown_value = 3
	countdown_label.text = str(countdown_value)
	countdown_label.visible = true
		#arranca el timer
	countdown_timer.wait_time = 1.0
	countdown_timer.start()

func _on_Countdowntimer_timeout():
	if countdown_value > 1:
		countdown_value -= 1
		countdown_label.text = str(countdown_timer)
	else:
			#ultimo mensaje
		countdown_label.text = "POW!"
			#esperar un poco antes de iniciar la ronda
		await get_tree().create_timer(0.5).timeout
	countdown_label.visible = false
	countdown_timer.stop()
		#se desbloquean los jugadores para que puedan moverse
	player1.can_move = true
	player2.can_move = true
	reset_round()

func player_died(_player_id: int):
	reset_round()

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

extends Node2D

@export var easy_maps: Array[PackedScene]
@export var midium_maps: Array[PackedScene]
@export var hard_maps: Array[PackedScene]

var current_map: Node = null

@onready var player1 = $player1
@onready var player2 = $player2
@onready var countdown_label = $CountdownLabel

var is_counting_down := false
var rounds_p1: int = 0
var rounds_p2: int = 0
var max_rounds_to_win: int = 5
var countdown_value = 3

func _ready() -> void:
	randomize()
	add_to_group("game")
	get_tree().call_group("ui", "update_rounds",rounds_p1, rounds_p2)
	start_round()

func player_died(player_id: int) -> void:
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

func end_match() -> void:
	_safe_set_can_move(player1, false)
	_safe_set_can_move(player2, false)
	
	countdown_label.visible = true
	if rounds_p1 > rounds_p2:
		countdown_label.text = "Jugador 1 Gana!"
	elif rounds_p2 > rounds_p1:
		countdown_label.text = "Jugador 2 Gana!"
	else:
		countdown_label.text = "Empate!"
	
	await  get_tree().create_timer(2.0).timeout
	
	rounds_p1 = 0
	rounds_p2 = 0
	get_tree().call_group("ui", "update_rounds", rounds_p1, rounds_p2)
	start_round()

func load_map(round_number: int) -> void:
	if current_map and is_instance_valid(current_map):
		current_map.queue_free()
		current_map = null
		
	var pool: Array[PackedScene] = []
	if round_number < 3:
		pool = easy_maps
	elif round_number < 6:
		pool = midium_maps
	else:
		pool = hard_maps
	if  pool.is_empty():
		push_warning("Pool de mapas vacio para la ronda %d" % round_number)
		return
	var scene := pool[randi() % pool.size()]
	current_map = scene.instantiate()
	add_child(current_map)
	current_map.z_index = -1

func reset_round():
		#reinicia las vidas de los jugadores
	player1.lives = 3
	player2.lives = 3
	
	if player1.has_method("reset_for_round"):
		player1.reset_for_round()
	if player2.has_method("reset_for_round"):
		player2.reset_for_round()
		
	var spawn_p1 = current_map.get_node("SpawnP1")
	var spawn_p2 = current_map.get_node("SpawnP2")
	
	if spawn_p1:
		player1.global_position = spawn_p1.global_position
	else:
		push_warning("SpawnP1 no encontrado en el mapa actual")
	if spawn_p2:
		player2.global_position = spawn_p2.global_position
	else:
		push_warning("SpawnP2 no encontrado en el mapa actual")

	get_tree().call_group("ui", "update_lives", 1, player1.lives)
	get_tree().call_group("ui", "update_lives", 2, player2.lives)
	get_tree().call_group("ui", "update_rounds", rounds_p1, rounds_p2)

func start_round():
	if is_counting_down:
		return
	is_counting_down = true
	
	_safe_set_can_move(player1, false)
	_safe_set_can_move(player2, false)

	countdown_label.visible = true
		#bucle 3,2,1
	for i in range(3,0,-1): #3,2,1
		countdown_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
		#POW!
	countdown_label.text = "POW!"
	await  get_tree().create_timer(0.5).timeout
	countdown_label.visible = false
	
	load_map(rounds_p1 + rounds_p2)
	reset_round()
	
	_safe_set_can_move(player1, true)
	_safe_set_can_move(player2, true)
	is_counting_down = false

func _safe_set_can_move(player: Node,enable: bool) -> void:
	if player and player.has_method("set_can_move"):
		player.set_can_move(enable)

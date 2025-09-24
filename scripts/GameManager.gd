extends Node2D


@export var PowerUpScene: PackedScene
@export var easy_maps: Array[PackedScene]
@export var midium_maps: Array[PackedScene]
@export var hard_maps: Array[PackedScene]

var current_map: Node = null
const PowerUp = preload("res://scripts/power_up.gd")

@onready var player1 = $player1
@onready var player2 = $player2
@onready var countdown_label = $CountdownLabel
@onready var control_screen = $ControlScreen
@onready var control_timer = $ControlScreen/Timer
@onready var hud = $HUD
@onready var players = [player1, player2]
@onready var powerup_timer: Timer = Timer.new()

var is_counting_down := false
var rounds_p1: int = 0
var rounds_p2: int = 0
var max_rounds_to_win: int = 5
var countdown_value = 3

func _ready() -> void:
	randomize()
	add_to_group("game")
	get_tree().call_group("ui", "update_rounds",rounds_p1, rounds_p2)
	
	control_screen.visible = true
	hud.visible = false
	for player in players:
		player.visible = false
	control_timer.start()
	
	powerup_timer.wait_time = 8.0
	powerup_timer.one_shot = false
	powerup_timer.autostart = true
	add_child(powerup_timer)
	powerup_timer.timeout.connect(spawn_powerup)
	
	start_round()

func player_died(winner_id: int) -> void:
	if winner_id == 1:
		rounds_p1 += 1
	elif winner_id == 2:
		rounds_p2 += 1

	# Avisar al HUD que muestre el contador de rondas
	get_tree().call_group("rounds_ui", "show_results", winner_id)

	# (si todavía usás las labels viejas de UI)
	get_tree().call_group("ui", "update_rounds", rounds_p1, rounds_p2)

	if check_match_winner():
		end_match()
	else:
		start_round()

func check_match_winner() -> bool:
	if rounds_p1 == max_rounds_to_win:
		return true
	if rounds_p2 == max_rounds_to_win:
		return true
	return false

func end_match() -> void:
	_safe_set_can_move(player1, false)
	_safe_set_can_move(player2, false)
	
	countdown_label.visible = true
	if rounds_p1 > rounds_p2:
		countdown_label.text = "Jugador 2 Gana!"
	elif rounds_p2 > rounds_p1:
		countdown_label.text = "Jugador 1 Gana!"
	
	await  get_tree().create_timer(2.0).timeout
	
	rounds_p1 = 0
	rounds_p2 = 0
	get_tree().call_group("ui", "update_rounds", rounds_p1, rounds_p2)
	get_tree().call_group("rounds_ui", "reset_rounds")
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
	_safe_set_can_shoot(player1, false)
	_safe_set_can_shoot(player2, false)

	countdown_label.visible = true

	for i in range(3,0,-1): 
		countdown_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
	countdown_label.text = "POW!"
	await  get_tree().create_timer(0.5).timeout
	countdown_label.visible = false
	
	load_map(rounds_p1 + rounds_p2)
	await get_tree().process_frame
	reset_round()
	
	hud.visible = true
	for player in players:
		player.visible = true
	
	_safe_set_can_move(player1, true)
	_safe_set_can_move(player2, true)
	_safe_set_can_shoot(player1, true)
	_safe_set_can_shoot(player2, true)
	is_counting_down = false

func spawn_powerup():
	var p = PowerUpScene.instantiate()
	p.type = randi() % PowerUp.PowerUpType.size()
	p.connect("picked_up", Callable(self, "_on_powerup_picked"))
	add_child(p)
	p.global_position = get_random_spawn_position()

func _on_powerup_picked(player, type):
	match type:
		PowerUp.PowerUpType.BOUNCE:
			player.extra_bounces += 2

func get_random_spawn_position() -> Vector2:
	var spawn_area = Rect2(Vector2(16, 16), Vector2(320 - 32, 180))
	var pos: Vector2
	var tries := 0
	while tries < 50:  # límite de intentos
		pos = Vector2(
			randf_range(spawn_area.position.x, spawn_area.end.x),
			randf_range(spawn_area.position.y, spawn_area.end.y)
		)
		if not is_in_wall(pos):
			return pos
		tries += 1
	return spawn_area.get_center()

func is_in_wall(pos: Vector2) -> bool:
	var space = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var result = space.intersect_point(params, 1)
	return result.size() > 0

func _safe_set_can_move(player: Node,enable: bool) -> void:
	if player and player.has_method("set_can_move"):
		player.set_can_move(enable)

func _safe_set_can_shoot(player: Node, enable: bool) -> void:
	if player and player.has_method("set_can_shoot"):
		player.set_can_shoot(enable)

func _on_timer_timeout() -> void:
	control_screen.visible = false
	start_round()

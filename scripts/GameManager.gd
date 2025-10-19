extends Node2D

@export var PowerUpScene: PackedScene
@export var easy_maps: Array[PackedScene]
@export var midium_maps: Array[PackedScene]
@export var hard_maps: Array[PackedScene]
@export var countdown_atlas = preload("res://assets/HUD/321 pow.png")

var countdown_regions = {
	3: Rect2(0, 0, 42, 56),
	2: Rect2(44, 0, 51, 56),
	1: Rect2(97, 0, 45, 56),
	"pow": Rect2(144, 0, 90, 57)
}

var current_map: Node = null
const PowerUp = preload("res://scripts/power_up.gd")

@onready var player1 = $player1
@onready var player2 = $player2
@onready var countdown_sprite = $CountdownSprite
@onready var control_screen = $ControlScreen
@onready var control_timer = $ControlScreen/Timer
@onready var hud = $HUD
@onready var players = [player1, player2]
@onready var powerup_timer: Timer = Timer.new()
@onready var white_flash = $CanvasLayer/WhiteFlash

var is_counting_down := false
var rounds_p1: int = 0
var rounds_p2: int = 0
var max_rounds_to_win: int = 1
var countdown_value = 3
var match_over: bool = false
var last_scene: PackedScene = null

const GAMEOVER_SCENE := "res://scenes/GameOverMenu.tscn"

func _ready() -> void:
	randomize()
	add_to_group("game")
	apply_selected_skins()
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

func apply_selected_skins() -> void:
	var p1_base = Global.player1_choice
	var p2_base = Global.player2_choice
	if p1_base == "" and p2_base == "":
		return
	var frames1: SpriteFrames = null
	var frames2: SpriteFrames = null
	# --- PLAYER 1 ---
	if p1_base != "":
		var variant1 = "alt" if Global.player1_alt else "main"
		frames1 = load_skin_frames(p1_base, variant1)
	# --- PLAYER 2 ---
	if p2_base != "":
		var variant2 = "alt" if Global.player2_alt else "main"
		frames2 = load_skin_frames(p2_base, variant2)

	if frames1 and player1.has_node("AnimatedSprite2DP1"):
		player1.get_node("AnimatedSprite2DP1").sprite_frames = frames1
	elif not frames1:
		push_warning("No se pudo cargar spriteframes para Player1")
		
	if frames2 and player2.has_node("AnimatedSprite2DP2"):
		player2.get_node("AnimatedSprite2DP2").sprite_frames = frames2
	elif not frames2:
		push_warning("No se pudo cargar spriteframes para Player2")

func load_skin_frames(base_name: String, variant: String = "main") -> SpriteFrames:
	var path := ""
	if variant == "main":
		path = Global.SKINS_FOLDER + "%s.tres" % base_name
	else:
		path = Global.SKINS_FOLDER + "%s_alt.tres" % base_name
	
	var res = ResourceLoader.load(path)
	if res and res is SpriteFrames:
		return res
	if variant == "alt":
		var fallback = ResourceLoader.load(Global.SKINS_FOLDER + "%s.tres" % base_name)
		if fallback and fallback is SpriteFrames:
			return fallback
	return null

func player_died(winner_id: int) -> void:
	if match_over:
		return
	if winner_id == 1:
		rounds_p1 += 1
	elif winner_id == 2:
		rounds_p2 += 1
	get_tree().call_group("rounds_ui", "show_results", winner_id)
	get_tree().call_group("ui", "update_rounds", rounds_p1, rounds_p2)
	
	freeze_game()
	clear_projectiles()
	
	if check_match_winner():
		end_match()
	else:
		await get_tree().create_timer(2.5).timeout
		unfreeze_game()
		start_round()

func on_player_died(dead_id: int) -> void:
	if match_over:
		return
	var winner_id = 1 if dead_id == 2 else 2
	player_died(winner_id)

func clear_projectiles():
	for b in get_tree().get_nodes_in_group("balas"):
		if is_instance_valid(b):
			b.queue_free()

func check_match_winner() -> bool:
	if rounds_p1 == max_rounds_to_win:
		return true
	if rounds_p2 == max_rounds_to_win:
		return true
	return false

func end_match() -> void:
	match_over = true
	_safe_set_can_move(player1, false)
	_safe_set_can_move(player2, false)
	_safe_set_can_shoot(player1, false)
	_safe_set_can_shoot(player2, false)
	
	clear_projectiles()
	
	var winner := 1 if rounds_p1 > rounds_p2 else 2
	
	trigger_victory_transition(winner)

func trigger_victory_transition(winner: int) -> void:
	# 🔹 Cámara lenta breve
	var slow_tween = create_tween()
	slow_tween.tween_property(Engine, "time_scale", 0.2, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 🔹 Fade in (blanco aparece)
	white_flash.visible = true
	white_flash.modulate = Color(1, 1, 1, 0.0)

	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(white_flash, "modulate:a", 0.8, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_in_tween.finished

	# 🔹 Restaura tiempo normal
	var restore_tween = create_tween()
	restore_tween.tween_property(Engine, "time_scale", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# 🔹 🔥 Mostramos la pantalla de ganador *mientras sigue todo blanco*
	show_gameover(winner)

	# 🔹 Fade out (el blanco desaparece dejando ver la pantalla de ganador)
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(white_flash, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_out_tween.finished

	white_flash.visible = false

func show_gameover(winner: int) -> void:
	white_flash.visible = false
	white_flash.modulate.a = 0.0
	
	print("Ganador en GameManager: ", winner)
	if hud:
		hud.visible = false
	if countdown_sprite:
		countdown_sprite.visible = false
	
	var scene_res = ResourceLoader.load(GAMEOVER_SCENE)
	if scene_res == null:
		push_error("No se encontro " + GAMEOVER_SCENE)
		return
		
	var menu = scene_res.instantiate()
	add_child(menu)
	
	if menu.has_method("setup"):
		menu.setup(winner)

func restart_match() -> void:
	match_over = false
	rounds_p1 = 0
	rounds_p2 = 0
	get_tree().call_group("ui", "update_rounds", rounds_p1, rounds_p2)
	get_tree().call_group("rounds_ui", "reset_rounds")
	apply_selected_skins()
	start_round()

func load_map(round_number: int) -> void:
	if current_map and is_instance_valid(current_map):
		current_map.queue_free()
		current_map = null
	var pool: Array[PackedScene] = []
	if round_number < 2:
		pool = easy_maps
	elif round_number < 4:
		pool = midium_maps
	else:
		pool = hard_maps
	if  pool.is_empty():
		push_warning("Pool de mapas vacio para la ronda %d" % round_number)
		return
	var scene: PackedScene = null
	if pool.size() == 1:
		scene = pool[0]
	else:
		while true:
			var candidate = pool[randi() % pool.size()]
			if candidate != last_scene:
				scene = candidate
				break
				
	last_scene = scene
	current_map = scene.instantiate()
	add_child(current_map)
	current_map.z_index = -1

func reset_round():
	player1.lives = 3
	player2.lives = 3
	for PowerUp in get_tree().get_nodes_in_group("powerups"):
		PowerUp.queue_free()
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
	if match_over:
		return
	
	get_tree().paused = false
	
	if is_counting_down:
		return
	is_counting_down = true
	_safe_set_can_move(player1, false)
	_safe_set_can_move(player2, false)
	_safe_set_can_shoot(player1, false)
	_safe_set_can_shoot(player2, false)
	
	countdown_sprite.visible = true

	for i in range(3, 0, -1):
		var tex := AtlasTexture.new()
		tex.atlas = countdown_atlas
		tex.region = countdown_regions[i]
		countdown_sprite.texture = tex
		await get_tree().create_timer(1.0).timeout

	# POW!
	var tex_pow := AtlasTexture.new()
	tex_pow.atlas = countdown_atlas
	tex_pow.region = countdown_regions["pow"]
	countdown_sprite.texture = tex_pow
	await get_tree().create_timer(0.5).timeout

	countdown_sprite.visible = false
	
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
	if match_over or not PowerUpScene:
		return
	var p = PowerUpScene.instantiate()
	p.type = randi() % PowerUp.PowerUpType.size()
	p.connect("picked_up", Callable(self, "_on_powerup_picked"))
	add_child(p)
	p.global_position = get_random_spawn_position()
	p.add_to_group("powerups")

func _on_powerup_picked(player, type):
	match type:
		PowerUp.PowerUpType.BOUNCE:
			player.extra_bounces = 2
			await get_tree().create_timer(8.0).timeout
			player.extra_bounces = 0
		PowerUp.PowerUpType.SPEED:
			player.speed *= 1.5
			await get_tree().create_timer(8.0).timeout
			player.speed /= 1.5
		PowerUp.PowerUpType.HEAL:
			player.lives = min(player.lives + 1, 3)
			get_tree().call_group("ui", "update_lives", player.player_id, player.lives)
		PowerUp.PowerUpType.SHIELD:
			if player.has_method("activate_shield"):
				player.activate_shield()

func get_random_spawn_position() -> Vector2:
	var spawn_area = Rect2(Vector2(16, 16), Vector2(320 - 32, 180))
	var pos: Vector2
	var tries := 0
	while tries < 50:
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

func freeze_game() -> void:
	for player in players:
		_safe_set_can_move(player, false)
		_safe_set_can_shoot(player, false)
	
	if powerup_timer:
		powerup_timer.stop()
	
	for bullet in get_tree().get_nodes_in_group("balas"):
		if bullet.has_method("set_process"):
			bullet.set_process(false)
		if bullet.has_method("set_physics_process"):
			bullet.set_physics_process(false)
			
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	countdown_sprite.process_mode = Node.PROCESS_MODE_ALWAYS

func unfreeze_game() -> void:
	for player in players:
		_safe_set_can_move(player, true)
		_safe_set_can_shoot(player, true)

	if powerup_timer and not powerup_timer.is_stopped():
		powerup_timer.start()
	
	for bullet in get_tree().get_nodes_in_group("balas"):
		if bullet.has_method("set_process"):
			bullet.set_process(true)
		if bullet.has_method("set_physics_process"):
			bullet.set_physics_process(true)

func _on_timer_timeout() -> void:
	if match_over:
		return
	control_screen.visible = false
	start_round()

func on_player_hit(player: Node) -> void:
	var cam = get_tree().get_first_node_in_group("camara")
	if cam and cam.has_method("shake"):
		cam.shake(3.0)
	get_tree().call_group("ui", "flash_hit", player.get("player_id"))

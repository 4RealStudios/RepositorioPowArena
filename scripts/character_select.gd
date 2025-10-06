extends Node2D

const GAME_SCENE_PATH := "res://scenes/world.tscn"

@export var PREVIEWS_PATH: String = "res://assets/players/skins/previews/"

@onready var background = $Background
@onready var player1preview = $preview_player1
@onready var player2preview = $preview_player2
@onready var grid_p1 = $GridContainerP1
@onready var grid_p2 = $GridContainerP2
@onready var p1_cursor = $CursorP1
@onready var p2_cursor = $CursorP2

var p1_index: int = 0
var p2_index: int = 0
var p1_locked: bool = false
var p2_locked: bool = false
var p1_icons: Array = []
var p2_icons: Array = []

func _ready():
	p1_icons = grid_p1.get_children()
	p2_icons = grid_p2.get_children()
	
	if p1_icons.size() == 0:
		push_warning("GridContainer1 no tiene hijos. Agregar Icon_...(sprite2d).")
	if p2_icons.size() == 0:
		push_warning("GridContainer2 no tiene hijos. Agregar Icon_...(sprite2d).")
	
	player1preview.modulate = Color(1,1,1,0.45)
	player2preview.modulate = Color(1,1,1,0.45)
	
	_update_cursors()
	_update_previews()

func _process(_delta: float) -> void:
	if not p1_locked:
		_handle_input_player(1)
	if not p2_locked:
		_handle_input_player(2)

func _handle_input_player(player:int) -> void:
	if player == 1:
		if Input.is_action_just_pressed("p1_left"):
			_move_index(player, -1)
		elif Input.is_action_just_pressed("p1_right"):
			_move_index(player, 1)
		elif Input.is_action_just_pressed("p1_up"):
			_move_index(player, -1)
		elif Input.is_action_just_pressed("p1_down"):
			_move_index(player, 1)
		elif Input.is_action_just_pressed("p1_accept"):
			_lock_player(player)
	else:
		if Input.is_action_just_pressed("p2_left"):
			_move_index(player, -1)
		elif Input.is_action_just_pressed("p2_right"):
			_move_index(player, 1)
		elif Input.is_action_just_pressed("p2_up"):
			_move_index(player, -1)
		elif Input.is_action_just_pressed("p2_down"):
			_move_index(player, 1)
		elif Input.is_action_just_pressed("p2_accept"):
			_lock_player(player)

func _move_index(player:int, delta:int) -> void:
	if player == 1:
		p1_index = clamp(p1_index + delta, 0, max(0, p1_icons.size() - 1))
	else:
		p2_index = clamp(p2_index + delta, 0, max(0, p2_icons.size() - 1))

	_update_cursors()
	_update_previews()

func _lock_player(player:int) -> void:
	if player == 1:
		p1_locked = true
		player1preview.modulate = Color(1,1,1,1)
	else:
		p2_locked = true
		player2preview.modulate = Color(1,1,1,1)

	# si ambos lockeados, arrancar
	if p1_locked and p2_locked:
		# pequeña pausa visual
		await get_tree().create_timer(0.25).timeout
		_finalize_and_start()

func _finalize_and_start() -> void:
	var name1 = _icon_base_name(p1_icons[p1_index])
	var name2 = _icon_base_name(p2_icons[p2_index])

	# Si ambos eligen el mismo personaje, el Player2 usará el alt (si existe)
	var p2_alt_used: bool = false
	if name1 == name2:
		var alt_path := PREVIEWS_PATH + "%s_preview_alt.png" % name2
		if ResourceLoader.exists(alt_path):
			p2_alt_used = true

	# Guardamos las elecciones globales
	Global.player1_choice = name1
	Global.player2_choice = name2
	Global.player1_alt = false
	Global.player2_alt = p2_alt_used

	# Mostrar previews distintos si ambos eligen el mismo personaje
	var p1_preview_path = PREVIEWS_PATH + "%s_preview.png" % name1
	var p2_preview_path = PREVIEWS_PATH + "%s_preview.png" % name2
	var p2_preview_alt_path = PREVIEWS_PATH + "%s_preview_alt.png" % name2

	if name1 == name2 and p2_alt_used:
		player2preview.texture = load(p2_preview_alt_path)
	else:
		player2preview.texture = load(p2_preview_path)

	player1preview.texture = load(p1_preview_path)

	# Pequeña pausa visual y cambio de escena
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _update_cursors() -> void:
	if p1_icons.size() > 0:
		p1_cursor.global_position = p1_icons[p1_index].global_position
	if p2_icons.size() > 0:
		p2_cursor.global_position = p2_icons[p2_index].global_position
	
	p1_cursor.visible = not p1_locked
	p2_cursor.visible = not p2_locked

func _update_previews() -> void:
	var name_p1 = ""
	var name_p2 = ""
	if p1_icons.size() > 0:
		name_p1 = _icon_base_name(p1_icons[p1_index])
	if p2_icons.size() > 0:
		name_p2 = _icon_base_name(p2_icons[p2_index])
		
	# Paths de previews
	var p1_preview_path = PREVIEWS_PATH + "%s_preview.png" % name_p1
	var p2_preview_path = PREVIEWS_PATH + "%s_preview.png" % name_p2
	var p2_alt_path = PREVIEWS_PATH + "%s_preview_alt.png" % name_p2

	# --- Player 1 ---
	if ResourceLoader.exists(p1_preview_path):
		player1preview.texture = load(p1_preview_path)
	elif "texture" in p1_icons[p1_index]:
		player1preview.texture = p1_icons[p1_index].texture

	# --- Player 2 ---
	# Si ambos están sobre el mismo personaje y existe alt, mostrar alt (aunque no estén lockeados)
	if name_p1 == name_p2 and ResourceLoader.exists(p2_alt_path):
		player2preview.texture = load(p2_alt_path)
	elif ResourceLoader.exists(p2_preview_path):
		player2preview.texture = load(p2_preview_path)
	elif "texture" in p2_icons[p2_index]:
		player2preview.texture = p2_icons[p2_index].texture

	# Opacidad visual
	player1preview.modulate = Color(1, 1, 1, 1 if p1_locked else 0.45)
	player2preview.modulate = Color(1, 1, 1, 1 if p2_locked else 0.45)


func _icon_base_name(icon_node: Node) -> String:
	var raw_name = icon_node.name
	# soporta "Icon_robot" o "robot" -> intenta recortar "Icon_"
	if raw_name.begins_with("Icon_"):
		return raw_name.substr(5) # corta "Icon_"
	return raw_name

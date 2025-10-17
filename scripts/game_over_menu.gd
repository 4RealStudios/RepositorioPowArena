extends Node2D

@onready var background = $Background
@onready var winner_preview = $WinnerPreview
@onready var winner_text = $WinnerText
@onready var rematch_button = $RematchButton
@onready var change_characters_button = $ChangeCharacterButton
@onready var mainmenu_button = $MainMenuButton
@onready var input_timer := Timer.new()

@export var atlas_botones_p1: Texture2D
@export var atlas_botones_p2: Texture2D

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const CHARACTER_SELECT_SCENE := "res://scenes/CharacterSelect.tscn"

var selected_index := 0
var input_enabled := false
var buttons := []

var regiones_botones := {
	"rematch": Rect2(0, 0, 47, 12),
	"change": Rect2(0, 14, 100, 12),
	"menu": Rect2(0, 28, 64, 12)
}

func _ready() -> void:
	buttons = [rematch_button, change_characters_button, mainmenu_button]
	_update_button_focus()

func setup(winner: int) -> void:
	if winner == 1:
		winner_text.texture = load("res://assets/HUD/victoriap1.png")
		background.texture = load("res://assets/players/skins/backgrounds/p1winfondo.png")
	else:
		winner_text.texture = load("res://assets/HUD/victoriap2.png")
		background.texture = load("res://assets/players/skins/backgrounds/p2winfondo.png")
		
	var winner_name := ""
	var alt_variant := false
	if winner == 1:
		winner_name = Global.player1_choice
		alt_variant = Global.player1_alt
	else:
		winner_name = Global.player2_choice
		alt_variant = Global.player2_alt
	
	var suffix := "_preview_alt" if alt_variant else "_preview"
	var preview_path := "res://assets/players/skins/preview_wins/%s%s.png" % [winner_name, suffix]
	
	if ResourceLoader.exists(preview_path):
		winner_preview.texture = load(preview_path)
		print("Ruta preview:", preview_path)
	else:
		push_warning("no se encontro prewviews")
	
	if winner == 1:
		winner_preview.flip_h = false
		winner_preview.position = Vector2(160, 90)
		winner_text.position = Vector2(240, 50)
	else:
		winner_preview.flip_h = true
		winner_preview.position = Vector2(160, 90)
		winner_text.position = Vector2(80, 50)
		
	_aplicar_atlas_botones(winner)
	_show_with_animation()
	_agregar_timer_input()
	
	print("Preview cargado:", winner_preview.texture != null)
	winner_preview.visible = true
	winner_preview.modulate = Color(1, 1, 1, 1)
	winner_preview.scale = Vector2(1, 1)

func _agregar_timer_input() -> void:
	input_timer.wait_time = 2.5 
	input_timer.one_shot = true
	add_child(input_timer)
	input_timer.start()
	await input_timer.timeout
	input_enabled = true

func _aplicar_atlas_botones(winner: int) -> void:
	var atlas_actual: Texture2D = atlas_botones_p1 if winner == 1 else atlas_botones_p2
	
	var rematch_tex := AtlasTexture.new()
	rematch_tex.atlas = atlas_actual
	rematch_tex.region = regiones_botones["rematch"]
	rematch_button.texture = rematch_tex
	
	var change_tex := AtlasTexture.new()
	change_tex.atlas = atlas_actual
	change_tex.region = regiones_botones["change"]
	change_characters_button.texture = change_tex
	
	var menu_tex := AtlasTexture.new()
	menu_tex.atlas = atlas_actual
	menu_tex.region = regiones_botones["menu"]
	mainmenu_button.texture = menu_tex
	
	if winner == 1:
		rematch_button.position = Vector2(240, 100)
		change_characters_button.position = Vector2(240, 115)
		mainmenu_button.position = Vector2(240, 130)
	else:
		rematch_button.position = Vector2(80, 100)
		change_characters_button.position = Vector2(80, 115)
		mainmenu_button.position = Vector2(80, 130)

func _show_with_animation():
	winner_preview.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(winner_preview, "modulate.a", 1.0, 0.5)
	tween.tween_property(winner_preview, "scale", Vector2(1.05, 1.05), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	
	if event.is_action_pressed("p1_down") or event.is_action_pressed("p2_down"):
		selected_index = (selected_index + 1) % buttons.size()
		_update_button_focus()
	elif event.is_action_pressed("p1_up") or event.is_action_pressed("p2_up"):
		selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
		_update_button_focus()
	elif event.is_action_pressed("p1_accept") or event.is_action_pressed("p2_accept"):
		_on_button_pressed(buttons[selected_index])

func _update_button_focus():
	for i in range(buttons.size()):
		if buttons[i] != null:
			buttons[i].modulate = Color(1, 1, 1, 0.5)
		else:
			push_warning("Uno de los botones es null(indice: %)" % i)
	if buttons[selected_index] != null:
		buttons[selected_index].modulate = Color(1, 1, 1, 1)

func _on_button_pressed(button: Sprite2D):
	match button:
		rematch_button:
			var gm = get_parent()
			if gm and gm.has_method("restart_match"):
				queue_free()
				gm.restart_match()
			else:
				get_tree().reload_current_scene()
		change_characters_button:
			get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
		mainmenu_button:
			get_tree().change_scene_to_file(MAIN_MENU_SCENE)

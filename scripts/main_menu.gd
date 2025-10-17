extends Node2D

const CHARACTER_SELECT_SCENE := "res://scenes/CharacterSelect.tscn"

@onready var jugar_button = $BotonJugar
@onready var salir_button = $BotonSalir
@onready var controles_button = $BotonControles
@onready var controles_panel = $ControlesPanel

@export var atlas_botones: Texture2D

var selected_index := 0
var buttons := []

var regiones_botones := {
	"controles": Rect2(0, 0, 98, 18),
	"jugar": Rect2(0, 20, 60, 18),
	"salir": Rect2(0, 40, 52, 18)
}

func _ready() -> void:
	buttons = [controles_button, jugar_button, salir_button]
	_aplicar_atlas_botones()
	_update_button_focus()

func _aplicar_atlas_botones() -> void:
	var controles_tex := AtlasTexture.new()
	controles_tex.atlas = atlas_botones
	controles_tex.region = regiones_botones["controles"]
	controles_button.texture = controles_tex

	
	var jugar_tex := AtlasTexture.new()
	jugar_tex.atlas = atlas_botones
	jugar_tex.region = regiones_botones["jugar"]
	jugar_button.texture = jugar_tex

	var salir_tex := AtlasTexture.new()
	salir_tex.atlas = atlas_botones
	salir_tex.region = regiones_botones["salir"]
	salir_button.texture = salir_tex

	# posiciones pensadas para 320x180
	controles_button.position = Vector2(160, 120)
	jugar_button.position = Vector2(160, 140)
	salir_button.position = Vector2(160, 160)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_down") or event.is_action_pressed("p2_down"):
		selected_index = (selected_index + 1) % buttons.size()
		_update_button_focus()
	elif event.is_action_pressed("p1_up") or event.is_action_pressed("p2_up"):
		selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
		_update_button_focus()
	elif event.is_action_pressed("p1_accept") or event.is_action_pressed("p2_accept"):
		_on_button_pressed(buttons[selected_index])
	elif event.is_action_pressed("p1_cancel") or event.is_action_pressed("p2_cancel"):
		if controles_panel.visible:
			_toggle_controles_panel()
		else:
			get_tree().quit()

func _update_button_focus() -> void:
	for i in range(buttons.size()):
		if buttons[i] != null:
			buttons[i].modulate = Color(1, 1, 1, 0.5)
	if buttons[selected_index] != null:
		buttons[selected_index].modulate = Color(1, 1, 1, 1)

func _toggle_controles_panel() -> void:
	if controles_panel.visible:
		controles_panel.visible = false
	else:
		controles_panel.visible = true

func _on_button_pressed(button: Sprite2D) -> void:
	match button:
		jugar_button:
			get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
		salir_button:
			get_tree().quit()
		controles_button:
			_toggle_controles_panel()

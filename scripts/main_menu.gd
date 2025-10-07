extends Control

const CHARACTER_SELECT_SCENE := "res://scenes/CharacterSelect.tscn"

@onready var play_button = $VBoxContainer/JUGAR
@onready var quit_button = $VBoxContainer/SALIR

func _ready() -> void:
	# Conectamos las señales de los botones
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Le damos el foco inicial al primer botón
	play_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_accept") or event.is_action_pressed("p2_accept"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused and focused is Button:
			focused.emit_signal("pressed")
	elif event.is_action_pressed("p2_cancel") or event.is_action_pressed("p1_cancel"):
		get_tree().quit()
	
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

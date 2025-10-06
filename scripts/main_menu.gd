extends Control

const CHARACTER_SELECT_SCENE := "res://scenes/CharacterSelect.tscn"

@onready var play_button = $VBoxContainer/JUGAR
@onready var quit_button = $VBoxContainer/SALIR

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

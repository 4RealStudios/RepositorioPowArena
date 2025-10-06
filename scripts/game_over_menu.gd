extends Control

@onready var winner_label = $VBoxContainer/WinnerLabel
@onready var rematch_button = $VBoxContainer/RematchButton
@onready var mainmenu_button = $VBoxContainer/MainMenuButton

const  MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

func _ready() -> void:
	rematch_button.pressed.connect(_on_rematch_pressed)
	mainmenu_button.pressed.connect(_on_mainmenu_pressed)

func setup(winner:int) -> void:
	winner_label.text = "Jugador %d ganó" % winner

func _on_rematch_pressed():
	var gm = get_parent()
	if gm and gm.has_method("restart_match"):
		queue_free()
		gm.restart_match()
	else:
		get_tree().change_scene_to_file(get_tree().current_scene.filname)

func _on_mainmenu_pressed():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

extends Control

@onready var winner_label = $VBoxContainer/WinnerLabel
@onready var rematch_button = $VBoxContainer/RematchButton
@onready var mainmenu_button = $VBoxContainer/MainMenuButton

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

func _ready() -> void:
	rematch_button.pressed.connect(_on_rematch_pressed)
	mainmenu_button.pressed.connect(_on_mainmenu_pressed)

	rematch_button.grab_focus()

func setup(winner:int) -> void:
	winner_label.text = "Jugador %d ganó" % winner

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_accept") or event.is_action_pressed("p2_accept"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused and focused is Button:
			focused.emit_signal("pressed")
	elif event.is_action_pressed("p1_cancel") or event.is_action_pressed("p2_cancel"):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_rematch_pressed():
	var gm = get_parent()
	if gm and gm.has_method("restart_match"):
		queue_free()
		gm.restart_match()
	else:
		get_tree().reload_current_scene()

func _on_mainmenu_pressed():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

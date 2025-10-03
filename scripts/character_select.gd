extends Control

var player1_skin: String = ""
var player2_skin: String = ""

@onready var confirm_button = $Seleccionar
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)

func select_skin(player: int, skin: String):
	if player == 1:
		player1_skin = skin
	elif player == 2:
		player2_skin = skin

func _on_confirm_pressed():
	if player1_skin == "" or player2_skin == "":
		print("Ambos jugadores deben elegir una skin")
		return
	Global.player1_skin = player1_skin
	Global.player2_skin = player2_skin
	
	if player1_skin == player2_skin:
		Global.player2_skin = player2_skin + "_alt"
	get_tree().change_scene_to_file("res://scenes/world.tscn")

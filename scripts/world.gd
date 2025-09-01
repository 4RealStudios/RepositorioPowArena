extends Node2D

func _ready():
	$VBoxContainer/Jugar.connect("pressed", Callable(self, "_on_jugar_pressed"))
	$VBoxContainer/Salir.connect("pressed", Callable(self, "_on_salir_pressed"))

func _on_jugar_pressed():
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_salir_pressed():
	get_tree().quit()

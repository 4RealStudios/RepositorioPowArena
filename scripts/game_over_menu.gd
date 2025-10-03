extends Control


func _on_revancha_pressed():
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

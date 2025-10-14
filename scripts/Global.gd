extends Node

var player1_choice: String = ""
var player2_choice: String = ""
var player1_alt: bool = false
var player2_alt: bool = false

const SKINS_FOLDER := "res://assets/players/skins/"

var bullet_atlas: Texture2D = preload("res://assets/players/balas.png")
var bullet_regions := {
	"robot": {
		"main": Rect2(0, 0, 4, 4),
		"alt": Rect2(5, 0, 4, 4)
	},
	"mago": {
		"main": Rect2(10, 0, 4, 4),
		"alt": Rect2(15, 0, 4, 4)
	},
	"panda": {
		"main": Rect2(20, 0, 4, 4),
		"alt": Rect2(25, 0, 4, 4)
	},
	"hunter": {
		"main": Rect2(48, 0, 4, 4),
		"alt": Rect2(53, 0, 4, 4)
	}
}

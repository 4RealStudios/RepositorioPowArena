extends Node

var player1_choice: String = ""
var player2_choice: String = ""
var player1_alt: bool = false
var player2_alt: bool = false

const SKINS_FOLDER := "res://assets/players/skins/"
const BULLET_ATLAS := preload("res://assets/players/balas.png")

const BULLET_SPRITES := {
	"robot": {
		"default": Rect2(0, 0, 10, 10),
		"alternate": Rect2(10, 0, 10, 10)
	},
	"mago": {
		"default": Rect2(0, 10, 10, 10),
		"alternate": Rect2(10, 10, 10, 10)
	},
	"panda": {
		"default": Rect2(0, 20, 10, 10),
		"alternate": Rect2(10, 20, 10, 10)
	},
	"hunter": {
		"default": Rect2(0, 30, 10, 10),
		"alternate": Rect2(10, 30, 10, 10)
	},
}

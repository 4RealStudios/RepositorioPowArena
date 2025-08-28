extends CharacterBody2D

@export var speed: float = 85
#@export var spread: float = 0.15
@export var BULLET = preload("res://scenes/bullet.tscn")
@onready var shoot_point: Marker2D = $shoot_point

var input_vector: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.RIGHT
#var blocking: bool = false

func _physics_process(_delta: float) -> void:
	input_vector.x = Input.get_action_strength("p2_right") - Input.get_action_strength("p2_left")
	input_vector.y = Input.get_action_strength("p2_down") - Input.get_action_strength("p2_up")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		aim_dir = input_vector
	velocity = input_vector * speed
	move_and_slide()
	if input_vector != Vector2.ZERO:
		$Player2Sprite2D.rotation = aim_dir.angle() - PI/90
	if Input.is_action_just_pressed("p2_shoot"):
		shoot()

func shoot():
	var bullet = BULLET.instantiate()
	bullet.global_position = shoot_point.global_position
	bullet.direction = aim_dir
	get_parent().add_child(bullet)

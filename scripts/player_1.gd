extends CharacterBody2D

@export var speed: float = 250
var spread: float = 0.15
const BULLET = preload("res://scenes/bullet.tscn")
@onready var shooting_point: Marker2D = $shooting_point

var move_dir: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.RIGHT
var blocking: bool = false

func _process(_delta: float) -> void:
	get_input()
	move_and_slide()
	if Input.is_action_just_pressed("p1_shoot"):
		shoot()

func get_input():
	var stick_dir = Vector2(Input.get_action_strength("p1_right") - Input.get_action_strength("p1_left"), Input.get_action_strength("p1_down") - Input.get_action_strength("p1_up")).normalized()
	blocking = Input.is_action_pressed("p1_block")
	if blocking:
		velocity = Vector2.ZERO
	if stick_dir != Vector2.ZERO:
		aim_dir = stick_dir
	else:
		move_dir = stick_dir
	if move_dir != Vector2.ZERO:
		velocity = move_dir * speed
		aim_dir = move_dir
	else:
		velocity = Vector2.ZERO

func shoot():
	if BULLET == null or aim_dir == Vector2.ZERO:
		return
	var bullet = BULLET.instantiate()
	bullet.position = global_position
	var dir = aim_dir
	if move_dir != Vector2.ZERO and not blocking:
		var random_angle = randf_range(-spread, spread)
		dir = dir.rotated(random_angle)
		bullet.direction = dir.normalized()
		get_parent().add_child(bullet)

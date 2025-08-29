extends CharacterBody2D

@export var speed: float = 85
@export var BULLET = preload("res://scenes/bullet.tscn")
@onready var shooting_point: Marker2D = $ShootingPointP2
@export var dash_speed: float = 200
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.5

var input_vector: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.RIGHT
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

func _physics_process(delta: float) -> void:
	input_vector.x = Input.get_action_strength("p2_right") - Input.get_action_strength("p2_left")
	input_vector.y = Input.get_action_strength("p2_down") - Input.get_action_strength("p2_up")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		aim_dir = input_vector
	velocity = input_vector * speed
	if input_vector != Vector2.ZERO: #rotacion del sprite segun a donde mira
		$Player2Sprite2D.rotation = aim_dir.angle() - PI/90
	if dash_cooldown_timer > 0: #cooldown del dash
		dash_cooldown_timer -= delta
	if is_dashing:
		velocity = input_vector * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
	else:
		velocity = input_vector * speed
		if Input.is_action_just_pressed("p2_dash") and dash_cooldown_timer <= 0 and input_vector != Vector2.ZERO:
			start_dash()
	move_and_slide()
	if Input.is_action_just_pressed("p2_shoot"): #disparo
		shoot()

func start_dash():
	is_dashing = true
	dash_timer = dash_duration

func shoot():
	var bullet = BULLET.instantiate()
	bullet.global_position = shooting_point.global_position
	bullet.direction = aim_dir
	get_parent().add_child(bullet)

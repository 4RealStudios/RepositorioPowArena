extends CharacterBody2D

@export var speed: float = 85 #VELOCIDAD DEL PERSONAJE
@export var DISPARO = preload("res://scenes/disparo.tscn")
@onready var shooting_point: Marker2D = $ShootingPointP1
@export var player_id: int = 1 
@export var dash_speed: float = 300 #VELOCIDAD DEL DASH
@export var dash_duration: float = 0.1 #DURACION DEL DASH
@export var dash_cooldown: float = 1.5 #COOLDOWN DEL DASH
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2DP1

var can_move: bool = true
var lives: int = 3
var spawn_position: Vector2
var shoot_local_offset: Vector2
var input_vector: Vector2 = Vector2.ZERO 
var aim_dir: Vector2 = Vector2.RIGHT 
var is_dashing: bool = false  #VARIABLE PARA EL DASH
var dash_timer: float = 0.0 #VARIABLE PARA EL COOLDOWN DEL DASH
var dash_cooldown_timer: float = 0.0  #VARIABLE PARA EL COOLDOWN DEL DASH
var is_locking: bool = false
var max_bounces: int = 1
var current_bounces: int = 1

func _ready() -> void:
	spawn_position = global_position #guarda el punto de spawn inicial
	shoot_local_offset = shooting_point.position

func _physics_process(delta: float) -> void:
	if not can_move:
		return
	input_vector.x = Input.get_action_strength("p1_right") - Input.get_action_strength("p1_left")
	input_vector.y = Input.get_action_strength("p1_down") - Input.get_action_strength("p1_up")
	input_vector = input_vector.normalized()
	var is_locking = Input.is_action_pressed("p1_block")
	if not is_locking:
		if input_vector != Vector2.ZERO:
			aim_dir = input_vector
	else:
		if input_vector != Vector2.ZERO:
			aim_dir = input_vector
	if dash_cooldown_timer > 0: #COOLDOWN DEL DASH
		dash_cooldown_timer -= delta
	if is_dashing:
		velocity = input_vector * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
	else:
		if not is_locking:
			velocity = input_vector * speed
		else:
			velocity = Vector2.ZERO
		if Input.is_action_just_pressed("p1_dash") and dash_cooldown_timer <= 0 and input_vector != Vector2.ZERO: #DASH
			start_dash()
	if is_dashing or velocity.length() > 0:
		if anim_sprite.animation != "walk":
			anim_sprite.play("walk")
	else:
		if anim_sprite.animation != "idle":
			anim_sprite.play("idle")
	if aim_dir != Vector2.ZERO:
		anim_sprite.rotation = aim_dir.angle() - PI/90
	move_and_slide()
	if Input.is_action_just_pressed("p1_shoot"): #DISPARO
		shoot()
# ============================
# FUNCIONES
# ============================
func take_damage():
	lives -= 1
	get_tree().call_group("ui", "update_lives", player_id, lives)
	if lives <= 0:
		get_tree().call_group("game", "player_died", player_id)

func start_dash(): #FUNCION DEL DASH
	is_dashing = true
	dash_timer = dash_duration

func shoot(): #FUNCION DEL DISPARO
	var disparo = DISPARO.instantiate()
	var dir := aim_dir.normalized()
	var rotated_offset := shoot_local_offset.rotated(dir.angle() - PI)
	disparo.global_position = global_position + rotated_offset
	disparo.direction = aim_dir.normalized()
	disparo.rotation = aim_dir.angle()
	get_tree().current_scene.add_child(disparo)

func reset_powerups() -> void:
	max_bounces = 1
	current_bounces = 1

extends CharacterBody2D

@export var speed: float = 85.0
@export var DISPARO: PackedScene = preload("res://scenes/disparo.tscn")
@export var player_id: int = 2
@export var dash_speed: float = 250.0
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 1.5
@export var shoot_cooldown := 0.5

# invulnerabilidad / parpadeo
@export var invuln_time: float = 2.0
@export var blink_interval: float = 0.10  

# --- Nodos ---
@onready var shooting_point: Marker2D = $ShootingPointP2
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2DP2

# --- Estado ---
var can_shoot: bool = true
var extra_bounces: int = 0
var can_move: bool = true
var lives: int = 3
var is_invulnerable: bool = false
var is_dead: bool = false
var is_hurt: bool = false

var input_vector: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.RIGHT
var spawn_position: Vector2
var shoot_local_offset: Vector2

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

var is_shooting: bool = false
var last_shoot_time: float = -9999.0

func _ready() -> void:
	can_move = false
	anim_sprite.play("idle")
	spawn_position = global_position
	shoot_local_offset = shooting_point.position

func _physics_process(delta: float) -> void:
	if not can_move or is_dead:
		velocity = Vector2.ZERO
		_update_animation()
		move_and_slide()
		return

	input_vector.x = Input.get_action_strength("p2_right") - Input.get_action_strength("p2_left")
	input_vector.y = Input.get_action_strength("p2_down")  - Input.get_action_strength("p2_up")
	input_vector = input_vector.normalized()

	var blocking := Input.is_action_pressed("p2_block")
	if input_vector != Vector2.ZERO:
		aim_dir = input_vector

	# --- dash cooldown y dash ---
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if is_dashing:
		velocity = input_vector * dash_speed
		dash_timer -= delta
		if input_vector != Vector2.ZERO:
			aim_dir = input_vector
			anim_sprite.rotation = aim_dir.angle() - PI/1
		if anim_sprite.animation != "dash":
			anim_sprite.play("dash")
		if dash_timer <= 0.0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
		move_and_slide()
		return
	else:
		if blocking:
			velocity = Vector2.ZERO
		else:
			velocity = input_vector * speed
			# iniciar dash si corresponde
		if Input.is_action_just_pressed("p2_dash") and dash_cooldown_timer <= 0.0 and input_vector != Vector2.ZERO:
			start_dash()
			
	if aim_dir != Vector2.ZERO:
		anim_sprite.rotation = aim_dir.angle() - PI/1
		
	_update_animation()
	
	move_and_slide()
	if Input.is_action_just_pressed("p2_shoot"):
		shoot()

func shoot() -> void:
	if not can_shoot or is_dead:
		return
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_shoot_time < shoot_cooldown:
		return
	last_shoot_time = now
	
	var disparo = DISPARO.instantiate()
	var dir := aim_dir.normalized()
	var rotated_offset := shoot_local_offset.rotated(dir.angle() - PI)
	
	disparo.global_position = global_position + rotated_offset
	disparo.direction = dir
	disparo.rotation = dir.angle()
	
	disparo.max_bounces += extra_bounces
	
	get_tree().current_scene.add_child(disparo)
	is_shooting = true
	anim_sprite.play("shooting")

func _on_animated_sprite_2dp_2_animation_finished() -> void:
	if anim_sprite.animation == "shooting":
		is_shooting = false
		_update_animation()
	elif anim_sprite.animation == "hurt" and not is_dead:
		is_hurt = false
		_update_animation()

func _update_animation() -> void:
	if is_dead:
		if anim_sprite.animation != "die":
			anim_sprite.play("die")
		return
	
	if is_hurt:
		if anim_sprite.animation != "hurt":
			anim_sprite.play("hurt")
		return
	
	if is_dashing:
		if anim_sprite.animation != "dash":
			anim_sprite.play("dash")
		return
	
	if is_shooting:
		if anim_sprite.animation != "shooting":
			anim_sprite.play("shooting")
		return
	
	if velocity.length() > 0:
		if anim_sprite.animation != "walk":
			anim_sprite.play("walk")
	else:
		if anim_sprite.animation != "idle":
			anim_sprite.play("idle")

func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	anim_sprite.play("dash")

func take_damage() -> void:
	if is_dead or is_invulnerable:
		return

	lives -= 1
	get_tree().call_group("ui", "update_lives", player_id, lives)

	if lives <= 0:
		is_dead = true
		can_move = false
		anim_sprite.play("die")
		get_tree().call_group("game", "player_died", player_id)
		return

	is_invulnerable = true
	is_hurt = true
	anim_sprite.play("hurt")
	start_invulnerability()

func start_invulnerability() -> void:
	is_invulnerable = true
	var elapsed := 0.0
	while elapsed < invuln_time and is_instance_valid(anim_sprite) and is_invulnerable:
		anim_sprite.visible = not anim_sprite.visible
		await get_tree().create_timer(blink_interval).timeout
		elapsed += blink_interval
		
	# finalizar invulnerabilidad
	if is_instance_valid(anim_sprite):
		anim_sprite.visible = true
	is_invulnerable = false

	if not is_dead and anim_sprite.animation == "hurt":
		anim_sprite.play("idle")

func reset_for_round() -> void:
	lives = 3
	is_dead = false
	is_invulnerable = false
	is_shooting = false
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	last_shoot_time = -9999.0
	velocity = Vector2.ZERO
	anim_sprite.visible = true
	anim_sprite.play("idle")
	extra_bounces = 0

func set_can_move(enable: bool) -> void:
	can_move = enable

func set_can_shoot(enable: bool) -> void:
	can_shoot = enable

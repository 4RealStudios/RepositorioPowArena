
extends CharacterBody2D


@export var speed: float = 85.0
@export var DISPARO: PackedScene = preload("res://scenes/disparo.tscn")
@export var player_id: int = 1
@export var dash_speed: float = 300.0
@export var dash_duration: float = 0.1
@export var dash_cooldown: float = 1.5
@export var shoot_cooldown := 0.5

# invulnerabilidad / parpadeo
@export var invuln_time: float = 2.0
@export var blink_interval: float = 0.10  # tiempo entre toggles de visibilidad

# --- Nodos ---
@onready var shooting_point: Marker2D = $ShootingPointP1
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2DP1

# --- Estado ---
var can_move: bool = true
var lives: int = 3
var is_invulnerable: bool = false
var is_dead: bool = false

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
	spawn_position = global_position
	shoot_local_offset = shooting_point.position
	if anim_sprite:
		anim_sprite.connect("animation_finished", Callable(self, "_on_anim_finished"))

func _physics_process(delta: float) -> void:
	# si está muerto no procesamos
	if is_dead:
		return

	# --- input (siempre leemos el stick para poder apuntar aunque 'can_move' sea false) ---
	input_vector.x = Input.get_action_strength("p1_right") - Input.get_action_strength("p1_left")
	input_vector.y = Input.get_action_strength("p1_down")  - Input.get_action_strength("p1_up")
	input_vector = input_vector.normalized()

	# bloqueo con el botón (hold) — si está presionado no se mueve, pero SÍ actualiza aim_dir
	var blocking := Input.is_action_pressed("p1_block")
	if input_vector != Vector2.ZERO:
		aim_dir = input_vector

	# --- dash cooldown y dash ---
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if is_dashing:
		velocity = input_vector * dash_speed
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
	else:
		# si can_move es false, no se mueve (ej: durante cuenta regresiva del GameManager)
		if not can_move:
			velocity = Vector2.ZERO
		else:
			# si está blockeando con el botón, no nos movemos (pero seguimos apuntando)
			if blocking:
				velocity = Vector2.ZERO
			else:
				velocity = input_vector * speed
			# iniciar dash si corresponde
			if Input.is_action_just_pressed("p1_dash") and dash_cooldown_timer <= 0.0 and input_vector != Vector2.ZERO:
				start_dash()

	# rotación del sprite para apuntar
	if aim_dir != Vector2.ZERO:
		anim_sprite.rotation = aim_dir.angle() - PI/90

	# --- animaciones (no bloqueamos movimiento por is_shooting) ---
	# mostrar walk/idle salvo que esté en "hurt" o "shooting"
	if not is_dead:
		if anim_sprite.animation == "hurt":
			# dejamos la animación de daño intacta
			pass
		elif is_shooting:
			# dejamos que "shooting" se muestre completa (pero NO bloquea movimiento)
			pass
		else:
			if velocity.length() > 0.0:
				if anim_sprite.animation != "walk":
					anim_sprite.play("walk")
			else:
				if anim_sprite.animation != "idle":
					anim_sprite.play("idle")

	move_and_slide()

	# --- disparo ---
	if Input.is_action_just_pressed("p1_shoot"):
		shoot()

# =====================
# DISPARO
# =====================
func shoot() -> void:
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
	# si la bala tiene owner_id, setealo (útil para evitar self-hit)
	if "owner_id" in disparo:
		disparo.owner_id = player_id
	get_tree().current_scene.add_child(disparo)

	is_shooting = true
	anim_sprite.play("shooting")

func _on_anim_finished() -> void:
	# signal handler para cuando termina cualquier anim. Si terminó "shooting", desactivo la bandera.
	if anim_sprite.animation == "shooting":
		is_shooting = false
		# siguiente frame el _physics_process decidirá si poner idle/walk

# =====================
# DASH
# =====================
func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration

# =====================
# DAÑO + INVULNERABILIDAD (parpadeo con duración exacta)
# =====================
func take_damage() -> void:
	# si ya está muerto o invulnerable, ignorar
	if is_dead or is_invulnerable:
		return

	lives -= 1
	get_tree().call_group("ui", "update_lives", player_id, lives)

	if lives <= 0:
		is_dead = true
		anim_sprite.play("hurt")
		can_move = false
		get_tree().call_group("game", "player_died", player_id)
		return

	# daño pero sigue pudiendo moverse; queda invulnerable por invuln_time
	is_invulnerable = true
	anim_sprite.play("hurt")
	# no awaitamos: arranca el coroutine en paralelo
	start_invulnerability()

func start_invulnerability() -> void:
	# duración exacta (en ms)
	var end_ms := Time.get_ticks_msec() + int(invuln_time * 1000.0)
	var blink_timer := get_tree().create_timer(blink_interval, true)

	while Time.get_ticks_msec() < end_ms and is_instance_valid(anim_sprite) and is_invulnerable:
		anim_sprite.visible = not anim_sprite.visible
		await blink_timer.timeout

	# finalizar invulnerabilidad
	if is_instance_valid(anim_sprite):
		anim_sprite.visible = true
	is_invulnerable = false
	# si no murió, volver a idle si sigue en "hurt"
	if not is_dead and anim_sprite.animation == "hurt":
		anim_sprite.play("idle")

# =====================
# RESET / API para GameManager
# =====================
func reset_for_round() -> void:
	# llamado por GameManager al comenzar la ronda (asegura limpieza de flags)
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
	# can_move lo manejará el GameManager (puede dejarlo false hasta el pow)

func set_can_move(enable: bool) -> void:
	can_move = enable

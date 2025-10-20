extends CharacterBody2D

@export var speed: float = 85.0
@export var DISPARO: PackedScene = preload("res://scenes/disparo.tscn")
@export var player_id: int = 1
@export var character_name: String = "robot"
@export var skin_type: String = "main" 
@export var dash_speed: float = 250.0
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 1.5
@export var shoot_cooldown := 0.5

# invulnerabilidad / parpadeo
@export var invuln_time: float = 2.0
@export var blink_interval: float = 0.10  

# --- Nodos ---
@onready var shooting_point: Marker2D = $ShootingPointP1
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2DP1
@onready var shield_effect: AnimatedSprite2D = $ShieldEffect if has_node("ShieldEffect") else null
@onready var disparo_sfx = $DisparoSFX
@onready var daño_sfx = $DanoSFX
@onready var dash_sfx = $DashSFX
@onready var muerte_sfx = $MuerteSFX

# --- Estado ---
var can_shoot: bool = true
var extra_bounces: int = 0
var can_move: bool = true
var lives: int = 3
var is_invulnerable: bool = false
var is_dead: bool = false
var is_hurt: bool = false
var has_shield: bool = false
var shield_node: AnimatedSprite2D = null  #----
var shield_timer: Timer = null  #----
var speed_boost_active: bool = false
var speed_boost_timer: Timer
var speed_multiplier: float = 1.5
var speed_boost_duration: float = 5.0

var input_vector: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.RIGHT
var spawn_position: Vector2
var shoot_local_offset: Vector2
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_shooting: bool = false
var last_shoot_time: float = -9999.0

var characters := {
	"robot":{
		"main": preload("res://assets/players/skins/robot.tres"),
		"alt": preload("res://assets/players/skins/robot_alt.tres")
	},
	"mago": {
		"main": preload("res://assets/players/skins/mago.tres"),
		"alt": preload("res://assets/players/skins/mago_alt.tres")
	},
	"panda": {
		"main": preload("res://assets/players/skins/panda.tres"),
		"alt": preload("res://assets/players/skins/panda_alt.tres")
	},
	"hunter": {
	"main": preload("res://assets/players/skins/hunter.tres"),
	"alt": preload("res://assets/players/skins/hunter_alt.tres")
	}
}

var character_sounds := {
	"robot":{
		"shoot": preload("res://fx/players/robot/Disparo_robot_op1.wav"),
		"dash": preload("res://fx/players/Dash_op1.wav"),
		"hurt": preload("res://fx/players/Sonido_Dano.wav"),
		"death": preload("res://fx/players/Sonido_Muerte_op3.wav")
	},
	"mago": {
		"shoot": preload("res://fx/players/mago/Disparo_mago_op2.wav"),
		"dash": preload("res://fx/players/Dash_op1.wav"),
		"hurt": preload("res://fx/players/Sonido_Dano.wav"),
		"death": preload("res://fx/players/Sonido_Muerte_op3.wav")
	},
	"panda": {
		"shoot": preload("res://fx/players/panda/Disparo_panda_op1.wav"),
		"dash": preload("res://fx/players/Dash_op1.wav"),
		"hurt": preload("res://fx/players/Sonido_Dano.wav"),
		"death": preload("res://fx/players/Sonido_Muerte_op3.wav")
	},
	"hunter": {
		"shoot": preload("res://fx/players/hunter/Disparo_hunter.wav"),
		"dash": preload("res://fx/players/Dash_op1.wav"),
		"hurt": preload("res://fx/players/Sonido_Dano.wav"),
		"death": preload("res://fx/players/Sonido_Muerte_op3.wav")
	}
}

func _ready() -> void:
	if Global.player1_choice != "" and player_id == 1:
		character_name = Global.player1_choice
		skin_type = "alt" if Global.player1_alt else "main"
	elif Global.player2_choice != "" and player_id == 2:
		character_name = Global.player2_choice
		skin_type = "alt" if Global.player2_alt else "main"
	print("[PLAYER _ready] id:", player_id, " character:", character_name, " skin:", skin_type)
	if Global.bullet_atlas and Global.bullet_regions.has(character_name):
		var region_map = Global.bullet_regions[character_name]
		var key := "main" if skin_type == "main" else "alt"
		if region_map.has(key):
			var region = region_map[key]
			var bullet_tex := AtlasTexture.new()
			bullet_tex.atlas = Global.bullet_atlas
			bullet_tex.region = region
			set_meta("bullet_texture", bullet_tex)
			print("[PLAYER] Seteada bullet texture ->", character_name, key, region)
		else:
			printerr("[PLAYER] Global.bullet_regions[", character_name, "] no tiene key:", key)
	else:
		printerr("[PLAYER] Global.bullet_atlas o bullet_regions no configurado o falta character:", character_name)
	
	if character_sounds.has(character_name):
		var sounds = character_sounds[character_name]
		if disparo_sfx:
			disparo_sfx.stream = sounds["shoot"]
		if daño_sfx:
			daño_sfx.stream = sounds["hurt"]
		if not has_node("DeathSFX"):
			var death_sfx = AudioStreamPlayer2D.new()
			death_sfx.name = "DeathSFX"
			add_child(death_sfx)
		else:
			var death_sfx = $MuerteSFX
			death_sfx.stream = sounds["death"]
	
	if player_id == 1:
		anim_sprite.sprite_frames = characters[character_name]["main"]
	else:
		anim_sprite.sprite_frames = characters[character_name]["alt"]
	can_move = false
	anim_sprite.play("idle")
	spawn_position = global_position
	shoot_local_offset = shooting_point.position
	if shield_effect:
		shield_effect.visible = false
	speed_boost_timer = Timer.new()
	speed_boost_timer.one_shot = true
	speed_boost_timer.wait_time = speed_boost_duration
	add_child(speed_boost_timer)
	speed_boost_timer.timeout.connect(_on_speed_boost_timeout)

func _physics_process(delta: float) -> void:
	if not can_move or is_dead:
		velocity = Vector2.ZERO
		_update_animation()
		move_and_slide()
		return
	input_vector.x = Input.get_action_strength("p1_right") - Input.get_action_strength("p1_left")
	input_vector.y = Input.get_action_strength("p1_down")  - Input.get_action_strength("p1_up")
	input_vector = input_vector.normalized()
	var blocking := Input.is_action_pressed("p1_block")
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
			anim_sprite.rotation = aim_dir.angle() - PI/90
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
		if Input.is_action_just_pressed("p1_dash") and dash_cooldown_timer <= 0.0 and input_vector != Vector2.ZERO:
			start_dash()
			dash_sfx.play()
			
	if aim_dir != Vector2.ZERO:
		anim_sprite.rotation = aim_dir.angle() - PI/90
		
	_update_animation()
	move_and_slide()
	if Input.is_action_just_pressed("p1_shoot"):
		shoot()

func _check_collision(body):
	if body.is_in_group("bullets"):
		if has_shield:
			# Reflejar UNA sola bala y romper el escudo al instante
			if body.has_variable("direction"):
				body.direction = -body.direction
				body.rotation = body.direction.angle()
			# Reproducir animación de ruptura si existe
			if shield_effect and is_instance_valid(shield_effect):
				shield_effect.play("shield_break")
				await shield_effect.animation_finished
				shield_effect.visible = false
			# Desactivar escudo inmediatamente
			await desactivate_shield()
		else:
			take_damage()

func set_bullet_sprite(skin_name: String, is_alt: bool = false):
	if not Global.BULLET_SPRITES.has(skin_name):
		printerr("[PLAYER] No se encontró sprite de bala para:", skin_name)
		return

	var region_key = "alternate" if is_alt else "default"
	var region = Global.BULLET_SPRITES[skin_name].get(region_key)
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = Global.BULLET_ATLAS
	atlas_texture.region = region

	var sprite = $Sprite2D
	if sprite:
		sprite.texture = atlas_texture
	else:
		printerr("[PLAYER] ⚠️ No se encontró Sprite2D en la escena del disparo.")

func shoot() -> void:
	if not can_shoot or is_dead:
		return
	var now = Time.get_ticks_msec() / 1250.0
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
	
	disparo.set_meta("bullet_rotation", dir.angle())
	
	if has_meta("bullet_texture"):
		disparo.set_meta("bullet_texture", get_meta("bullet_texture"))
	
	get_tree().current_scene.add_child(disparo)
	is_shooting = true
	anim_sprite.play("shooting")
	disparo_sfx.play()

func _break_shield() -> void:
	has_shield = false
	if has_node("ShieldTimer"):
		$ShieldTimer.stop()

func _on_animated_sprite_2dp_1_animation_finished() -> void:
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
	dash_sfx.play()
	is_invulnerable = true
	await get_tree().create_timer(dash_duration).timeout
	is_invulnerable = false

func take_damage() -> void:
	if is_dead or is_invulnerable:
		return
	if has_shield:
		await desactivate_shield()
		return
		
	lives -= 1
	get_tree().call_group("ui", "update_lives", player_id, lives)
	if lives <= 0:
		is_dead = true
		can_move = false
		anim_sprite.play("die")
		if has_node("DeathSFX"):
			muerte_sfx.play()
		get_tree().call_group("game", "on_player_died", player_id)
		return
		
	is_invulnerable = true
	is_hurt = true
	anim_sprite.play("hurt")
	daño_sfx.play()
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

func activate_shield(duration: float = 5.0) -> void:
	if not $ShieldEffect: 
		return
	
	has_shield = true
	if $ShieldEffect:
		$ShieldEffect.visible = true
		$ShieldEffect.play("shield_idle")

	if has_node("ShieldTimer"):
		$ShieldTimer.stop()
	else:
		var timer = Timer.new()
		timer.name = "ShieldTimer"
		add_child(timer)
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_on_shield_timeout"))
	$ShieldTimer.start(duration)

func apply_shield(frames: SpriteFrames, duration: float = 5.0) -> void:
	if has_shield:
		# si ya tiene escudo, reiniciamos el timer (si querés)
		if shield_timer and is_instance_valid(shield_timer):
			shield_timer.wait_time = duration
			shield_timer.start()
		return

	has_shield = true

	# Si el nodo ShieldEffect ya existe en la escena, lo usamos; sino instanciamos uno dinámico
	if shield_effect and is_instance_valid(shield_effect):
		shield_node = shield_effect
		# Si el shield_effect está en la escena, asumimos que tiene sprite_frames asignado
		if shield_node.sprite_frames == null and frames != null:
			shield_node.sprite_frames = frames
	else:
		# instanciamos uno nuevo y lo agregamos como hijo
		shield_node = AnimatedSprite2D.new()
		if frames != null:
			shield_node.sprite_frames = frames
		shield_node.animation = "shield_idle" if shield_node.sprite_frames and shield_node.sprite_frames.has_animation("shield") else ""
		shield_node.z_index = -1
		add_child(shield_node)

	# mostrar y reproducir animación de escudo (idle)
	shield_node.visible = true
	if shield_node.animation != "" :
		shield_node.play(shield_node.animation if shield_node.animation != "" else "shield")

	# timer para duración
	if shield_timer and is_instance_valid(shield_timer):
		shield_timer.queue_free()
	shield_timer = Timer.new()
	shield_timer.one_shot = true
	shield_timer.wait_time = duration
	add_child(shield_timer)
	shield_timer.start()
	await shield_timer.timeout
	# al expirar, rompemos el escudo
	if has_shield:
		await desactivate_shield()

func desactivate_shield() -> void:
	if not has_shield:
		return
	has_shield = false

	# si hay timer, eliminarlo
	if shield_timer and is_instance_valid(shield_timer):
		shield_timer.queue_free()
		shield_timer = null

	if shield_node and is_instance_valid(shield_node):
		# reproducir animación de quiebre si existe
		if shield_node.sprite_frames and shield_node.sprite_frames.has_animation("shield_break"):
			shield_node.play("shield_break")
			await shield_node.animation_finished
		# ocultar o borrar el nodo instanciado dinámicamente
		# si shield_effect era un nodo preexistente, solo lo ocultamos
		if shield_effect and is_instance_valid(shield_effect):
			shield_node.visible = false
		else:
			shield_node.queue_free()
		shield_node = null

func _on_shield_timeout() -> void:
	has_shield = false
	if $ShieldEffect:
		$ShieldEffect.play("shield_break")
		await $ShieldEffect.animation_finished
		$ShieldEffect.visible = false

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
	desactivate_shield()
	speed = speed
	speed_boost_active = false
	if speed_boost_timer:
		speed_boost_timer.stop()

func activate_speed_boost():
	if speed_boost_active:
		speed_boost_timer.start()
		return
		
	speed_boost_active = true
	speed *= speed_multiplier
	speed_boost_timer.start()

func _on_speed_boost_timeout():
	speed_boost_active = false
	speed = speed

func set_can_move(enable: bool) -> void:
	can_move = enable

func set_can_shoot(enable: bool) -> void:
	can_shoot = enable

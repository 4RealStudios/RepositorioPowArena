extends CharacterBody2D
# Si tu bala es Node2D, cambiá la 1ra línea por: extends Node2D

@export var speed: float = 160
@export_flags_2d_physics var hit_mask: int = 1    # capas con las que debe colisionar (ej: World + Players)
var direction: Vector2 = Vector2.ZERO

const MAX_BOUNCES := 1
var bounces := 0

func _physics_process(delta: float) -> void:
	var from := global_position
	var to := from + direction * speed * delta

	var params := PhysicsRayQueryParameters2D.create(from, to)
	params.collision_mask = hit_mask
	params.exclude = [self]

	var hit := get_world_2d().direct_space_state.intersect_ray(params)

	if hit:
		var collider: Node = hit.collider as Node
		# Colocamos la bala justo en el punto de impacto
		global_position = hit.position

		# Si pegó a un jugador → daño y destruir
		if collider and collider.is_in_group("Players"):
			if "take_damage" in collider:
				collider.take_damage()
			queue_free()
			return

		# Rebote 1 sola vez contra paredes/tiles/etc.
		if bounces < MAX_BOUNCES:
			direction = direction.bounce(hit.normal).normalized()
			bounces += 1
			# avanzar un pelito después del rebote para no quedarse pegado
			global_position += direction * 0.5
		else:
			queue_free()
	else:
		# Sin impacto → avanzar normal
		global_position = to

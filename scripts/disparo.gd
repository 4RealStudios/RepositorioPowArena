extends CharacterBody2D

@export var speed: float = 160
@export_flags_2d_physics var hit_mask: int = 1    
var direction: Vector2 = Vector2.ZERO

const MAX_BOUNCES := 3
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
		global_position = hit.position
		if collider and collider.is_in_group("Players"):
			if "take_damage" in collider:
				collider.take_damage()
			queue_free()
			return
		if bounces < MAX_BOUNCES:
			direction = direction.bounce(hit.normal).normalized()
			bounces += 1
			global_position += direction * 0.5
		else:
			queue_free()
	else:
		global_position = to

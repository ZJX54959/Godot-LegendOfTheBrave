class_name Hitbox
extends Area2D

signal hit(hurtbox)

var damage: Damage = null

func _init() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	# print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name])
	if area is Hurtbox:
		var hurtbox = area
		hit.emit(hurtbox)
		if damage:
			hurtbox.hurt.emit(self, damage)
		else :
			hurtbox.hurt.emit(self, Damage.new(0, owner))
		damage_particles(hurtbox)
	
	if area is Hitbox:
		# var hitbox = area
		pass
	
func damage_particles(hurtbox: Hurtbox) -> void:
	if not damage:
		return
	
	var particle := GPUParticles2D.new()
	particle.one_shot = true
	particle.global_position = lerp(hurtbox.owner.global_position + Vector2(0, -16), owner.global_position, randf_range(0, .2))
	# particle.amount = 10
	particle.lifetime = 0.5
	# particle.process_material = load("res://assets/particles/fire.tres")

	match damage.type:
		"fire":
			pass
		"ice":
			pass
		"poison":
			pass
		"electric":
			pass
		"wind":
			pass
		"earth":
			pass
		"water":
			pass
		"dark":
			pass
		"light":
			pass
		"slash":
			particle.texture = load("res://assets/Orb1.tres")
			particle.amount = 1
			particle.lifetime = 0.1
			particle.modulate = Color(0.8, 0.9, 1)
			particle.local_coords = true
			particle.scale = Vector2(2.5, 0.3)
			particle.rotation = randf_range(-10, 10) + (hurtbox.global_position - self.global_position).angle()
			get_tree().create_tween().tween_property(particle, "scale", particle.scale * .75, particle.lifetime).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
		"pierce":
			pass
		_:
			pass
	
	get_tree().root.add_child(particle)
	particle.emitting = true
	print(particle.name)
	await particle.finished
	particle.queue_free()

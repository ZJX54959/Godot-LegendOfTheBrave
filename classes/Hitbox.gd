class_name Hitbox
extends Area2D

signal hit(hurtbox)

var damage: Damage = null

func _init() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(hurtbox: Hurtbox) -> void:
	# print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name])
	hit.emit(hurtbox)
	if damage:
		hurtbox.hurt.emit(self, damage)
		damage = null
	else :
		hurtbox.hurt.emit(self, Damage.new(0, owner))

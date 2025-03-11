class_name Damage
extends RefCounted

var name: String
var amount: float
var inv_frame: int:
	set(value):
		if value > 0:
			inv_frame = value
		else:
			inv_frame = -1
var source: Node2D
var knockback_force: float  # 击退力度
var knockback_dir: Vector2  # 击退方向（归一化向量）
var type: String
var hurt_layer: int
var smash_attack: bool

func _init(
	damage: float, 
	from: Node2D, 
	frame: int = -1,
	force: float = 1.0,
	direction: Vector2 = Vector2.ZERO
) -> void:
	amount = damage
	source = from
	knockback_force = force
	inv_frame = frame
	knockback_dir = direction if not direction.is_zero_approx() else Vector2.ZERO
	# 默认使用从攻击者到受击者的反方向
	if knockback_dir.is_zero_approx() and is_instance_valid(source):
		knockback_dir = (from.global_position - source.global_position).normalized()
	
	

func with_name(wrd: String) -> Damage:
	self.name = wrd
	return self

func with_type(wrd: String) -> Damage:
	self.type = wrd
	return self

func with_hurt_layer(wrd: int) -> Damage:
	self.hurt_layer = wrd
	return self

func smash() -> Damage:
	self.smash_attack = true
	return self

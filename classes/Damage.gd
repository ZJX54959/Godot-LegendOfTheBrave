class_name Damage
extends RefCounted

var name: String
var amount: float
var inv_frame: int
var source: Node2D
var knockback_force: float  # 击退力度
var knockback_dir: Vector2  # 击退方向（归一化向量）

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
	knockback_dir = direction if not direction.is_zero_approx() else Vector2.ZERO
	# 默认使用从攻击者到受击者的反方向
	if knockback_dir.is_zero_approx() and is_instance_valid(source):
		knockback_dir = (from.global_position - source.global_position).normalized()
	
	if frame > 0:
		inv_frame = frame
	else:
		inv_frame = -1
	

func with_name(wrd: String) -> Damage:
	name = wrd
	return self

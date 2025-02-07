class_name Damage
extends RefCounted

var amount: float
var inv_frame: int
var source: Node2D
var knockback: float:
	set(v):
		# to_be_done
		pass

func _init(damage: float, from: Node2D, frame: int = -1) -> void:
	amount = damage
	source = from
	if frame > 0:
		inv_frame = frame
	else:
		inv_frame = 2<<64
	

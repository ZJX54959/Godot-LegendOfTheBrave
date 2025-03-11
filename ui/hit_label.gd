class_name HitLabel
extends Label


const THEME = preload("res://assets/theme.tres")

var health_change: int
var color: Color
var M_hp: int = 10
var hp: int
var base_scale: float = 1.0

func _init(hc: int):
	theme = THEME
	hp = hc
	pass

func set_bias_position(pos: Vector2) -> HitLabel:
	position = pos + Vector2(randf_range(-10, 10), randf_range(-10, -20))
	return self
func with_hp(Mhp: int) -> HitLabel:
	M_hp = Mhp
	return self

func initailize() -> void:
	# global_scale = Vector2(1, 1)
	base_scale = clamp(tanh(float(abs(hp))/M_hp), 0.3, 3.0)
	scale = Vector2(base_scale, base_scale)
	print(base_scale, hp, M_hp, tanh(float(hp)/M_hp))
	pass


func _ready():
	# set_vars()
	initailize()
	text = str(hp)
	if hp < 0:
		modulate = Color(1, 1 - abs(hp)/M_hp, 1 - abs(hp)/M_hp, 1)
	else:
		modulate = Color(1 - abs(hp)/M_hp, 1, 1 - abs(hp)/M_hp, 1)

	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2) * base_scale, 0.1)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0) * base_scale, 0.1).set_delay(0.1)
	tween.parallel().tween_property(self, "position", position + Vector2(0, -10), 0.3)
	tween.tween_property(self, "position", position + Vector2(0, -22), 0.3).set_delay(0.1)
	tween.parallel().tween_property(self, "modulate:a", 0, 0.3)

	tween.tween_callback(queue_free)

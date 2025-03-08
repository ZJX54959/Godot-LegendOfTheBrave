class_name HitLabel
extends Label


const THEME = preload("res://assets/theme.tres")

# @onready var label: Label = $Label

var health_change: int
var color: Color

func _init(hp: int):
	# await label.ready
	# label.text = str(health_change)
	# if health_change < 0:
	# 	label.modulate.r = health_change/30.0
	# else:
	# 	label.modulate.g = health_change/30.0
	# get_vars(hp)
	theme = THEME
	text = str(hp)
	if hp < 0:
		modulate = Color(1, 1 - abs(hp)/30.0, 1 - abs(hp)/30.0, 1)
	else:
		modulate = Color(1 - abs(hp)/30.0, 1, 1 - abs(hp)/30.0, 1)
	pass

# func set_vars():
# 	# label.text = str(health_change)
# 	# label.modulate = color
# 	text = str(health_change)
# 	modulate = color

# func get_vars(hp_change: int):
# 	health_change = hp_change
# 	if health_change < 0:
# 		color = Color(1 - abs(health_change)/30.0, 0, 0, 1)
# 	else:
# 		color = Color(0, 1 - abs(health_change)/30.0, 0, 1)

func set_bias_position(pos: Vector2) -> HitLabel:
	position = pos + Vector2(randf_range(-10, 10), randf_range(-10, -20))
	return self

func initailize() -> void:
	# global_scale = Vector2(1, 1)
	pass


func _ready():
	# set_vars()
	initailize()

	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)
	tween.parallel().tween_property(self, "position", position + Vector2(0, -10), 0.3)
	tween.tween_property(self, "position", position + Vector2(0, -22), 0.3).set_delay(0.1)
	tween.parallel().tween_property(self, "modulate:a", 0, 0.3)

	tween.tween_callback(queue_free)

extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var skewValue := 15
@export var bendGrassAnimationSpeed := 0.3
@export var grassReturnAnimationSpeed := 5.0


var PINK_TULIP = load("res://assets/interactive_grass/pink_tulip.png")
var RED_ROSE = load("res://assets/interactive_grass/red_rose.png")

var Texs := [
	PINK_TULIP,
	RED_ROSE,
]


func _ready() -> void:
	sprite_2d.texture = Texs.pick_random()
	
	# 统一宽度自动缩放
	var target_width := 16.0  # 根据需求调整目标宽度
	var tex_size := sprite_2d.texture.get_size()
	var scale_factor := target_width / tex_size.x
	sprite_2d.scale = Vector2(scale_factor, scale_factor)
	
	# 底部对齐（设置offset到精灵高度的一半）
	sprite_2d.offset.y = - tex_size.y * scale_factor / 2


func _on_body_entered(body: Node2D) -> void:
	if body == get_tree().get_first_node_in_group("player") or true:
		var direction := global_position.direction_to(body.global_position)
		var skw: int = clamp(direction.x * skewValue, -10., 10.)
		
		var tween := create_tween()
		tween.tween_property(
			sprite_2d.material,
			"shader_parameter/skew",
			skw,
			bendGrassAnimationSpeed
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		tween.tween_property(
			sprite_2d.material,
			"shader_parameter/skew",
			0.0,
			grassReturnAnimationSpeed
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	pass # Replace with function body.


func _on_area_entered(area: Area2D) -> void:
	_on_body_entered(area)

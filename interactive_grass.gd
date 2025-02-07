extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var skewValue := 15
@export var bendGrassAnimationSpeed := 0.3
@export var grassReturnAnimationSpeed := 5.0

func _on_body_entered(body: Node2D) -> void:
	if body == get_tree().get_first_node_in_group("player") or true:
		var direction := global_position.direction_to(body.global_position)
		var skew: int = clamp(direction.x * skewValue, -10., 10.)
		
		var tween := create_tween()
		tween.tween_property(
			sprite_2d.material,
			"shader_parameter/skew",
			skew,
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

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
	#while sprite_2d.texture.get_size() > Vector2(16, 16):
		#sprite_2d.texture *= Vector2(.5, .5)
	if sprite_2d.texture == RED_ROSE:
		sprite_2d.scale *= .25
		sprite_2d.position.y -= sprite_2d.texture.get_size().y / 4.


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

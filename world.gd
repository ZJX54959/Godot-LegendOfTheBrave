extends Node2D

@onready var tile_map: TileMap = $TileMap
@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var boar := preload("res://enemies/boar.tscn")


func _ready() -> void:
	var used := tile_map.get_used_rect().grow(-1)
	var tile_size := tile_map.tile_set.tile_size
	
	camera_2d.limit_top = used.position.y * tile_size.y
	camera_2d.limit_right = used.end.x * tile_size.x
	camera_2d.limit_bottom = used.end.y * tile_size.y
	camera_2d.limit_left = used.position.x * tile_size.x
	camera_2d.reset_smoothing()


func _physics_process(delta: float) -> void:
	#SceneTree
	#add_child()
	#instance_node()
	#if Input.is_action_pressed("slide"):
		#new_boar()
	pass


func new_boar() -> void:
	var now_boar := boar.instantiate()
	now_boar.global_position = camera_2d.global_position
	print(now_boar.position)
	get_tree().root.add_child(now_boar)

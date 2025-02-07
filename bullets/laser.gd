class_name Laser
extends Bullet

@export var segment_texture: Texture2D
@export var segment_length: float = 32.0
@export var max_segments: int = 32
@export var max_length: float = 1024.0
@export var owner_node: Node2D

@export_category("Laser Parts")
@export var head_texture: Texture2D
@export var body_texture: Texture2D
@export var tail_texture: Texture2D
@export var is_following: bool = false  # 是否跟随发射者
@export var fade_out_duration: float = 0.5  # 消失渐变时间

@onready var ray_cast: RayCast2D = $Bodies/RayCast2D
@onready var bodies: Node2D = $Bodies
@onready var laser_collision_shape: CollisionShape2D = $Bodies/Hitbox/CollisionShape2D
@onready var laser_hitbox: Hitbox = $Bodies/Hitbox

var active_segments: Array[Node2D] = []
var segment_pool: Array[Node2D] = []


var initial_position: Vector2	# 初始化激光位置 (self.position <- local_to(owner_node)) # 激光子弹相对于owner_node的初始位置，不一定是激光实际射出位置
var direction: Vector2	# 激光方向
var base_position: Vector2	# 激光基点 (bodies.position <- local_to(self)) # 激光实际射出位置
'''
激光子弹global_position = owner_node.global_position + initial_position
激光射出点global_position = (owner_node.global_position + initial_position) + base_position
'''

func _ready() -> void:

	speed = 0
	velocity = Vector2.ZERO
	immortal = false
	life = 10.0
	# segment_texture = allocate_tex(load("res://laser1.png"))
	outlook.hide()
	collision_shape.disabled = true
	hitpoint = 128
	damage = 1
	damage_interval = 4
	from_owner = owner_node
	laser_hitbox.hit.connect(_on_hitbox_hit)
	set_direction(direction)
	if outlook.hframes > 1 or outlook.vframes > 1:
		animation_player.play("laser")

	super._ready() # already global_position = init_position
	initial_position = global_position - owner_node.global_position if owner_node else global_position
	bodies.position = base_position


	# 预初始化对象池
	for _i in range(max_segments):
		var seg = create_segment()
		segment_pool.append(seg)
	if not head_texture:
		head_texture = segment_texture
	if not body_texture:
		body_texture = segment_texture
	if not tail_texture:
		tail_texture = segment_texture
	update_laser()

	bodies.scale = Vector2(1, 0)
	get_tree().create_tween().set_ease(Tween.EASE_IN).tween_property(bodies, "scale", Vector2(1, 1), fade_out_duration)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_following and not owner_node:
		expired()
	update_laser()
	# check_collisions()


func expired(reason: EXPIRE_REASON = EXPIRE_REASON.NULL, print_reason: bool = true) -> Error:
	# print(hitpoint)
	# 渐隐动画
	# var tween = create_tween()
	# await tween.tween_property(self, "modulate:a", 0.0, fade_out_duration).finished
	await get_tree().create_tween().set_ease(Tween.EASE_OUT).tween_property(bodies, "scale", Vector2(1, 0), fade_out_duration).finished
	# tween.tween_callback(super.expired.bind(reason, print_reason))
	super.expired(reason, print_reason)
	return OK


func create_segment() -> Node2D:
	# var seg = Node2D.new()
	var sprite = Sprite2D.new()
	# var collision = CollisionShape2D.new()
	# var area = Area2D.new()
	
	# sprite.texture = segment_texture
	# collision.shape = RectangleShape2D.new()
	# collision.shape.extents = Vector2(segment_length/2, 8)
	
	# seg.add_child(sprite)
	# area.add_child(collision)
	# area.collision_layer = hitbox.collision_layer
	# area.collision_mask = hitbox.collision_mask
	# seg.add_child(area)
	# seg.hide()
	
	# bodies.add_child(seg)
	sprite.hide()
	bodies.add_child(sprite)
	
	return sprite

func update_laser() -> void:
	'''
	到时候把这部分整理一下，在physics_process里只判断is_following时处理即可
	'''

	var ray_length: float = get_raycast_length()
	# var segment_count: int = ceil((ray_length + segment_length/2.) / segment_length)
	# 根据实际纹理宽度动态计算段长度（优先使用身体纹理）
	# var tex_width: float = body_texture.get_width() if body_texture else segment_length
	# segment_length = tex_width if tex_width > 0 else 32.0
	
	# 计算总段数（浮点数）
	var total_segments: float = ray_length / segment_length
	var visible_segments: int = max(ceil(total_segments), 2)  # 确保至少2个段
	laser_collision_shape.shape.size = Vector2(ray_length, 18)
	laser_collision_shape.position = Vector2(ray_length/2, 0)
	ray_cast.target_position = Vector2.RIGHT * (ray_length + 8)
	# update_laser_parts(segment_count)
	update_laser_parts(visible_segments, total_segments)

	if not is_following or not owner_node:
		'''
		无owner_node，则激光固定在初始位置。
		global_position始终不变
		'''
		# base_position = global_position + bias_position
		base_position = global_position
		return

	# 更新发射起点
	'''
	若有owner_node，则激光跟随owner_node。
	则base_position设定后_基本不变_，
	global_position = owner_node.global_position + initial_position实现移动跟随
	'''
	global_position = owner_node.global_position + initial_position
	if Input.is_action_pressed("Range"):
		direction = (get_global_mouse_position() - bodies.global_position).normalized()
	elif Input.is_action_just_released("Range"):
		expired()
		pass

	# global_position = base_position
	bodies.position = base_position

	var angle = base_position.angle_to_point(get_local_mouse_position())
	set_direction(Vector2.from_angle(angle))

func update_laser_parts(visible_segments: int, total_segments: float) -> void:
	# 计算最小需要段数（当总长度超过1个段时强制添加中间段）
	var min_segments = 2 if total_segments >= 1.0 else 1
	min_segments = 3 if (total_segments > 1.0 and visible_segments == 1) else min_segments
	var target_segments = max(visible_segments, min_segments)
	
	# 回收多余段
	if active_segments.size() > target_segments:
		for i in range(target_segments, active_segments.size()):
			var seg = active_segments[i]
			seg.hide()
			segment_pool.append(seg)
		active_segments.resize(target_segments)
	
	# 复用对象池
	for i in range(active_segments.size(), target_segments):
		active_segments.append(segment_pool.pop_back() if not segment_pool.is_empty() else create_segment())
	
	# 更新所有段
	for i in range(active_segments.size()):
		var seg = active_segments[i] as Sprite2D
		
		if i == active_segments.size() - 1:  # 头部
			if not update_laser_part_outlook(seg, "head"):
				seg.texture = head_texture
			seg.position = Vector2.RIGHT * (total_segments * segment_length)
			seg.scale = Vector2(1, 1)
		elif i == 0:  # 尾部
			if not update_laser_part_outlook(seg, "tail"):
				seg.texture = tail_texture
			if active_segments.size() <= 2:
				# var full_segments = floor(total_segments)
				var fraction = max(total_segments - 1.0, 0.0)
				seg.position = Vector2.RIGHT * fraction * segment_length
				seg.scale = Vector2(1 + fraction * 2, 1)
			else:
				seg.position = Vector2.ZERO + Vector2.RIGHT * (segment_length / 2.)
				seg.scale = Vector2(1, 1)
		else:  # 身体段
			if not update_laser_part_outlook(seg, "body"):
				seg.texture = body_texture
			# 处理最后一个完整身体段的缩放
			if i == active_segments.size() - 2:
				var full_segments = floor(total_segments)
				var fraction = total_segments - full_segments
				seg.position = Vector2.RIGHT * ((full_segments - 1) * segment_length + fraction * segment_length)
				seg.scale = Vector2(1 + fraction, 1)  # 向右延伸缩放
				# print("full_segments: ", full_segments, "fraction: ", fraction, "seg.position: ", seg.position, "seg.scale: ", seg.scale)
			else:
				seg.position = Vector2.RIGHT * ((i + .5) * segment_length)
				seg.scale = Vector2(1, 1)
		
		seg.show()

func update_laser_part_outlook(seg: Sprite2D, seg_type: String) -> bool:
	"""
	更新激光段外观 | 也可以用Sprite2D.frame_changed信号连接
	"""
	# var head_region: Rect2
	# var body_region: Rect2
	# var tail_region: Rect2

	# if head_texture and head_texture is AtlasTexture:
	# 	head_region = head_texture.region
	# if body_texture and body_texture is AtlasTexture:
	# 	body_region = body_texture.region
	# if tail_texture and tail_texture is AtlasTexture:
	# 	tail_region = tail_texture.region
	
	# if seg_type == "head" and head_region:
	# 	seg.region_rect = head_region
	# elif seg_type == "body" and body_region:
	# 	seg.region_rect = body_region
	# elif seg_type == "tail" and tail_region:
	# 	seg.region_rect = tail_region

	# if head_texture and body_texture and tail_texture:
	
	if outlook.texture and outlook.hframes == 3:
		seg.texture = outlook.texture
		seg.hframes = outlook.hframes
		seg.vframes = outlook.vframes
		seg.frame_coords.y = outlook.frame_coords.y
		match seg_type:
			"tail":
				seg.frame_coords.x = 0
			"body":
				seg.frame_coords.x = 1
			"head":
				seg.frame_coords.x = 2
		# print("seg.frame_coords: ", seg.frame_coords)
		return true
	return false

func get_raycast_length() -> float:
	# 从基点发射射线
	ray_cast.target_position = Vector2.RIGHT * max_length
	ray_cast.force_raycast_update()
	return ray_cast.global_position.distance_to(ray_cast.get_collision_point()) if ray_cast.is_colliding() else max_length

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	# 更新射线方向
	# ray_cast.target_position = initial_direction * max_length
	bodies.rotation = direction.angle()

func _on_hitbox_hit(_hurtbox: Variant) -> void:
	laser_hitbox.damage = Damage.new(damage, from_owner if from_owner else self, damage_interval)
	hitpoint -= 1

func is_outscreen() -> bool:
	'''
	更改一下判断逻辑 | 激光射线超出屏幕范围时，返回true
	'''
	return super.is_outscreen()
	

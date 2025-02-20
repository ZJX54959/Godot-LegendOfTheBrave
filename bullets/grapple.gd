extends Bullet

@export var segment_count := 6

@export_category("Swing Physics")
@export var swing_stiffness: float = 0.6    # 横向摆动刚度 (0-1)
@export var vertical_bounce: float = 0.4   # 垂直弹跳系数 
@export var air_resistance: float = 0.98   # 空中阻力
@export var swing_acceleration: float = 8.0 # 摆动加速度

@export_category("Rope Physics")
@export var max_distance := 384.0
@export var pull_force := 400.0
@export var pull_distance := 128.0
@export var stiffness: float = 2.4    # 垂直弹性
@export var damping: float = 0.2       
@export var sag_factor := 0.2  
@export var tension_threshold := 10.0
# @export var slack_distance := 24.0

@onready var ray_cast: RayCast2D = $RayCast2D
# @onready var break_particles: GPUParticles2D = $Particles

var expiring := false
var hooked := false
var owner_node: Node2D  # 玩家角色
var joint: PinJoint2D
var line: Line2D

func _ready():
	super._ready()
	type = "Grapple"
	line = Line2D.new()
	line.width = 1.0
	line.default_color = Color.BLUE_VIOLET
	get_parent().add_child(line)
	allocate_tex(load("res://assets/2085.png"))
	
	# 设置碰撞检测
	#collision_mask = 2  # 只检测地形层
	gravity = false
	immortal = true

func _physics_process(delta):
	if expiring:
		return
	if is_queued_for_deletion():
		expiring = true
	if owner_node and not is_instance_valid(owner_node):
		expired(Bullet.EXPIRE_REASON.INVALID_OWNER, true)
		return
	if hooked and is_instance_valid(owner_node):
		var distance = global_position.distance_to(owner_node.global_position + Vector2(0, -16))
		var dir = (global_position - owner_node.global_position + Vector2(0, -16)).normalized()
		
		# 计算拉力（当距离超过max_distance时生效）
		if distance > pull_distance:
			var excess = distance - pull_distance
			owner_node.velocity += F(dir, excess)
			# if hooked and owner_node.velocity.length() < 1. or true:
			# 	print(F(dir, excess), owner_node.velocity)
		
		# 更新绳索显示（根据距离调整颜色）
		update_rope_visual(distance)
		
		# 检测slide按键直接断开
		if Input.is_action_just_pressed("slide"):
			owner_node.hooked = false
			expired(Bullet.EXPIRE_REASON.ACTIVE_CANCEL, true)
		
		if Input.is_action_just_pressed("pull"):
			owner_node.velocity += F(dir, 16) * 3

	else:
		super._physics_process(delta)
		ray_cast.force_raycast_update()
		if ray_cast.is_colliding() and owner_node and is_instance_valid(owner_node):
			hooked = true
			owner_node.hooked = true
			velocity = Vector2.ZERO
			_create_joint()
			$Particles.emitting = true
	
	if owner_node and not expiring and is_instance_valid(owner_node) and global_position.distance_to(owner_node.global_position + Vector2(0, -16)) > max_distance * 1.:
		expired(Bullet.EXPIRE_REASON.OUT_OF_RANGE, true)

# func _on_hitbox_hit(hurtbox):
# 	if not hooked and (hurtbox.collision_layer == 1 or true):  # 碰撞到地形
# 		hooked = true
# 		velocity = Vector2.ZERO
# 		_create_joint()
# 		$Particles.emitting = false

func update_rope_visual(distance: float):
	if expiring:
		return
	line.default_color = Color.ORANGE_RED if distance > pull_distance * 1.2 else Color.BLUE_VIOLET
	# line.points = [owner_node.global_position + Vector2(0, -16), global_position]
	var start_pos = owner_node.global_position - Vector2(0, 16)
	var end_pos = global_position
	# var mid_point = (start_pos + end_pos) / 2
	
	# 计算下垂偏移量（基于距离和重力）
	var current_sag = Vector2.ZERO
	var excess = max(distance - pull_distance, 0.0)
	
	if excess < tension_threshold:
		# 当拉力小于阈值时保持下垂
		current_sag = Vector2.DOWN * distance * sag_factor * (1.0 - excess/tension_threshold)
	
	# 生成贝塞尔曲线点
	var curve_points = []
	for i in range(segment_count + 1):
		var t = float(i) / segment_count
		var point = start_pos.lerp(end_pos, t)
		# 使用二次贝塞尔曲线公式添加下垂
		point += current_sag * sin(t * PI)
		curve_points.append(point)
	
	line.points = curve_points

func _create_joint():
	# 创建物理关节
	joint = PinJoint2D.new()
	joint.node_a = owner_node.get_path()
	joint.node_b = get_path()
	joint.disable_collision = true
	get_parent().add_child(joint)

func F(dir: Vector2, excess: float) -> Vector2:
	excess = clamp(excess, 0.0, 16.0)
	var force = 2.5 if Input.is_action_pressed("pull") else 1.
	var spring_force = dir * stiffness * excess
	var relative_vel = owner_node.velocity - velocity
	var damping_force = -damping * relative_vel.dot(dir) * dir
	var total_force = spring_force + damping_force
	return total_force * log(excess * pull_force + 1.0) * 0.2 * force

func expired(_reason: Bullet.EXPIRE_REASON = Bullet.EXPIRE_REASON.NULL, _print_reason: bool = true):
	expiring = true
	if owner_node and is_instance_valid(owner_node) and owner_node.active_grapples.has(self):
		# print("owner_node.active_grapples.erase(%s)" % self)
		owner_node.active_grapples.erase(self)
		if owner_node.active_grapples.size() <= 0:
			owner_node.hooked = false
			
		owner_node = null
	if joint:
		joint.queue_free()
		# joint.call_deferred("free")  # 延迟释放
		# get_parent().call_deferred("remove_child", joint)
		joint = null
	if line:
		line.queue_free()
		# line.call_deferred("free")
		# line.get_parent().remove_child(line)
		line = null
	if $Particles:
		$Particles.emitting = false
	if $Hitbox.hit.is_connected(_on_hitbox_hit):
		$Hitbox.hit.disconnect(_on_hitbox_hit)
	super.expired(_reason, _print_reason)
	#print("super.expired")
	# queue_free()
	call_deferred("free")

func exceed_max_capacity():
	# print("exceed_max_capacity")
	# var break_particles = $Particles.duplicate()
	# break_particles.emitting = true
	# break_particles.global_position = global_position
	# add_child(break_particles)
	# break_particles.finished.connect(break_particles.queue_free)
	expired(Bullet.EXPIRE_REASON.EXCEED_LIMIT, true)
	# for child in get_children():
	# 	child.free()
	# free()

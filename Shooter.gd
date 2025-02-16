class_name Shooter
extends Node

# 预定义常用子弹类型
const BULLET := preload("res://bullet.tscn")
const ARROW := preload("res://bullets/arrow.tscn")
# const LIGHTNING := preload("res://bullets/lightning.tscn")

enum SHOOT_PATTERN {
	NONE = -1,
	SINGLE,
	RANDOM,
	FLOWER,
	WINDER,
}

# 发射模式接口
class ShootingPattern:
	func execute(shooter: Shooter, config: ShootConfig): pass

# 基础发射配置
class ShootConfig:
	var bullet_scene: PackedScene
	var position: Vector2
	var direction := Vector2.ZERO
	var speed := 150.0
	var life := 10.0
	var scale := Vector2.ONE
	var homing := false
	var aim: Node2D = null
	var knockback_dir: Vector2 = Vector2.ZERO
	var knockback_force: float = 0
	var ways: int = 1
	var spread_angle: float = 1
	var custom_config: Callable = func(_b): pass
	var custom_config_before_ready: Callable = func(_b): pass
	func _init(
		bullet: PackedScene,
		pos: Vector2,
		dir: Vector2 = Vector2.ZERO,
		spd: float = 150.0,
		lf: float = 10.0
	):
		bullet_scene = bullet
		position = pos
		direction = dir
		speed = spd
		life = lf
	
	func duplicate() -> ShootConfig:
		var config = ShootConfig.new(bullet_scene, position, direction, speed, life)
		config.scale = scale
		config.homing = homing
		config.aim = aim
		config.custom_config = custom_config
		config.ways = ways
		config.spread_angle = spread_angle
		config.bullet_scene = bullet_scene
		config.position = position
		config.direction = direction
		config.speed = speed
		config.life = life
		return config

	func with_rotation(angle: float) -> ShootConfig:
		direction = direction.rotated(angle)
		return self

	func with_speed(spd: float) -> ShootConfig:
		speed = spd
		return self
	
	func with_homing(aim_node: Node2D) -> ShootConfig:
		homing = true
		aim = aim_node
		return self
	
	func with_scale(new_scale: Vector2) -> ShootConfig:
		scale = new_scale
		return self
	
	func with_knockback(dir: Vector2, force: float) -> ShootConfig:
		knockback_dir = dir
		knockback_force = force
		return self
	
	func with_ways(way_count: int) -> ShootConfig:
		ways = way_count
		return self
	
	func with_custom_config(callback: Callable) -> ShootConfig:
		custom_config = callback
		return self
	
	func with_custom_config_before_ready(callback: Callable) -> ShootConfig:
		custom_config_before_ready = callback
		return self

# 具体发射模式实现
class SinglePattern extends ShootingPattern:
	func execute(shooter: Shooter, config: ShootConfig) -> Bullet:
		return shooter._create_bullet(config)

class FlowerPattern extends ShootingPattern:
	# var ways: int

	# func _init(way_count: int):
	# 	ways = way_count

	func execute(shooter: Shooter, config: ShootConfig) -> Array[Bullet]:
		var b_array: Array[Bullet] = []
		for i in range(config.ways):
			var angle = TAU * i / config.ways
			b_array.append(shooter._create_bullet(config.duplicate().with_rotation(angle)))
		return b_array

class RandomPattern extends ShootingPattern:
	# var spread_angle: float
	# var ways: int

	# func _init(angle: float, way_count: int):
	# 	spread_angle = deg_to_rad(angle)
	# 	ways = way_count

	func execute(shooter: Shooter, config: ShootConfig) -> Array[Bullet]:
		var b_array: Array[Bullet] = []
		for i in range(config.ways):
			var angle = randf_range(-config.spread_angle/2, config.spread_angle/2)
			var modified_speed = config.speed * randf_range(0.8, 1.2)
			b_array.append(shooter._create_bullet(config.duplicate()
				.with_rotation(angle)
				.with_speed(modified_speed)))
		return b_array

# 建造者接口
func shooter_config(bullet_scene: PackedScene, position: Vector2 = owner.global_position if owner else Vector2.ZERO, direction: Vector2 = Vector2.RIGHT) -> ShootConfig:
	#var owner_pos = owner.global_position if owner else Vector2.ZERO
	return ShootConfig.new(bullet_scene, position, direction)

func shoot(config: ShootConfig, pattern: SHOOT_PATTERN):
	if pattern < 0 or not pattern is SHOOT_PATTERN:
		pattern = SHOOT_PATTERN.NONE
		return FAILED
	match pattern:
		SHOOT_PATTERN.SINGLE:
			var p = SinglePattern.new()
			return p.execute(self, config)
		SHOOT_PATTERN.RANDOM:
			var p = RandomPattern.new()
			return p.execute(self, config)
		SHOOT_PATTERN.FLOWER:
			var p = FlowerPattern.new()
			return p.execute(self, config)
		_:
			return FAILED

	# return OK

func _create_bullet(config: ShootConfig) -> Bullet:
	var bullet = config.bullet_scene.instantiate()
	
	bullet.init_position = config.position
	bullet.velocity = config.direction.normalized()
	bullet.speed = config.speed
	bullet.life = config.life
	bullet.scale = config.scale
	bullet.homing = config.homing
	bullet.aim = config.aim
	bullet.knockback_force = config.knockback_force

	if config.knockback_dir.length() > 0:
		bullet.knockback_dir = config.knockback_dir
		bullet.auto_knockback = false
	
	if config.custom_config_before_ready.is_valid():
		config.custom_config_before_ready.call(bullet)

	get_tree().root.add_child(bullet)

	# 应用自定义配置
	if config.custom_config.is_valid():
		config.custom_config.call(bullet)

	return bullet

# ShootConfig 扩展方法
# func ShootConfig.with_rotation(angle: float) -> ShootConfig:
#     direction = direction.rotated(angle)
#     return self

# func ShootConfig.with_speed(new_speed: float) -> ShootConfig:
#     speed = new_speed
#     return self

# func ShootConfig.with_homing(target: Node2D) -> ShootConfig:
#     homing = true
#     aim = target
#     return self

# func ShootConfig.with_scale(new_scale: Vector2) -> ShootConfig:
#     scale = new_scale
#     return self

# func ShootConfig.with_custom_config(callback: Callable) -> ShootConfig:
#     custom_config = callback
#     return self
'''
# 简单发射
shoot(Bullet, position)
	.with_rotation(PI/4)
	.with_speed(200)
	.with_custom_config(func(b):
		b.damage = 2
		b.auto_align = false
	)

# 花朵样式发射
var flower_config = shoot(Arrow, position)
	.with_scale(Vector2(0.8, 0.8))
	.with_homing(enemy)

flower_config.custom_config = func(b): 
	b.gravity_scale = 0.5

FlowerPattern.new(8).execute(self, flower_config)

# 随机散射
RandomPattern.new(45.0, 5).execute(self, 
	shoot(Lightning, position)
		.with_speed(180)
		.with_custom_config(func(b):
			b.immortal = true
		)
)
'''

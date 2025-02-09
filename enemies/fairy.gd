extends Enemy

enum State {
	HOVER,
	MOVE,
	TRACK,
	ATTACK,
	HURT,
	DYING,
}

const KNOCKBACK_AMOUNT := 100.0
const TRACK_SPEED := 120.0
const LOST_TIME := 2.0
const BULLET_SPEED := 180.0
const MOVE_SPEED := 80.0
const CHECKER_DISTANCE := 512.0


@export var fairy_bullet: PackedScene = preload("res://bullets/star.tscn")

@onready var shooter: Shooter = $Shooter
@onready var attack_timer: Timer = $AttackTimer
@onready var hitbox: Hitbox = $Graphics/Hitbox
@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var player_checker_2: RayCast2D = $Graphics/PlayerChecker2
@onready var player_checker_3: RayCast2D = $Graphics/PlayerChecker3
# @onready var wall_checker: RayCast2D = $WallChecker
# @onready var player_checker: RayCast2D = $PlayerChecker
@onready var player_checkers: Array[RayCast2D] = [
	player_checker,
	player_checker_2,
	player_checker_3,
]

var attack_pattern := Shooter.SHOOT_PATTERN.FLOWER
var pending_damages: Array[Damage] = []
var last_known_position: Vector2
var lost_timer: float = 0.0
var dir: Vector2 = Vector2.RIGHT



func _ready() -> void:
	super._ready()
	attack_timer.start(randf_range(1.5, 3.0))
	# motion_mode = MotionMode.MOTION_MODE_FLOATING

func tick_physics(state: State, delta: float) -> void:

	if wall_checker.is_colliding():
		dir = dir.bounce(wall_checker.get_collision_normal())
		update_checker_direction()

	match state:
		State.HOVER:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
			move_and_slide()
			#move_and_collide(velocity * delta)
		
		State.MOVE:
			# 随机方向漂浮（二维移动）
			if state_machine.state_time > randf_range(5.5, 65.5):
				dir = Vector2(randf_range(-1, 1), randf_range(-0.5, 0.5)).normalized()
				update_checker_direction()
			move(MOVE_SPEED, delta)
		
		State.TRACK:
			# 持续更新玩家位置
			if can_see_player():
				last_known_position = player_checker.get_collision_point()
				dir = (last_known_position - global_position).normalized()
				lost_timer = 0.0  # 重置丢失计时器
				update_checker_direction()
			else:
				# 平滑转向最后已知位置
				var target_dir = (last_known_position - global_position).normalized()
				dir = dir.lerp(target_dir, delta * 4)  # 增加转向平滑
				update_checker_direction()
				
				# 定期随机扫描
				if state_machine.state_time - floor(state_machine.state_time) < 0.5:
					player_checker.rotation = randf_range(-PI/4, PI/4)
				
				# 障碍物回避
				if wall_checker.is_colliding():
					var normal = wall_checker.get_collision_normal()
					dir = dir.bounce(normal).rotated(randf_range(-PI/8, PI/8))
					update_checker_direction()
				
				# 接近目标后重新评估
				if global_position.distance_to(last_known_position) < 64.0:
					if can_see_player():
						state_machine.transition_to(State.ATTACK)
					else:
						lost_timer += delta * 2  # 加速丢失计时
		
		State.ATTACK:
			# 攻击时短暂悬停
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
			move_and_slide()
		
		State.HURT, State.DYING:
			move(0.0, delta)

func get_next_state(state: State) -> int:
	if stats.health <= 0:
		return State.DYING if state != State.DYING else StateMachine.KEEP_CURRENT
	
	# if pending_damage:
	# 	return State.HURT
	if not pending_damages.is_empty():
		return State.HURT
	
	# 玩家检测优先
	# if can_see_player():
	# 	if state in [State.MOVE, State.HOVER]:
	# 		return State.TRACK
	# elif state == State.TRACK:
	# 	lost_timer += get_process_delta_time()
	# 	if lost_timer > LOST_TIME:
	# 		lost_timer = 0.0
	# 		return State.MOVE
	
	match state:
		State.HOVER:
			if can_see_player():
				return State.TRACK
			if state_machine.state_time > 0.5:
				return State.MOVE
		
		State.MOVE:
			if can_see_player():
				return State.TRACK
			if attack_timer.is_stopped():
				return State.ATTACK
			if not can_see_player() and state_machine.state_time > randf_range(15, 200):
				return State.HOVER
		
		State.ATTACK:
			if not animation_player.is_playing():
				attack_timer.start(randf_range(2.0, 4.0))
				return State.MOVE
		
		State.TRACK:
			if global_position.distance_to(last_known_position) < 64.0:
				return State.ATTACK
			lost_timer += get_process_delta_time()
			if lost_timer > LOST_TIME:
				lost_timer = 0.0
				return State.MOVE

		State.HURT:
			if not animation_player.is_playing():
				return State.MOVE
	
	return StateMachine.KEEP_CURRENT

func transition_state(from: State, to: State) -> void:

	if from == State.TRACK:
		player_checker.rotation = 0

	match to:
		State.TRACK:
			animation_player.play("alert")
			last_known_position = player_checker.get_collision_point()
			update_checker_direction()
		
		State.MOVE:
			animation_player.play("hover")
			hitbox.damage = Damage.new(1, self)
		State.HOVER:
			animation_player.play("hover")
			hitbox.damage = Damage.new(.2, self)
		
		State.ATTACK:
			animation_player.play("attack")
			# 使用flower pattern发射8方向子弹
			var config = shooter.shooter_config(
				fairy_bullet, 
				global_position, 
				Vector2.RIGHT
				).with_speed(BULLET_SPEED).with_scale(Vector2(0.6, 0.6)).with_ways(8+randi_range(0, 2)).with_custom_config(
					func(bullet): 
						#bullet.life = 1.5
						bullet.hitbox.set_collision_mask_value(8, false)
						bullet.hitbox.set_collision_mask_value(7, true)
						#bullet.allocate_tex.call(load("res://fairy1.png"))
						bullet.scale *= 0.4
						)
			
			print(shooter.shoot(config, Shooter.SHOOT_PATTERN.FLOWER))
			await get_tree().create_timer(0.2).timeout
			print(shooter.shoot(config.with_rotation(randf_range(0, PI/3.)), Shooter.SHOOT_PATTERN.FLOWER))
			attack_timer.wait_time = randf_range(2.0, 4.0)
		
		State.HURT:
			animation_player.play("hit")
			# hitstop(0)
			# stats.health -= pending_damage.amount
			var total_damage := 0.
			var knockback_dir := Vector2.ZERO
			for dmg in pending_damages:
				total_damage += dmg.amount
				knockback_dir += dmg.source.global_position.direction_to(global_position)
			
			stats.health -= int(total_damage)
			velocity = knockback_dir.normalized() * KNOCKBACK_AMOUNT
			pending_damages.clear()
			update_checker_direction()
		
		State.DYING:
			animation_player.play("die")
			# hitbox.set_deferred("monitoring", 
			hitbox.monitoring = false
			hurtbox.monitorable = false

func _on_attack_timer_timeout() -> void:
	state_machine.transition_to(State.ATTACK)

func update_checker_direction() -> void:
	# 防止方向归零
	if dir.is_zero_approx():
		dir = Vector2.RIGHT.rotated(randf_range(0, TAU))
	
	# 新增防卡死随机偏移
	if wall_checker.is_colliding() and randf() < 0.3:
		dir = dir.rotated(randf_range(-PI/4, PI/4))
	
	# 根据水平方向更新父类direction（控制图形翻转）
	direction = Direction.LEFT if dir.x < 0 else Direction.RIGHT
	
	# 更新检测器方向（需考虑图形翻转后的坐标系）
	var graphics_scale = graphics.scale.x
	player_checker.target_position = dir.normalized() * CHECKER_DISTANCE * Vector2(-graphics_scale, 1)
	wall_checker.target_position.x = sign(dir.normalized()).x * 72.0 * -graphics_scale

func move(speed: float, delta: float) -> void:
	# 支持任意方向移动（已覆写重力）
	velocity = velocity.move_toward(Vector2(-dir.x, dir.y) * speed, acceleration * delta)
	# move_and_bounce(delta)
	move_and_slide()

# func move_and_bounce(delta: float) -> void:
# 	var wall: KinematicCollision2D = move_and_collide(velocity * delta)
# 	if wall:
# 		velocity = velocity.bounce(wall.get_normal())
		
		
# 	pass

func can_see_player() -> bool:
	var result := false
	var colliding := false
	for checker in player_checkers:
		# print(checker)
		if not checker:
			continue
		colliding = colliding or checker.is_colliding()
		result = result or (checker.is_colliding() and checker.get_collider() is Player)
		# print(colliding, result)
	# if result:
		# print("can see player")
	return result


func _on_hurtbox_hurt(hitbox: Variant, damage: Variant) -> void:
	if handle_damage(damage):
		# pending_damage = damage
		# state_machine.transition_to(State.HURT)
		pending_damages.append(damage)

func _on_hitbox_hit(hurtbox: Variant) -> void:
	dir = global_position.direction_to(hurtbox.global_position)
	update_checker_direction()
	pass # Replace with function body.

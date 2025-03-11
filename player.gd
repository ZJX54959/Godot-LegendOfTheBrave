class_name Player
extends CharacterBody2D

enum Direction {
	LEFT = -1,
	RIGHT = +1,
}

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALLING,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3,
	ATTACK_COMBO,
	HURT,
	DYING,
	SLIDING_START,
	SLIDING_LOOP,
	SLIDING_END,
}

const GROUND_STATES := [
	State.IDLE, State.RUNNING, State.LANDING,
	State.ATTACK_1, State.ATTACK_2, State.ATTACK_3,
	State.SLIDING_START, State.SLIDING_LOOP, State.SLIDING_END,
]
const ATTACK_STATES := [
	State.ATTACK_1, State.ATTACK_2, State.ATTACK_3
]
const INACTIVE_STATES := [
	# 不可操作的状态
	State.SLIDING_START, State.SLIDING_LOOP, State.SLIDING_END,
	State.HURT, State.DYING
]
const ANTI_KNOCKBACK_STATES := [
	# 不受到击退的状态\霸体状态
	State.ATTACK_3
]
const RUN_SPEED := 160.0
const JUMP_VELOCITY := -320.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
const AIR_ACCELERATION := RUN_SPEED / 0.1
const SWING_ACCELERATION := RUN_SPEED / 10.
const WALL_JUMP_VELOCITY := Vector2(380, -280)
const WALL_JUMP_ENERGY := 1.0
const KNOCKBACK_AMOUNT := 512.0
const SLIDING_DURATION := 0.5
const SLIDING_SPEED := 256.0
const SLIDING_ENERGY := 4.0
const LANDING_HEIGHT := 100.0
const MAX_GRAPPLES = 3
const MAX_HEALTH := 100

@export var can_combo := false
@export var can_cancel := false # <-- Todo
@export var direction := Direction.RIGHT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = direction

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick := false
var last_wall_normal := Vector2(NAN, NAN)
var is_combo_requested := false
var pending_damages: Array[Damage] = []
var fall_from_y: float 
var aimdir: Vector2
var can_air_attack := false
# var direction := Input.get_axis("move_left", "move_right")
# var slide_dir := direction
var active_grapples: Array[Bullet] = []
var hooked := false
var interacting_with: Array[Interactable]

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var slide_request_timer: Timer = $SlideRequestTimer
@onready var attack_request_timer: Timer = $AttackRequestTimer
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var charge_hold_timer: Timer = $ChargeHoldTimer
@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var front_wall_checker: RayCast2D = $Graphics/FrontWallChecker
@onready var back_wall_checker: RayCast2D = $Graphics/BackWallChecker
@onready var state_machine: StateMachine = $StateMachine
@onready var input_buffer: InputBuffer = $InputBuffer
@onready var stats: Stats = Game.player_stats
@onready var shooter: Shooter = $Shooter
@onready var wave: Sprite2D = $Wave
@onready var hitbox: Hitbox = $Graphics/Hitbox
@onready var interaction_action: AnimatedSprite2D = $InteractionAction


@export_category("bullets")
@export var b_LASER: PackedScene = preload("res://bullets/laser.tscn")
@export var b_ARROW: PackedScene = preload("res://bullets/arrow.tscn")
@export var b_GRAPPLING_HOOK: PackedScene = preload("res://bullets/grapple.tscn")
@export var b_LIGHTNING: PackedScene = preload("res://bullets/lightning.tscn")

'''
主要逻辑
'''
func _unhandled_input(event: InputEvent) -> void:
	# 统一处理所有输入事件
	input_buffer.record_input(event)

	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	
	# 特殊处理：短跳（松开跳跃键时减少跳跃高度）
	if event.is_action_released("jump") and velocity.y < JUMP_VELOCITY/2:
		velocity.y = JUMP_VELOCITY/2
	
	# if Input.is_action_just_pressed("slide"):
	# 	# _clear_all_grapples()
	# 	hooked = false

	if event.is_action_pressed("interact") and interacting_with:
		interacting_with.back().interact(self)


func tick_physics(state:State, delta: float) -> void:
	interaction_action.visible = not interacting_with.is_empty()

	if not get_tree().get_nodes_in_group("Enemy").is_empty():
		aimdir = get_tree().get_nodes_in_group("Enemy").pick_random().global_position-global_position
	else: aimdir = Vector2.RIGHT if direction > 0 else Vector2.LEFT
	if invincible_timer.time_left > 0:
		graphics.modulate.a = 0.5 * sin(Time.get_ticks_msec()) + 0.5
	else:
		graphics.modulate.a = 1
	# if not state_machine.current_state in INACTIVE_STATES:
	# 	direction = Input.get_axis("move_left", "move_right")
	# if not is_zero_approx(direction):
	# 	graphics.scale.x = -1 if direction<0 else 1


	match state:
		State.IDLE:
			# if _check_slide_command(): 
			# 	print("___+++___")
			# 	slide_request_timer.start()
			move(default_gravity, delta)
		
		State.RUNNING:
			# if _check_slide_command(): 
			# 	print("+++___+++")
			# 	slide_request_timer.start()
			move(default_gravity, delta)
		
		State.JUMP:
			move(0.0 if is_first_tick else default_gravity, delta)
		
		State.FALLING:
			move(default_gravity, delta)
		
		State.LANDING:
			stand(default_gravity, delta)
		
		State.WALL_SLIDING:
			move(default_gravity/4, delta, Vector2(velocity.x, velocity.y /10)  if is_first_tick else Vector2.INF)
			direction = wall_normal().x
		
		State.WALL_JUMP:
			if state_machine.state_time < 0.1:
				stand(0.0 if is_first_tick else default_gravity, delta)
				graphics.scale.x = wall_normal().x
			else:
				move(default_gravity, delta)
		
		State.ATTACK_1, State.ATTACK_2, State.ATTACK_3, State.ATTACK_COMBO:
			stand(default_gravity, delta)
		
		State.HURT, State.DYING:
			graphics.modulate.s = clampf(1 - 4 * state_machine.state_time, 0, 1) if state_machine.state_time < 1 else 0.0
			stand(default_gravity, delta)
		
		State.SLIDING_END:
			stand(default_gravity, delta)
		
		State.SLIDING_START, State.SLIDING_LOOP:
			slide(delta)
		
		_:
			push_warning("tick_physics() State Error: State %d" % state)
	
	is_first_tick = false


func get_next_state(state: State) -> int:
	if stats.health <= 0:
		return State.DYING if not state == State.DYING else state_machine.KEEP_CURRENT
	
	if not pending_damages.is_empty():
		handle_damage(state in ANTI_KNOCKBACK_STATES)
		if not state in ANTI_KNOCKBACK_STATES:
			return State.HURT
	
	var input := _get_current_input_state()
	var is_still: bool = Input.get_axis("move_left", "move_right") == 0

	if input.dp:
		return State.ATTACK_3
	elif input.qcf:
		return State.ATTACK_COMBO
	
	# 地面状态通用检测
	if state in GROUND_STATES and not is_on_floor():
		return State.FALLING
	
	# 状态专用转换逻辑
	match state:
		State.IDLE:
			if input.slide:
				return State.SLIDING_START
			if input.jump:
				return State.JUMP
			if input.attack:
				print("IDLE input.attack!")
				return State.ATTACK_1
				# return _get_attack_transition(state)
			if not is_still:
				return State.RUNNING
		
		State.RUNNING:
			if input.slide:
				return State.SLIDING_START
			if input.jump:
				return State.JUMP
			if input.attack:
				print("RUNNING input.attack!")
				return State.ATTACK_1
			if is_still:
				# print("is_still! move_dir:", input.move_dir, "axis: ", Input.get_axis("move_left", "move_right"))
				return State.IDLE
		
		State.JUMP, State.WALL_JUMP:
			if velocity.y >= 0:
				return State.FALLING
		
		State.FALLING:
			if is_on_floor():
				return State.LANDING if abs(global_position.y - fall_from_y) > LANDING_HEIGHT else State.IDLE
			if can_wall_slide():
				return State.WALL_SLIDING
			if input.jump:
				return State.JUMP
		
		State.LANDING:
			if not animation_player.is_playing():
				return State.IDLE
			if not is_still:
				return State.RUNNING
		
		State.WALL_SLIDING:
			if input.jump:
				return State.WALL_JUMP
			if is_on_floor():
				return State.IDLE
			if not on_wall():
				return State.FALLING
		
		State.ATTACK_1, State.ATTACK_2, State.ATTACK_3:
			if not animation_player.is_playing():
				return State.IDLE
			if int(input.attack) == State.ATTACK_COMBO and is_combo_requested:
				return State.ATTACK_COMBO
			if input.attack and can_combo:
				return State.ATTACK_2 if state == State.ATTACK_1 else State.ATTACK_3
		
		State.ATTACK_COMBO:
			if not (Input.is_action_pressed("Attack") or Input.is_action_pressed("Range")):
				print("ATTACK_COMBO! ")
				return State.IDLE

		State.HURT:
			if state_machine.state_time > 0.4:
				return State.IDLE if is_on_floor() else State.FALLING
		
		State.SLIDING_START:
			if not animation_player.is_playing():
				return State.SLIDING_LOOP
		
		State.SLIDING_LOOP:
			if input.jump:
				return State.JUMP
			if state_machine.state_time > SLIDING_DURATION:
				return State.SLIDING_END

		State.SLIDING_END:
			if not animation_player.is_playing():
				return State.IDLE
	
	return state_machine.KEEP_CURRENT


func transition_state(from: State, to: State) -> void:
	
	# print("[%s] %s => %s" % [
	# 		Engine.get_physics_frames(),
	# 		State.keys()[from] if from != -1 else "<START>",
	# 		State.keys()[to],
	# 	])
	
	if from not in GROUND_STATES and to in GROUND_STATES:
		coyote_timer.stop()
	
	if from == State.HURT:
		graphics.modulate.s = 0
	
	match to:
		State.IDLE:
			animation_player.play("idle")
		
		State.RUNNING:
			animation_player.play("running")
		
		State.JUMP:
			animation_player.play("jump")
			# var jump_record = input_buffer.get_last_button_record("jump")
			# var hold_factor = clamp(jump_record.duration / 0.3, 0.0, 1.0) if jump_record else 0.0
			velocity.y = JUMP_VELOCITY # * (1.0 - hold_factor * 0.4)
			coyote_timer.stop()
		
		State.FALLING:
			animation_player.play("falling")
			if from in GROUND_STATES:
				coyote_timer.start()
			fall_from_y = global_position.y
		
		State.LANDING:
			animation_player.play("landing")
		
		State.WALL_SLIDING:
			animation_player.play("wall_sliding")
		
		State.WALL_JUMP:
			animation_player.play("jump")
			velocity = WALL_JUMP_VELOCITY
			velocity.x *= wall_normal().x
			stats.energy -= WALL_JUMP_ENERGY
			coyote_timer.stop()
		
		State.ATTACK_1:
			animation_player.play("attack_1")
			#shooter.shoot(shooter.PARTTERN.BULLET, Bullet.BASIC_TYPE.SLASH, 1, Vector2(graphics.scale.x, 0), 0, 1, 1, 1, position+Vector2(graphics.scale.x*16, -18), false, null, Vector2(1, 0.2))
			is_combo_requested = false
			attack_request_timer.stop()
			hitbox.damage = Damage.new(3, self, 10).with_type("slash")
			
		
		State.ATTACK_2:
			animation_player.play("attack_2")
			#shooter.shoot(shooter.PARTTERN.BULLET, Bullet.BASIC_TYPE.SLASH, 1, Vector2(graphics.scale.x, 0), 0, 1, 1, 1, position+Vector2(graphics.scale.x*20, -18), false, null, Vector2(2, 0.4))
			is_combo_requested = false
			attack_request_timer.stop()
			hitbox.damage = Damage.new(3, self, 10).with_type("slash")
		
		State.ATTACK_3:
			animation_player.play("attack_3")
			#shooter.shoot(shooter.PARTTERN.BULLET, Bullet.BASIC_TYPE.SLASH, 1, Vector2(graphics.scale.x, 0), 0, 1, 1, 1, position+Vector2(graphics.scale.x*48, -18), false, null, Vector2(2, -1.5))
			is_combo_requested = false
			attack_request_timer.stop()
			position.x += direction * 5
			hitbox.damage = Damage.new(30, self, 10, 25, Vector2(0, -1)).with_name("DP_attack! ").smash().with_type("slash")
		
		State.ATTACK_COMBO:
			animation_player.play("attack_combo")
			#shooter.shoot(shooter.PARTTERN.BULLET, Bullet.BASIC_TYPE.SLASH, 1, Vector2(graphics.scale.x, graphics.scale.x), 0, 1, 1, 1, position+Vector2(graphics.scale.x*24, -18), false, null, Vector2(2, 0.4))
			is_combo_requested = false
			hitbox.damage = Damage.new(3, self, 6, 60, Vector2(direction, 0)).smash().with_type("slash")
			attack_request_timer.stop()
		
		State.HURT:
			animation_player.play("hurt")
			# --> handle_damage()
			# hitstop()
			
			# var total_knockback := Vector2.ZERO
			# var total_damage := 0.0
			# for dmg in pending_damages:
			# 	total_damage += dmg.amount
			# 	# 计算每个伤害源的击退向量
			# 	var dir = dmg.knockback_dir if not dmg.knockback_dir.is_zero_approx() else \
			# 		(global_position - dmg.source.global_position).normalized()
			# 	total_knockback += dir * dmg.knockback_force
			
			# stats.health -= int(total_damage)
			# velocity = total_knockback * KNOCKBACK_AMOUNT
			# pending_damages.clear()
			
			# invincible_timer.start()
			graphics.modulate.s = 1
		
		State.DYING:
			animation_player.play("die")
			hitstop(1)
			invincible_timer.stop()
			interacting_with.clear()
		
		State.SLIDING_START:
			animation_player.play("sliding_start")
			slide_request_timer.stop()
			# slide_dir = direction if not is_zero_approx(direction) else graphics.scale.x
			stats.energy -= SLIDING_ENERGY
			hitbox.damage = Damage.new(4, self, 1, 15, direction * Vector2.RIGHT).with_name("sliding_start")
		
		State.SLIDING_LOOP:
			animation_player.play("sliding_loop")
			hitbox.damage = Damage.new(3, self, 1, 15, direction * Vector2.RIGHT).with_name("sliding_loop")
		
		State.SLIDING_END:
			animation_player.play("sliding_end")
			hitbox.damage = null
		
		_:
			push_warning("transition_state State Error: State ", to)
	
	#if to == State.WALL_JUMP:
		#Engine.time_scale = 0.3
	#if from == State.WALL_JUMP:
		#Engine.time_scale = 1.0
	
	is_first_tick = true


func _on_hurtbox_hurt(_hitbox: Variant, damage: Damage) -> void:
	if invincible_timer.time_left > 0:
		return
	
	pending_damages.append(damage)
'''
输入检测等
'''
func _get_current_input_state() -> Dictionary:
	var state = {
		"move_dir": input_buffer.get_last_direction(),
		"jump": _check_jump_input(),
		"attack": _check_attack_input(),
		"slide": _check_slide_command(),
		"range_attack": _check_range_attack_input(),
		"dp": _check_dp_command(),
		"dm": _check_dm_command(),
		"hook": _check_hook_input(),
		"qcf": _check_qcf_command(),
	}
	# print("state: ", state)
	# var text := ""
	# for i in state:
	# 	if i != "move_dir":
	# 		text += i + ":" + var_to_str(state[i]) + "|" if state[i] else ""
	# 	else:
	# 		text += var_to_str(state[i]) + "|"
	# print(text)
	return state

func _get_attack_transition(current_state: State) -> int:
	# 连击检测参数
	var combo_timeout := attack_request_timer.time_left > 0
	var can_chain_combo := can_combo and (is_combo_requested or combo_timeout)
	
	# 状态转换逻辑
	match current_state:
		State.ATTACK_1:
			return State.ATTACK_2 if can_chain_combo else State.ATTACK_1
		
		State.ATTACK_2:
			return State.ATTACK_3 if can_chain_combo else State.ATTACK_1
		
		State.ATTACK_3:
			return State.ATTACK_COMBO if can_chain_combo else State.ATTACK_1
		
		State.ATTACK_COMBO:
			if can_air_attack and input_buffer.check_command([{"button": "Attack"}]):
				return State.ATTACK_COMBO
			return State.ATTACK_COMBO if velocity.y < 0 else State.FALLING
		
		_:
			# 新攻击起始
			if is_on_floor():
				attack_request_timer.start()
				return State.ATTACK_1
			elif can_air_attack:
				return State.ATTACK_COMBO
	
	return state_machine.KEEP_CURRENT

func _check_jump_input() -> bool:
	var has_buffer := jump_request_timer.time_left > 0
	var can_jump := is_on_floor() or coyote_timer.time_left > 0 or on_wall()
	# if can_jump:
	# 	print(is_on_floor(), coyote_timer.time_left > 0, on_wall())
	return can_jump and (Input.is_action_just_pressed("jump") or has_buffer) and stats.energy - WALL_JUMP_ENERGY > 0

func _check_attack_input() -> bool:
	# 检测短按攻击（持续时间小于0.2秒）
	if input_buffer.check_command([{"button": "Attack", "max_duration": 0.1}]):
		# attack_request_timer.start()
		# print("attack true")
		return true
	# 检测长按攻击（蓄力攻击）
	# if input_buffer.check_command([{"button": "Attack", "min_duration": 0.5}]):
	# 	return State.ATTACK_COMBO
	return false

func _check_range_attack_input() -> bool:
	# 检测蓄力射击
	var charge_shot = input_buffer.check_command([
		{"button": "Range", "min_duration": 0.5}
	])
	
	# 检测瞬发射击
	var quick_shot = input_buffer.check_command([
		{"button": "Range", "max_duration": 0.3}
	]) and not Input.is_action_pressed("Range")
	
	if charge_shot:
		print("[%s] charge_shot" % Engine.get_physics_frames())
		_fire_charge_shot()
	elif quick_shot:
		_fire_quick_shot()
	
	return charge_shot or quick_shot

func _fire_charge_shot():
	shooter.shoot(
		# shooter.shooter_config(load("res://bullets/lightning.tscn"), get_global_mouse_position()),
		shooter.shooter_config(b_LASER, position + Vector2(direction * 16, -32), get_local_mouse_position()).with_custom_config_before_ready(func(b):
		b.owner_node = self
		# b.initial_position == position + Vector2(graphics.scale.x * 16, -32) # 子弹位置在人物前方
		b.base_position = Vector2.ZERO # 激光射出点在鼠标位置
		b.direction = get_global_mouse_position() - position
		b.is_following = true
		),
		Shooter.SHOOT_PATTERN.SINGLE
	)

func _fire_quick_shot():
	shooter.shoot(
		shooter.shooter_config(b_ARROW, position + Vector2(0, -32), get_local_mouse_position() - Vector2(0, -32))
			.with_speed(350)
			.with_custom_config(func(b):
			b.gravity_velocity = Vector2.DOWN
			b.gravity_scale = 0.6
			),
		Shooter.SHOOT_PATTERN.SINGLE
	)

func _check_dp_command() -> bool:
	return input_buffer.check_command([
		Vector2(direction, 0),
		Vector2.DOWN,
		Vector2(direction, 0) + Vector2.DOWN,
		{"button": "Range", "min_duration": 0.01}
	])# and Input.is_action_just_pressed("Attack")

func _check_qcf_command() -> bool:
	return input_buffer.check_command([
		Vector2.DOWN,
		Vector2(direction, 0) + Vector2.DOWN,
		Vector2(direction, 0),
		{"button": "Range", "min_duration": 0.01}
	])# and Input.is_action_just_pressed("Attack")

func _check_dm_command() -> bool:
	var dm_input = input_buffer.check_command([
		Vector2.DOWN,
		Vector2.DOWN,
		{"button": "Magic", "min_duration": 0.01}
	])
	# if Input.is_action_just_pressed("Magic"):
	# 	print("Magic!")
	if dm_input:
		_fire_charge_shot2()
	return dm_input

func _check_slide_command() -> bool:
	return input_buffer.check_command([
		Vector2(direction, 0) + Vector2.DOWN,
		{"button": "slide", "min_duration": 0.1}
	]) and stats.energy - SLIDING_ENERGY > 0

func _check_hook_input() -> bool:
	var hook_input = input_buffer.check_command([
		{"button": "hook", "max_duration": 0.2}
	])
	if hook_input:
		_fire_grapple()
	return hook_input

func _check_grapple_limit():
	active_grapples = active_grapples.filter(func(g): 
		if not is_instance_valid(g):
			print("发现无效钩爪：", g)
		return is_instance_valid(g))
	while active_grapples.size() > MAX_GRAPPLES:
		var oldest = active_grapples.pop_front()
		oldest.exceed_max_capacity()
		oldest = null
	if active_grapples.size() == 0:
		hooked = false

func _fire_grapple():
	var hook_config = shooter.shooter_config(
		b_GRAPPLING_HOOK,
		position + Vector2(0, -16),  # 发射位置偏移
		get_local_mouse_position() - Vector2(0, -32)  # 发射方向
	).with_speed(600).with_custom_config(func(b):
		b.owner_node = self  # 将玩家自身传递给钩爪
	)
	_check_grapple_limit()
	# add_grapple(hook_config.bullet_scene.instantiate())
	# add_grapple(Node.new() as Bullet)
	var g = shooter.shoot(hook_config, Shooter.SHOOT_PATTERN.SINGLE)
	if g:
		add_grapple(g)
		print(active_grapples)

func _fire_charge_shot2():
	print(shooter.shoot(
		shooter.shooter_config(b_LIGHTNING, get_global_mouse_position()),
		Shooter.SHOOT_PATTERN.SINGLE
	))
	print("fire_charge_shot2")

func add_grapple(grapple: Bullet):
	active_grapples.append(grapple)
	# 超过上限时移除最旧的钩爪
	if active_grapples.size() > MAX_GRAPPLES:
		var oldest = active_grapples.pop_front()
		oldest.exceed_max_capacity()
		oldest = null

# func _clear_all_grapples():
# 	for grapple in active_grapples:
# 		if is_instance_valid(grapple):
# 			grapple.exceed_max_distance()
# 	active_grapples.clear()
# 	hooked = false

'''
状态检测
'''
func wall_normal():
	if front_wall_checker.is_colliding(): last_wall_normal = front_wall_checker.get_collision_normal()
	elif back_wall_checker.is_colliding(): last_wall_normal = back_wall_checker.get_collision_normal()
	if not is_nan(last_wall_normal.x) and not is_nan(last_wall_normal.y): return last_wall_normal
	else:
		push_warning("Return Wall Normal As Vec2.ZERO")
		return Vector2.ZERO
func on_wall() -> bool:
	return front_wall_checker.is_colliding() or back_wall_checker.is_colliding()
func can_wall_slide() -> bool:
	return on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding() and not is_on_floor()

'''
行动逻辑
'''
func move(gravity:float, delta: float, VELinput: Vector2 = Vector2.INF) -> void:#此处可以enum MoveMode后把Movemode也作为参数传入来代替is_finite的判断，扩展性更强 
	# var direction := Input.get_axis("move_left", "move_right")
	var movement_dir := Input.get_axis("move_left", "move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else (AIR_ACCELERATION if not hooked else SWING_ACCELERATION)
	velocity.x = move_toward(velocity.x, movement_dir * RUN_SPEED, acceleration * delta)
	velocity.y += gravity * delta
	if VELinput.is_finite(): 
		velocity = VELinput
	if not is_zero_approx(movement_dir):
		direction = Direction.LEFT if movement_dir<0 else Direction.RIGHT
	move_and_slide()
func die() -> void:
	var tree := get_tree()
	tree.reload_current_scene()
	# await tree.tree_changed
	# Game.player_stats.health = MAX_HEALTH
func stand(gravity: float, delta: float) -> void:
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += gravity * delta
	move_and_slide()
func slide(delta : float) -> void:
	# velocity.x = slide_dir * SLIDING_SPEED
	velocity.x = direction * SLIDING_SPEED
	velocity.y += default_gravity * delta
	move_and_slide()
func hitstop(type: int = 0, time: float = 0.05, time_scale: float = 0.05):
	if type == 0:
		state_machine.hitstop = time
		animation_player.speed_scale = time_scale
		await get_tree().create_timer(time, true, false, true).timeout
		animation_player.speed_scale = 1
	elif type == 1:
		var sctw = get_tree().create_tween()
		Engine.time_scale = time_scale
		sctw.tween_property(wave, "scale", Vector2(40, 40), time*8*time_scale)
		await get_tree().create_timer(time, true, false, true).timeout
		Engine.time_scale = 1
		await sctw.finished
		wave.scale = Vector2.ZERO
func register_interactable(interactable: Interactable) -> void:
	if state_machine.current_state in INACTIVE_STATES:
		return
	if interacting_with.has(interactable):
		return
	interacting_with.append(interactable)
	interaction_action.visible = true
func unregister_interactable(interactable: Interactable) -> void:
	interacting_with.erase(interactable)
	interaction_action.visible = interacting_with.size() > 0
func handle_damage(hit_stun:int = 0) -> void:
	hitstop(0, hit_stun/10.)
			
	var total_knockback := Vector2.ZERO
	var total_damage := 0.0
	for dmg in pending_damages:
		total_damage += dmg.amount
		# 计算每个伤害源的击退向量
		var dir = dmg.knockback_dir if not dmg.knockback_dir.is_zero_approx() else \
			(global_position - dmg.source.global_position).normalized()
		total_knockback += dir * dmg.knockback_force
	
	stats.health -= int(total_damage)
	velocity = total_knockback * KNOCKBACK_AMOUNT
	pending_damages.clear()
	
	invincible_timer.start()

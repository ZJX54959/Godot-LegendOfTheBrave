extends Enemy

enum State {
	IDLE,
	WALK,
	RUN,
	HURT,
	DYING,
}

const KNOCKBACK_AMOUNT := 512.0/4

# var pending_damage: Damage
var pending_damages: Array[Damage] = []

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var calm_down_timer: Timer = $CalmDownTimer
@onready var hitbox: Hitbox = $Graphics/Hitbox


func _ready() -> void:
	super._ready()
	knockback_amount = 20


func can_see_player() -> bool:
	if not player_checker.is_colliding():
		return false
	return player_checker.get_collider() is Player
# func hitstop(type: int = 0, time: float = 0.03):
# 	if type == 0:
# 		state_machine.hitstop = time
# 		animation_player.speed_scale = 0.05
# 		await get_tree().create_timer(time, true, false, true).timeout
# 		animation_player.speed_scale = 1
# 	elif type == 1:
# 		Engine.time_scale = .05
# 		await get_tree().create_timer(0.5, true, false, true).timeout
# 		Engine.time_scale = 1


func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE, State.HURT, State.DYING:
			move(0.0, delta)
		
		State.WALK:
			move(max_speed/3, delta)
		
		State.RUN:
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				direction *= -1
			move(max_speed, delta)
			if can_see_player():
				calm_down_timer.start()
		
		_:
			push_warning("Unhandled State of _[%s(%d)]_ !\nmove(0.0) instead!" % [State.keys()[state] if state in State.values() else "UnknownState", state])
			move(0.0, delta)


func get_next_state(state: State) -> int:
	if stats.health <= 0:
		return State.DYING if not state == State.DYING else state_machine.KEEP_CURRENT
	
	# if pending_damage:
	# 	return State.HURT
	if not pending_damages.is_empty():
		return State.HURT
	
	match state:
		State.IDLE:
			if can_see_player():
				return State.RUN
			if state_machine.state_time > 2:
				return State.WALK
		
		State.WALK:
			if can_see_player():
				return State.RUN
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				return State.IDLE
		
		State.RUN:
			#if calm_down_timer.time_left > 0:
				#print("[%d]Calmdown Timer: [%s]Time_left - %f || Can See Player? : %s" % [Engine.get_physics_frames(), name, calm_down_timer.time_left, "Y" if can_see_player() else "N"])
			if not can_see_player() and calm_down_timer.is_stopped():
				return State.WALK
		
		State.HURT:
			if not animation_player.is_playing():
				return State.RUN
		
		State.DYING:
			push_warning("State.DYING but somehow health > 0?! How??")
	
	return StateMachine.KEEP_CURRENT


func transition_state(from: State, to: State) -> void:
	
	#print("[%s] %s => %s" % [
			#Engine.get_physics_frames(),
			#State.keys()[from] if from != -1 else "<START>",
			#State.keys()[to],
		#])
	
	match to:
		State.IDLE:
			animation_player.play("idle")
			if wall_checker.is_colliding():
				direction *= -1
			hitbox.damage = null
		
		State.WALK:
			animation_player.play("walk")
			if not floor_checker.is_colliding():
				direction *= -1
				floor_checker.force_raycast_update()
			hitbox.damage = Damage.new(1 + velocity.length()/100., self)
		
		State.RUN:
			animation_player.play("run")
			hitbox.damage = Damage.new(5 + velocity.length()/100., self)
		
		State.HURT:
			animation_player.play("hit")
			
			# hitstop(1) # 还是专门写一个新函数处理这个吧
			
			# stats.health -= pending_damage.amount

			var total_damage := 0.
			# var total_knockback := Vector2.ZERO
			for dmg in pending_damages:
				total_damage += dmg.amount
				# var dir = dmg.knockback_dir if not dmg.knockback_dir.is_zero_approx() else \
					# (global_position - dmg.source.global_position).normalized()
				# total_knockback += dir * dmg.knockback_force
				pass
			
			# stats.health -= int(total_damage)
			# velocity = total_knockback * KNOCKBACK_AMOUNT
			print("[Enemy]Boar: total_damage: ", total_damage)
			pending_damages.clear()
			
			# direction = Direction.LEFT if total_knockback.x > 0 else Direction.RIGHT
			
			# pending_damage = null
		
		State.DYING:
			animation_player.play("die")
			hitbox.damage = null
			hurtbox.monitorable = false


func _on_hurtbox_hurt(hitbox: Hitbox, damage: Damage) -> void:#把伤害从一个新函数传进来的话，就能实现自定义伤害了
	# pending_damage = Damage.new()
	# pending_damage.amount = 1
	# pending_damage.source = hitbox.owner#把pending_damage改成数组、或者用算法混合，以实现同帧内多个伤害来源的处理
	print("damage: ", damage)
	if handle_damage(damage):
		"""
		不对啊...现在伤害处理的逻辑全移到handle_damage里了，那pending_damages是干嘛的？
		"""
		pending_damages.append(damage)

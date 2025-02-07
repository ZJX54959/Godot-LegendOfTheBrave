# func transition_state(event: InputEvent) -> void:
#      # 跳跃条件判断
#     var should_jump := (is_on_floor() or can_coyote_jump) and has_jump_request
    
#     var can_attack := is_on_floor()
#     var should_attack := _check_attack_input() and can_attack
#     # var should_jump := _check_jump_input(can_jump)
#     var should_slide := _check_slide_input()
#     var should_range_attack := _check_range_attack_input()
#     var should_combo_attack := can_combo and Input.is_action_pressed("Attack") and not Input.is_action_just_released("Attack")
#     var direction := Input.get_axis("move_left", "move_right")
#     var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
    
    
#     # 特殊指令检测
#     if _check_dp_command() and can_attack:
#         return State.ATTACK_3
#     if _check_slide_command():
#         return State.SLIDING_START
    
#     if _check_attack_input() and can_attack:
#         is_combo_requested = true
        
#     if should_jump:
#         return State.JUMP
    
#     if state in GROUND_STATES and not is_on_floor():
#         return State.FALLING
    
#     match state:
#         State.IDLE:
#             if should_attack:
#                 return State.ATTACK_1
#             if should_slide:
#                 return State.SLIDING_START
#             if not is_still:
#                 return State.RUNNING
        
#         State.RUNNING:
#             if should_attack:
#                 return State.ATTACK_1
#             if should_slide:
#                 return State.SLIDING_START
#             if is_still:
#                 return State.IDLE
        
#         State.JUMP:
#             if velocity.y >= 0:
#                 return State.FALLING
        
#         State.FALLING:
#             if is_on_floor():
#                 var height := global_position.y - fall_from_y
#                 return State.LANDING if height >= LANDING_HEIGHT else State.RUNNING
#             if can_wall_slide():
#                 return State.WALL_SLIDING
        
#         State.LANDING:
#             if should_attack:
#                 return State.ATTACK_1
#             if not is_still:
#                 return State.RUNNING
#             if not animation_player.is_playing():
#                 return State.IDLE
        
#         State.WALL_SLIDING:
#             if jump_request_timer.time_left > 0:
#                 return State.WALL_JUMP
#             if is_on_floor():
#                 return State.IDLE
#             if not on_wall():
#                 return State.FALLING
        
#         State.WALL_JUMP:
#             if can_wall_slide() and not is_first_tick:
#                 return State.WALL_SLIDING
#             if velocity.y >= 0:
#                 return State.FALLING
        
#         State.ATTACK_1:
#             if not animation_player.is_playing():
#                 if not should_combo_attack:
#                     return State.ATTACK_2 if is_combo_requested else State.IDLE
#                 else:
#                     return State.ATTACK_COMBO
        
#         State.ATTACK_2:
#             if not animation_player.is_playing():
#                 return State.ATTACK_3 if is_combo_requested else State.IDLE#算了，还是专门给连击新做个动画吧
        
#         State.ATTACK_3:
#             if not animation_player.is_playing():
#                 return State.IDLE
        
#         State.ATTACK_COMBO:
#             if Input.is_action_just_released("Attack"):
#                 return State.ATTACK_3
        
#         State.HURT:
#             if not animation_player.is_playing():
#                 return State.IDLE
        
#         State.SLIDING_START:
#             if not animation_player.is_playing():
#                 return State.SLIDING_LOOP
        
#         State.SLIDING_END:
#             if not animation_player.is_playing():
#                 return State.IDLE
        
#         State.SLIDING_LOOP:
#             if state_machine.state_time > STATE_DURATION:
#                 return State.SLIDING_END
        
#         #_:
#             #assert(state in State.values(),"cur_state not in enum State?! How?")
#             #assert(state not in State.values(),"hey some state got broken, did you passed Sth.?")
        
    
#     return StateMachine.KEEP_CURRENT
'''
func unhandled_input(event: InputEvent) -> void:

# 	if event.is_action_pressed("Attack"):
# 		attack_request_timer.start()#希望将来能实现通过按键时长决定出招 -> >is_action_pressed()<?
	
# 	if Input.is_action_just_pressed("Range"):
# 		charge_hold_timer.start()
# 	if Input.is_action_just_released("Range"):
# 		if charge_hold_timer.time_left > charge_hold_timer.wait_time-0.5:
# 			shooter.shoot(
# 				shooter.shooter_config(load("res://bullets/arrow.tscn"), position+Vector2(0, -32))
# 					.with_speed(350)
# 					.with_custom_config(func(b):
# 					b.gravity_velocity = Vector2.DOWN
# 					b.gravity_scale = .6
# 					b.velocity = get_local_mouse_position() - Vector2(0, -32)
# 					), 
# 				Shooter.SHOOT_PATTERN.SINGLE
# 				)

# 		else:
# 			#shooter.shoot(Shooter.PARTTERN.BULLET, Bullet.BASIC_TYPE.TENTACLE_1)
# 			#shooter.shoot(Shooter.PARTTERN.BULLET, Bullet.BASIC_TYPE.LIGHTING)
# 			shooter.shoot(
# 			shooter.shooter_config(load("res://bullets/lightning.tscn") ,get_global_mouse_position())
# 				.with_custom_config(func(b):
# 				pass
# 				),
# 			shooter.SHOOT_PATTERN.SINGLE
# 		)
# 			pass
# 		charge_hold_timer.stop()
	
# 	if attack_request_timer.time_left > 0 and can_combo:
# 		is_combo_requested = true
	
# 	if event.is_action_pressed("slide"):
# 		slide_request_timer.start()
	


# func wall_normal():
# 	if front_wall_checker.is_colliding(): last_wall_normal = front_wall_checker.get_collision_normal()
# 	elif back_wall_checker.is_colliding(): last_wall_normal = back_wall_checker.get_collision_normal()
# 	if not is_nan(last_wall_normal.x) and not is_nan(last_wall_normal.y): return last_wall_normal
# 	else:
# 		push_warning("Return Wall Normal As Vec2.ZERO")
# 		return Vector2.ZERO
# func on_wall():
# 	return front_wall_checker.is_colliding() or back_wall_checker.is_colliding()
# # func can_wall_slide() -> bool:
# 	return on_wall and hand_checker.is_colliding() and foot_checker.is_colliding() and not is_on_floor()
# func should_slide():
# 	if slide_request_timer.is_stopped():
# 		return false
# 	if stats.energy < SLIDING_ENERGY:
# 		return false
# 	return true
# func _check_dp_command() -> bool:
# 	return input_buffer.check_command([
# 		Vector2.RIGHT,
# 		Vector2.DOWN,
# 		Vector2.RIGHT + Vector2.DOWN,
# 		{"button": "Attack", "min_duration": 0.01}  # 需要按住攻击键0.5秒
# 	])
# func _check_slide_command() -> bool:
# 	return input_buffer.check_command([
# 		Vector2.RIGHT + Vector2.DOWN,
# 		{"button": "slide"}
# 	])
'''

"""
func _cleanup():
	var current_time := Time.get_ticks_msec() / 1000.0
	# 保留未释放按钮记录
	var keep_index := 0
	while keep_index < _buffer.size() and (current_time - _buffer[keep_index].timestamp > MAX_RECORD_TIME or (_buffer[keep_index].button != "" and not _buffer[keep_index].is_released)):
		keep_index += 1
	_buffer = _buffer.slice(keep_index)
"""
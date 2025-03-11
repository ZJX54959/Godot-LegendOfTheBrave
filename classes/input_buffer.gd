class_name InputBuffer
extends Node

# 指令类型枚举
enum CommandType {
	QCF,    # 236
	QCB,    # 214
	DP,     # 623
	CHARGE, # 蓄力指令
	CUSTOM
}

# 输入记录结构体
class InputRecord:
	var direction: Vector2
	var button: String
	var timestamp: float
	var duration: float  # 记录持续时长
	var is_released := false  # 新增释放状态标记
	var device_id := 0  # 新增设备ID字段
	
	func _init(dir: Vector2, btn: String, time: float):
		direction = dir
		button = btn
		timestamp = time
		duration = 0.0

var _buffer: Array[InputRecord] = []
const MAX_RECORD_TIME := 0.25  # 延长指令有效时间窗口
const KEY_REPEAT_THRESHOLD := 0.05  # 键盘自动重复间隔阈值
var _held_buttons := {}  # 改为记录{按钮: 按下时间}
var _last_direction := Vector2.ZERO
var _last_dir_time := 0.0

func _physics_process(_delta: float) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	
	# 新增：实时更新未释放按钮的持续时间
	for record in _buffer:
		if not record.is_released: # and record.button != "":
			record.duration = current_time - record.timestamp
	
	# if _buffer.is_empty():
	# 	return
	# if Engine.get_physics_frames() % 3 == 1:
	# 	var text: String = ""
	# 	for i in _buffer.size():
	# 		#text += " | " + var_to_str(rad_to_deg(_buffer[i].direction.angle())) + _buffer[i].button + "|" + var_to_str(_buffer[i].duration) + "|"# + "|" + var_to_str(_buffer[i].timestamp)
	# 		if not _buffer[i].button.begins_with("Vector"):
	# 			text += " |->" + _buffer[i].button + ":" + var_to_str(_buffer[i].duration) + "|"# + "|" + var_to_str(_buffer[i].timestamp)
	# 		elif not _buffer[i].direction.is_zero_approx():
	# 			text += " | " + var_to_str(rad_to_deg(_buffer[i].direction.angle())) + ":" + var_to_str(_buffer[i].duration) + "|"# + "|" + var_to_str(_buffer[i].timestamp)
	# 	print(text)
	# 	pass
# 		#print(_held_buttons)


# 添加输入记录（支持键盘和手柄）
func record_input(event: InputEvent) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# print("[Input] %s | Pressed: %s | Ctrl: %s | Device: %d" % [
	# 	event.as_text(),
	# 	event.is_pressed(),
	# 	event.ctrl_pressed if event is InputEventKey else false,
	# 	event.get_device()
	# 	])
	
	# 处理方向输入变化
	if input_dir != _last_direction and not event.is_echo():
		# 查找最后一个未释放的方向记录
		var last_dir_record: InputRecord = null
		for i in range(_buffer.size()-1, -1, -1):
			if _buffer[i].button.begins_with("Vector") and not _buffer[i].is_released:
				last_dir_record = _buffer[i]
				# break
		
		# 标记前一个方向记录为已释放
		if last_dir_record:
			last_dir_record.is_released = true
			last_dir_record.duration = current_time - last_dir_record.timestamp
		
		# 记录新方向（非零时）
		if not input_dir.is_zero_approx():
			_add_directional_input(input_dir, current_time)
		
		_last_direction = input_dir
		_last_dir_time = current_time
	
	# 修改后的按钮处理逻辑
	if event.is_pressed() and not event.is_echo():
		var actions := _get_action_for_event(event)
		if actions.is_empty() or actions.any(func(a): return a in ["move_left", "move_right", "move_up", "move_down"]):
			return
		
		# 新增：自动结束同一设备的未释放按钮
		var device_id = event.get_device()
		for action in actions:
			for record in _buffer:
				if record.button == action and not record.is_released and record.device_id == device_id:
					record.is_released = true
					record.duration = current_time - record.timestamp
			
			# 记录新按钮（添加设备ID）
			_held_buttons[action] = current_time
			var new_record = InputRecord.new(Vector2.ZERO, action, current_time)
			new_record.device_id = device_id
			_buffer.append(new_record)
	
	elif event.is_released() and not event.is_echo():
		var actions := _get_action_for_event(event)
		for action in actions:
			if action in _held_buttons:
				for record in _buffer:
					if record.button == action and not record.is_released:
						record.is_released = true
				_held_buttons.erase(action)

# 检测已完成输入的指令（按钮必须已释放）
func check_command(pattern: Array) -> bool:
	_cleanup()
	var current_time := Time.get_ticks_msec() / 1000.0
	var matched_indices: Array = []  # 记录匹配的索引
	
	# 子序列匹配算法
	var pattern_idx := 0
	for buffer_idx in _buffer.size():
		var record = _buffer[buffer_idx]
		var expected = pattern[pattern_idx]
		
		# 方向匹配
		if expected is Vector2:
			if _match_direction(record.direction, expected) and record.timestamp <= current_time:
				matched_indices.append(buffer_idx)
				pattern_idx += 1
		
		# 按钮匹配
		elif expected is Dictionary and expected.has("button"):
			if record.button == expected.button:
				var duration = record.duration if record.is_released else (current_time - record.timestamp)
				var min_ok = (not expected.has("min_duration")) or (duration > expected.min_duration)
				var max_ok = (not expected.has("max_duration")) or (duration < expected.max_duration and record.is_released)
				if min_ok and max_ok:
					matched_indices.append(buffer_idx)
					pattern_idx += 1
		
		if pattern_idx >= pattern.size():
			break
	
	if pattern_idx >= pattern.size():
		# 移除已匹配的记录
		var new_buffer: Array[InputRecord] = []
		for i in _buffer.size():
			if not i in matched_indices:
				new_buffer.append(_buffer[i])
		_buffer = new_buffer
		return true
	return false


# 清理过期记录
func _cleanup():
	var current_time := Time.get_ticks_msec() / 1000.0
	# var original = _buffer.duplicate()
	var keep_index := 0
	
	# 新的清理逻辑：所有记录从释放时间开始计算存活时间
	while keep_index < _buffer.size():
		var record = _buffer[keep_index]
		var release_time: float = record.timestamp + record.duration
		
		# 存活时间 = 当前时间 - 释放时间
		var alive_time = current_time - release_time
		var should_remove = alive_time > MAX_RECORD_TIME
		
		if not should_remove:
			break
		keep_index += 1
		# print("name: ", _buffer[keep_index-1].button, " | current_time: ", current_time, " | release_time: ", release_time, " | timestamp: ", _buffer[keep_index-1].timestamp, " | alive_time: ", alive_time, " | should_remove: ", should_remove)
	
	# var removed = _buffer.slice(0, keep_index) if keep_index > 0 else []
	# if keep_index > 0:
	# 	print("keep_index: ", keep_index)
	_buffer = _buffer.slice(keep_index)
	
# 	if removed.size() > 0:
# 		print("-\nBEFORE(%d):%s\nREMOVED(%d):%s\nAFTER(%d):%s\n-" % [
#  			original.size(), 
# 			_compact_format(original), 
# 			removed.size(),
# 			_compact_format(removed),
# 			_buffer.size(),
# 			_compact_format(_buffer)
# 		])

# # Helper function
# func _compact_format(records) -> String:
# 	var res = []
# 	for r in records:
# 		res.append("|%s%s@%.1f%s" % [
# 			r.button if r.button else r.direction, 
# 			"" if r.is_released else "*",  # *表示未释放
# 			r.timestamp,
# 			"/%.1f" % r.duration if r.duration > 0 else ""
# 		])
# 	return "\n".join(res)


# 通过InputMap获取事件对应的所有action名称
func _get_action_for_event(event: InputEvent) -> Array[String]:
	var matched_actions: Array[String] = []
	for action in InputMap.get_actions().filter(func(a): return not a.begins_with("ui_")):
		if event.is_action(action):
			matched_actions.append(action)
	return matched_actions

# 更新按钮持续时间（处理所有未完成的记录）
# func _update_button_duration(action: String, total_duration: float) -> void:
# 	print("Updating duration for: ", action, " duration: ", total_duration)
# 	for record in _buffer:
# 		if record.button == action and not record.is_released:
# 			record.duration = total_duration
# 			record.is_released = true  # 标记为已释放

# 添加方向输入（带8方向归整）
func _add_directional_input(dir: Vector2, time: float) -> void:
	var rounded_dir := Vector2(
		round(dir.x * 2) / 2,
		round(dir.y * 2) / 2
	).normalized()
	_buffer.append(InputRecord.new(rounded_dir, var_to_str(rounded_dir), time))

# 方向匹配检测
func _match_direction(input: Vector2, expected: Vector2) -> bool:
	if input.is_zero_approx():
		return false
	# print(input, expected, abs(input.angle_to(expected)) < 0.01)
	return abs(input.angle_to(expected)) < 0.01

# 新增：检测当前正在按住的按钮
# func is_button_held(action: String, min_duration: float = 0.0) -> bool:
# 	for record in _buffer:
# 		if record.button == action and not record.is_released:
# 			var current_duration = Time.get_ticks_msec()/1000.0 - record.timestamp
# 			return current_duration >= min_duration
# 	return false

# 获取指定按钮的最后一条记录
func get_last_button_record(action: String) -> InputRecord:
	for i in range(_buffer.size()-1, -1, -1):
		var record = _buffer[i]
		if record.button == action:
			return record
	return null

# 获取指定方向的最新记录
func get_last_direction() -> Vector2:
	for i in range(_buffer.size()-1, -1, -1):
		if not _buffer[i].direction.is_zero_approx():
			return _buffer[i].direction
	return Vector2.ZERO

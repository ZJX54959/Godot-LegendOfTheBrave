class_name Enemy
extends CharacterBody2D

enum Direction {
	LEFT = -1,
	RIGHT = +1,
}

@export var direction := Direction.LEFT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = -direction
@export var max_speed : float = 180
@export var acceleration : float = 2000
@export var knockback_amount: float = 100 # 越大越容易被击退

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = $Stats
@onready var hurtbox: Hurtbox = $Graphics/Hurtbox

@onready var init_hurt_layer: int = hurtbox.collision_layer # 160 = 128 + 32 = 0b10100000 = Layer 6 & 8 ON

# 添加无敌帧系统
const DEFAULT_INV_FRAME := 16  # 默认无敌时间16帧
var invincible_timer := 0.0
var is_invincible := false

func _ready() -> void:
	add_to_group("Enemy")
	# print(collision_layer)


func move(speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, speed * direction, acceleration * delta)
	velocity.y += default_gravity * delta
	
	move_and_slide()


func die() -> void:
	queue_free()

func _physics_process(delta: float) -> void:
	# 更新无敌帧计时器
	if invincible_timer <= 0:
		is_invincible = false
		hurtbox.collision_layer = init_hurt_layer
		# print("hurtbox.collision_layer: ", hurtbox.collision_layer)
	if invincible_timer > 0:
		invincible_timer -= delta
		# print("invincible_timer: ", invincible_timer * ProjectSettings.get("physics/common/physics_ticks_per_second"))
		# print("invincible_timer: ", invincible_timer)

# 公开接口：设置无敌帧（供子类调用）
func set_invincible(frames: float, hurt_layer: int = init_hurt_layer) -> void:
	is_invincible = true
	for i in range(32):
		hurtbox.set_collision_layer_value(i + 1, (hurt_layer >> i) & 1)
	invincible_timer = frames / ProjectSettings.get("physics/common/physics_ticks_per_second")

# 伤害处理主逻辑（供子类调用）
func handle_damage(damage: Damage) -> bool:
	print("is_invincible: ", is_invincible, " | damage: ", damage, " | damage.amount: ", damage.amount, " | damage.inv_frame: ", damage.inv_frame, " | damage.source: ", damage.source)
	if is_invincible:
		return false
	
	# 应用伤害前设置无敌帧
	if stats.health - damage.amount > 0:
		hitstop(0)
	else: 
		hitstop(1)
	
	var inv_frame = damage.inv_frame if damage.inv_frame > 0 else DEFAULT_INV_FRAME
	set_invincible(inv_frame, 0)
	
	stats.health -= int(damage.amount)

	velocity += damage.knockback_dir * damage.knockback_force * knockback_amount

	return true


func hitstop(type: int = 0, time: float = 0.03):
	if type == 0:
		state_machine.hitstop = time
		animation_player.speed_scale = 0.05
		await get_tree().create_timer(time, true, false, true).timeout
		animation_player.speed_scale = 1
	elif type == 1:
		Engine.time_scale = .05
		await get_tree().create_timer(0.5, true, false, true).timeout
		Engine.time_scale = 1

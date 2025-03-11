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

var default_gravity: float = ProjectSettings.get("physics/2d/default_gravity")

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = $Stats
@onready var hurtbox: Hurtbox = $Graphics/Hurtbox

@onready var init_hurt_layer: int = hurtbox.collision_layer # 160 = 128 + 32 = 0b10100000 = Layer 6 & 8 ON


const DEFAULT_INV_FRAME := 16
const BULLET_HURT_LAYER: int = 128 # Layer 8
const UNI_HURT_LAYER: int = 32 # Layer 6
# var invincible_timer := 0.0
var is_invincible := false
var should_bounce := false
var bounced_time: int = 0

var pending_damages: Array[Damage] = []

func _ready() -> void:
	add_to_group("Enemy")
	# stats.health_changed.connect(on_health_changed)
	stats.health_will_change.connect(on_health_changed)


func move(speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, speed * direction, acceleration * delta)
	velocity.y += default_gravity * delta
	var c_vel := velocity
	move_and_slide()
	if should_bounce:
		bounce(c_vel, get_wall_normal())


func die() -> void:
	queue_free()


func set_invincible(frames: float, hurt_layer: int = init_hurt_layer) -> void:
	'''调用方法：
		enemy.set_invincible(16, 128) # 设置无敌帧为16帧，并关闭Layer 8
		推荐写法：
			enemy.set_invincible(16, BULLET_HURT_LAYER | UNI_HURT_LAYER)
			enemy.set_invincible(16, 0b10000000 | 0b00000010)
	'''
	is_invincible = true
	var curr_layer := hurtbox.collision_layer
	for i in range(32):
		# hurtbox.set_collision_layer_value(i + 1, int(get_collision_layer_value(i + 1)) & ~((hurt_layer >> i) & 1))
		if ((hurt_layer >> i) & 1):
			hurtbox.set_collision_layer_value(i + 1, false)
	var invincible_timer: float = frames / ProjectSettings.get("physics/common/physics_ticks_per_second")
	await get_tree().create_timer(invincible_timer).timeout
	hurtbox.collision_layer = curr_layer
	is_invincible = false


# 伤害处理主逻辑（供子类调用）
func handle_damage(damage: Damage) -> bool:
	# print("is_invincible: ", is_invincible, " | damage: ", damage.name, " | damage.amount: ", damage.amount, " | damage.inv_frame: ", damage.inv_frame, " | damage.type: ", damage.type, " | damage.hurt_layer: ", damage.hurt_layer)
	if is_invincible:
		return false
	
	# 应用伤害前设置无敌帧
	if stats.health - damage.amount > 0:
		hitstop(0)
	else: 
		hitstop(1)
	
	var inv_frame = damage.inv_frame if damage.inv_frame > 0 else DEFAULT_INV_FRAME
	if damage.hurt_layer > 0:
		set_invincible(inv_frame, damage.hurt_layer)
	elif damage.type == "range":
		set_invincible(inv_frame, BULLET_HURT_LAYER | UNI_HURT_LAYER)
	else:
		set_invincible(inv_frame, UNI_HURT_LAYER)
	
	stats.health -= int(damage.amount)

	velocity += damage.knockback_dir * damage.knockback_force * knockback_amount

	if damage.smash_attack:
		should_bounce = true
		bounced_time = 0

	return true


func hitstop(type: int = 0, time: float = 0.16):
	if type == 0:
		state_machine.hitstop = time
		animation_player.speed_scale = 0.05
		await get_tree().create_timer(time, true, false, true).timeout
		animation_player.speed_scale = 1
	elif type == 1:
		Engine.time_scale = .05
		await get_tree().create_timer(0.5, true, false, true).timeout
		Engine.time_scale = 1

func bounce(vel: Vector2, wall_normal: Vector2) -> void:
	if not wall_normal:
		return
	if velocity.length() < 100 or bounced_time > 4:
		should_bounce = false
		return
	velocity = vel.bounce(wall_normal)
	bounced_time += 1

func on_health_changed(health_change: int) -> void:
	add_sibling(HitLabel.new(health_change).set_bias_position(position).with_hp(stats.max_health))

func _on_hurtbox_hurt(_hitbox: Hitbox, damage: Damage) -> void:
	if handle_damage(damage):
		pending_damages.append(damage)
	pass # Replace with function body.

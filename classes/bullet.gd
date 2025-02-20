class_name Bullet
extends Node2D

signal life_end

# enum BASIC_TYPE {
# 	BASIC_UR_BULLET,
# 	ARROW,
# 	LIGHTING,
# 	TENTACLE_1,
# 	SLASH,
# }

enum EXPIRE_REASON {
	NULL = -1,
	ANIMATION_END,
	LIFE_END,
	OUTSCREEN,
	HIT,
	OUT_OF_RANGE,
	INVALID_OWNER,
	EXCEED_LIMIT,
	ACTIVE_CANCEL, # 主动取消
	INACTIVE_CANCEL, # 被动取消
}


@onready var outlook: Sprite2D = $Outlook
@onready var particles: GPUParticles2D = $Particles
@onready var hitbox: Hitbox = $Hitbox
@onready var collision_shape: CollisionShape2D = $Hitbox/CollisionShape
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var invincible_timer: Timer = $InvincibleTimer


@export var damage: float = 1
@export var init_position: Vector2
@export var velocity: Vector2 = Vector2.RIGHT
@export var speed: float = 200
@export var life: float = 10.0
@export var hitpoint: int = 3
@export var type: String = "bullet"
@export var agile: float = 1
@export var damage_interval: int = 1
@export var knockback_dir: Vector2 = Vector2.ZERO
@export var knockback_force: float = 0

@export var aim: Node2D = null
@export var from_owner: Node2D = null

@export var immortal: bool = false
@export var outscreen_expired: bool = true
@export var auto_align: bool = true
@export var auto_knockback: bool = true

@export var gravity: bool = false
@export var gravity_scale: float = 9.8
@export var gravity_velocity: Vector2 = Vector2.DOWN

@export var homing: bool = false
@export var homing_scale: float = 1.0
@export var auto_homing_next: bool = true

var cam_rect: Rect2


func expired(reason: EXPIRE_REASON = EXPIRE_REASON.NULL, print_reason: bool = true) -> Error:
	if reason is EXPIRE_REASON and reason >= 0:
		if print_reason:
			print("[%s]%s from_%s [%s] expired" % [
				type, 
				name, 
				var_to_str(from_owner.name) if from_owner else "null", 
				EXPIRE_REASON.keys()[reason + 1],
				])
	queue_free()
	return OK

func get_velocity(delta: float) -> Vector2:
	return lerp((velocity + int(gravity) * gravity_scale * gravity_velocity), homing_velocity(delta, aim, auto_homing_next), int(homing) * homing_scale)

func move(delta: float):
	position += velocity * delta
	pass

func is_outscreen() -> bool:
	cam_rect = Rect2(get_viewport().get_camera_2d().get_screen_center_position() - get_viewport_rect().size/2.0, get_viewport_rect().size)
	if not cam_rect.intersects(Rect2(position - outlook.get_rect().size/2.0, outlook.get_rect().size)):
		# print(cam_rect, Rect2(position, outlook.get_rect().size))
		return true
	else: return false

func is_hitout() -> bool:
	if hitpoint <= 0:
		return true
	return false

func expiration_check(delta: float) -> EXPIRE_REASON:
	if not immortal:
		life -= delta
		if life <= 0:
			life_end.emit()
			expired(EXPIRE_REASON.LIFE_END, true)
			return EXPIRE_REASON.LIFE_END
	if outscreen_expired and is_outscreen():
		expired(EXPIRE_REASON.OUTSCREEN, true)
		return EXPIRE_REASON.OUTSCREEN
	if is_hitout():
		expired(EXPIRE_REASON.HIT, true)
		return EXPIRE_REASON.HIT
	return EXPIRE_REASON.NULL

func homing_velocity(delta: float, target: Node2D, auto_next: bool = true) -> Vector2:
	if target and not is_instance_valid(target):
		target = null
	if homing:
		if auto_next and not target and not get_tree().get_nodes_in_group("Enemy").is_empty():
			target = get_tree().get_nodes_in_group("Enemy").pick_random()
			aim = target
		if aim:
			return velocity.rotated(clampf(velocity.angle_to(target.global_position - global_position), -agile*delta, agile*delta))
	return velocity

# func invincibility_frame(_hurtbox: Hurtbox) -> void:
# 	'''英文名字包括 invincibility frame, immune frame, immunity frame, invulnerability frame; 有时简写为 iframe 或 i-frame'''
# 	var invincibility_time = damage_interval / 60.0
# 	invincible_timer.start(invincibility_time)
	
# 	create_tween().tween_property(outlook, "modulate:a", 0.5, 0.1).set_ease(Tween.EASE_IN_OUT)
# 	create_tween().tween_property(outlook, "modulate:a", 1.0, invincibility_time - 0.1).set_delay(0.1)

# func _on_invincible_timeout(hurtbox: Hurtbox) -> void:
# 	# is_invincible = false
# 	hurtbox.set_deferred("monitoring", true)
# 	outlook.modulate.a = 1.
# 	pass

func _on_hitbox_hit(_hurtbox) -> void:

	# hurtbox.set_deferred("monitoring", false)
	# hurtbox.owner._on_hurtbox_hurt(hitbox, Damage.new(damage, from_owner if from_owner else self))
	hitbox.damage = Damage.new(damage, from_owner if from_owner else self, damage_interval, knockback_force, knockback_dir).with_name(type)
	hitpoint -= 1
	# invincibility_frame(hurtbox)
	

func allocate_tex(tex: Texture2D = null):
	if tex and is_instance_valid(tex):
		outlook.texture = tex
		return tex
	#match type:
		#BASIC_TYPE.BASIC_UR_BULLET:
			#pass
		#BASIC_TYPE.ARROW:
			#outlook.texture = load("res://arrow.png")
			#outlook.rotation = PI/4
		#BASIC_TYPE.LIGHTING:
			#outlook.position += Vector2(0, -128)
			#animation_player.play("Lightning")
		#BASIC_TYPE.TENTACLE_1:
			#outlook.position += Vector2(0, -64)
			#animation_player.play("Tentacle1")
		#BASIC_TYPE.SLASH:
			#animation_player.play("slash")
	return outlook.texture

func allocate_property() -> void:
	#match type:
		#BASIC_TYPE.BASIC_UR_BULLET:
			#pass
		#BASIC_TYPE.ARROW:
			#collision_shape.shape = RectangleShape2D.new()
			#collision_shape.shape.size = Vector2(20, 4)
			#life = 20
			#damage_interval = 50
		#BASIC_TYPE.LIGHTING:
			#immortal = true
			#hitbox.set_collision_mask_value(4, true)
			##print(hitbox.collision_mask)
			#collision_shape.shape = RectangleShape2D.new()
			#collision_shape.shape.size = Vector2(8, 256)
			#collision_shape.position += Vector2(0, -128)
			#speed = 0; velocity = Vector2.ZERO
		#BASIC_TYPE.TENTACLE_1:
			#immortal = true
			#hitbox.set_collision_mask_value(4, true)
			#collision_shape.shape = RectangleShape2D.new()
			#collision_shape.shape.size = Vector2(8, 128)
			#collision_shape.position += Vector2(0, -64)
			#speed = 0; velocity = Vector2.ZERO
			#damage_interval = 24
		#BASIC_TYPE.SLASH:
			#immortal = true
			#collision_shape.shape = RectangleShape2D.new()
			#collision_shape.shape.size = Vector2(16, 32)
			#animation_player.speed_scale = 2
			#damage = 2
			#speed = 12
			#damage_interval = 1
	if init_position:
		global_position = init_position
	velocity = velocity.normalized() * speed
	if auto_align and velocity.length() > 0:
		rotation = velocity.angle()
	add_to_group("Bullet")
	pass

func _ready() -> void:
	set_physics_process(true)
	allocate_tex()
	allocate_property()

	hitbox.hit.connect(_on_hitbox_hit)
	
	# invincible_timer.timeout.connect(_on_invincible_timeout)


func _physics_process(delta: float) -> void:

	expiration_check(delta)
	
	if auto_align and velocity.length() > 0:
		rotation = velocity.angle()
	
	velocity = get_velocity(delta)
	if auto_knockback:
		knockback_dir = velocity.normalized()
	move(delta)
	

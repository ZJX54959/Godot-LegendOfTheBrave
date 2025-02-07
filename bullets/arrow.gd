extends Bullet

@onready var ray_cast: RayCast2D = $RayCast2D

var stopped: bool = false

func _ready() -> void:
	super._ready()
	# position = init_position
	type = BASIC_TYPE.ARROW
	life = 2
	damage = 12
	damage_interval = 50
	# auto_align = true
	# velocity = velocity.normalized() * speed
	gravity = true

func _physics_process(delta: float) -> void:

	expiration_check(delta)

	if stopped:
		hitbox.set_deferred("monitoring", false)
		return
	
	ray_cast.force_raycast_update()
	if ray_cast.is_colliding():
		stopped = true
		velocity = Vector2.ZERO
		$Particles.emitting = true
	
	if auto_align and velocity.length() > 0:
		rotation = velocity.angle()

	velocity = get_velocity(delta)
	move(delta)

func allocate_property() -> void:
	# 继承父类属性配置
	super()
	gravity_scale *= .8

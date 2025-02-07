extends Bullet

func _ready() -> void:
	super._ready()
	velocity = Vector2.ZERO
	immortal = true
	damage = 1
	damage_interval = 1
	gravity = false
	auto_align = false
	outscreen_expired = false
	homing = false
	animation_player.play("Lightning")

func _physics_process(delta: float) -> void:
	print(hitpoint)
	pass

func move(_f):
	pass

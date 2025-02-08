extends Bullet

func _ready() -> void:
	super._ready()
	life = 10
	damage = 4
	damage_interval = 6
	gravity = false
	animation_player.play("star")

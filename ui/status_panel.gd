extends HBoxContainer

@export var stats : Stats

@onready var health_bar: TextureProgressBar = $V/HealthBar
@onready var eased_health_bar: TextureProgressBar = $V/HealthBar/EasedHealthBar
@onready var energy_bar: TextureProgressBar = $V/EnergyBar


func _ready() -> void:
	stats.health_changed.connect(update_health)
	update_health()
	
	stats.energy_changed.connect(update_energy)
	update_energy()


func update_health() -> void:
	var percentage := stats.health / float(stats.max_health)
	health_bar.value = percentage
	
	create_tween().tween_property(eased_health_bar, "value", percentage, 0.3)#能不能给改成一段时间不受伤后再统一扣血啊？


func update_energy() -> void:
	var percentage := stats.energy / stats.max_energy
	energy_bar.value = percentage
	

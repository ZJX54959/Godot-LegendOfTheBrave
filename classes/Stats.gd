class_name Stats
extends Node

signal health_will_change(value: int)
signal health_changed(value: int)
signal energy_changed

@export var max_health: int = 30
@export var max_energy: float = 10
@export var energy_regen: float = 0.8

@onready var health : int = max_health:
	set(v):
		health_will_change.emit(v - health)
		v = clampi(v, 0, max_health)
		if health == v:
			return
		health_changed.emit(v - health)
		health = v

@onready var energy : float = max_energy:
	set(v):
		v = clampf(v, 0, max_energy)
		if energy == v:
			return
		energy_changed.emit()
		energy = v

func _process(delta: float) -> void:
	energy += energy_regen * delta

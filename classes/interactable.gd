class_name Interactable
extends Area2D

signal interacted(player: Player)


func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(2, true)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func interact(player: Player) -> void:
	print("[Interact] %s interacted with %s" % [player.name, name])
	interacted.emit(player)


func _on_body_entered(player: Player) -> void:
	player.register_interactable(self)


func _on_body_exited(player: Player) -> void:
	player.unregister_interactable(self)

class_name Teleporter
extends Interactable

@export_file("*.tscn") var target_scene: String
@export var entry_point: String


func interact(player: Player) -> void:
	super(player)
	Game.change_scene(target_scene, entry_point)
	"""
	指定玩家位置的错误实现：
	get_tree().root.update_player(entry_point.global_position)
	await get_tree().process_frame # 加上这一行依旧不行：切换场景后，所有对本场景的操作都会被遗弃
	get_tree().root.update_player(entry_point.global_position) # 只有这一行：change_scene_to_file在当前帧末尾调用，因此此处任何的操作都不会发生在其之后
	即使如上写，依然不起作用
	"""

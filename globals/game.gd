extends Node

@onready var player_stats: Stats = $PlayerStats

func change_scene(scene: String, entry_point: String) -> void:
	var tree := get_tree()

	for node in tree.get_nodes_in_group("EntryPoints"):
		if node.name == entry_point:
			var target_pos: Vector2 = node.global_position
			var target_dir: Player.Direction = node.direction
			tree.current_scene.update_player(target_pos, target_dir)
			break

	tree.change_scene_to_file(scene)
	await tree.tree_changed

	# tree.current_scene.update_player(target_pos, target_dir)

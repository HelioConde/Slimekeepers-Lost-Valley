extends SceneTree
## Captura do toco e do tronco caído ao lado de uma árvore inteira (playtest ID 44).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_felled_tree.gd -- <pasta>


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.get_node("GameClock").set_time(11, 0)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var chop: Node = region.get("gathering").choppable
	var player: Node2D = region.get("player")
	var spawn := Vector2(3200, 3200)
	for want_small in [true, false]:
		var best := ""
		for key: String in chop.trees:
			if chop.is_small(key) != want_small: continue
			if best == "" or (chop.trees[key] as Node2D).global_position.distance_to(spawn) < (chop.trees[best] as Node2D).global_position.distance_to(spawn):
				best = key
		if best == "": continue
		for i in chop.fell_hits(best): chop.strike({"key": best, "kind": "tree"}, 1, 1)
		player.global_position = (chop.trees[best] as Node2D).global_position + Vector2(-60, 40)
		for i in 30: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/tronco_%s.png" % [out, "pequena" if want_small else "grande"])
		print("capturado ", best, " altura ", chop.visible_height(best))
	quit()

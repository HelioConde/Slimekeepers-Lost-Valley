extends SceneTree
## Captura do broto de sementes silvestres (playtest ID 41). Uso: ... -- <pasta>


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var patches: Array = region.get("seed_patches")
	print("SEED_PATCH: ", patches.size(), " brotos")
	if not patches.is_empty():
		region.get("player").global_position = (patches[0] as Node2D).global_position + Vector2(40, 30)
		for i in 10: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/broto.png" % out)
	quit()

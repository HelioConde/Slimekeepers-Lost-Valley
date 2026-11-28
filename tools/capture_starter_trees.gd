extends SceneTree
## Árvores pequenas perto do início: conta as cortáveis a até 550 px e salva a tela.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_starter_trees.gd -- [pasta]
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1
func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var chop: Node = region.get("choppable")
	var spawn := Vector2(3200, 3200)
	var near := 0
	for k in chop.trees:
		if chop.is_small(k) and chop.trees[k].global_position.distance_to(spawn) < 550.0: near += 1
	var holder: Node = region.get_node("VegetationHigh/StarterTrees")
	var registered := 0
	for k in chop.trees: if str(k).contains("StarterTrees"): registered += 1
	print("plantadas=%d registradas=%d pequenas=%d" % [holder.get_child_count(), registered, chop.trees.keys().filter(func(k): return str(k).contains("StarterTrees") and chop.is_small(k)).size()])
	check(near >= 8, "árvores pequenas cortáveis perto do início (%d)" % near)
	if out != "":
		var cam: Camera2D = region.get("player").get_node("Camera2D")
		cam.zoom = Vector2(0.45, 0.45)
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/arvores_inicio.png" % out)
	print("STARTER_TREES: %d failures" % failures)
	quit(1 if failures else 0)

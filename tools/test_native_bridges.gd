extends SceneTree
## Each bridge is placed under test, then crossed with the unchanged player controller.
var failed := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(960,540)
	var scene: Node2D = load("res://scenes/regions/ValeDasNascentes.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 8: await physics_frame
	var index := 0
	for bridge: Rect2 in preload("res://scripts/world/valley_layout.gd").BRIDGES:
		var horizontal := bridge.size.x > bridge.size.y
		var axis := Vector2.RIGHT if horizontal else Vector2.DOWN
		var distance := (bridge.size.x if horizontal else bridge.size.y) * .5 + 24
		var start := bridge.get_center() - axis * distance
		var end := bridge.get_center() + axis * distance
		scene.player.position = start
		scene.player.get_node("Camera2D").reset_smoothing()
		var begin := Time.get_ticks_msec()
		var captured := false
		while scene.player.position.distance_to(end) > 5 and Time.get_ticks_msec() - begin < 6000:
			Input.action_press("move_right" if horizontal else "move_down")
			await physics_frame
			if not captured and scene.player.position.distance_to(bridge.get_center()) < 12:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/world/living_v3/visual/bridge_crossing_%d.png" % index)
				captured = true
		Input.action_release("move_right")
		Input.action_release("move_down")
		var passed: bool = scene.player.position.distance_to(end) <= 5 and captured
		if not passed: failed += 1
		print("BRIDGE ",index," crossed=",passed," remaining=",scene.player.position.distance_to(end))
		index += 1
	scene.queue_free()
	await process_frame
	print("NATIVE_BRIDGES: 5 crossings; %d failures" % failed)
	quit(1 if failed else 0)

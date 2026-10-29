extends SceneTree
## Approach original tree/stone colliders with actual Input and player controller.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	var original: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	var candidates := {}
	for group_name in ["VegetationHigh","ExpandedForest","Decorations"]:
		for prop in original.get_node(group_name).get_children():
			var sprite := prop.get_node_or_null("Sprite") as Sprite2D
			if sprite == null or not prop.visible or not prop.has_node("SolidBase"): continue
			var kind := "tree" if prop.has_meta("tree") else "stone"
			if kind == "stone" and not "stone.png" in sprite.texture.resource_path: continue
			if not candidates.has(kind): candidates[kind] = prop
	var failures := 0
	var stage := "before" if OS.get_cmdline_user_args().is_empty() else OS.get_cmdline_user_args()[0]
	for kind in candidates:
		var world := Node2D.new()
		world.y_sort_enabled = true
		root.add_child(world)
		var prop: Node2D = candidates[kind].duplicate()
		prop.position = Vector2(640,400)
		world.add_child(prop)
		var player: CharacterBody2D = load("res://scenes/player.tscn").instantiate()
		player.position = Vector2(640,480)
		world.add_child(player)
		player.get_node("Camera2D").enabled = false
		for i in 4: await physics_frame
		Input.action_press("move_up")
		for i in 90: await physics_frame
		Input.action_release("move_up")
		var gap: float = player.position.y-prop.position.y
		if gap < 8 or gap > 15: failures += 1
		print("CONTACT ",kind," foot_gap=",gap," collider=",player.get_node("CollisionShape2D").shape.get_rect())
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/world/depth_followup/contact_%s_%s.png" % [stage,kind])
		world.free()
		await process_frame
	original.free()
	print("CONTACT_DISTANCE: 2 approaches; %d failures" % failures)
	quit(1 if failures else 0)

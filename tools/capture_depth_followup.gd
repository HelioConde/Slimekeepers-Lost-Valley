extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/world/depth_followup/"+path+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(960,540)
	var region: Node2D=load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	current_scene=region
	for i in 8: await physics_frame
	region.player.position=Vector2(5110,1480)
	region.player.get_node("Camera2D").reset_smoothing()
	await create_timer(2).timeout
	await shot("cliff_plants_after")
	var life: Node2D=region.ecosystem
	var squirrel: Sprite2D
	for i in 90:
		for record in life._wildlife:
			if record.species=="squirrel": squirrel=record.sprite;break
		if squirrel: break
		await create_timer(.2).timeout
	if squirrel:
		region.process_mode=Node.PROCESS_MODE_DISABLED
		squirrel.global_position=Vector2(3160,3200)
		region.player.position=squirrel.global_position+Vector2(85,0)
		var camera: Camera2D=region.player.get_node("Camera2D")
		camera.position_smoothing_enabled=false
		camera.reset_smoothing()
		camera.force_update_scroll()
		squirrel.scale=Vector2.ONE*.75
		await shot("squirrel_before")
		squirrel.scale=Vector2.ONE*preload("res://scripts/world/forest_life.gd").WILDLIFE_SCALE.squirrel
		await shot("squirrel_after")
		print("NATIVE_SQUIRREL: actual ambient sprite captured at both scales")
	else: push_error("No actual squirrel spawned for capture")
	quit(0 if squirrel else 1)

extends SceneTree
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(960,540)
	var scene := load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate() as Node2D
	root.add_child(scene)
	current_scene = scene
	# Let habitats populate outside the initial camera before moving the capture camera.
	for i in 8: await physics_frame
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if args.size() else "spawn"
	var camera: Camera2D = scene.player.get_node("Camera2D")
	if mode == "overview":
		root.size = Vector2i(1600,1600)
		root.content_scale_size = Vector2i.ZERO
		camera.zoom = Vector2(0.25,0.25)
		scene.get_node("HUD").hide()
	else:
		var places := {"spawn":Vector2(3200,3200),"east":Vector2(4480,3270),"mushrooms":Vector2(2100,2860),"old_tree":Vector2(2860,1880),"hills":Vector2(5110,1480),"south":Vector2(3220,5680),"garden":Vector2(5100,4250)}
		scene.player.position = places.get(mode,Vector2(3200,3200))
	camera.reset_smoothing()
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var path := "res://docs/world/forest_v2/after_%s.png"%mode
	var code := root.get_texture().get_image().save_png(path)
	print("CAPTURE ",path," result=",code," fps=",Engine.get_frames_per_second())
	scene.queue_free()
	await process_frame
	quit(code)

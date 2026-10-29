extends SceneTree
## Native render capture: --script res://tools/capture_clearing.gd -- spawn|overview|north|east|south|grove
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(960, 540)
	var region := (load("res://scenes/world.tscn") as PackedScene).instantiate()
	root.add_child(region)
	current_scene = region
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if not args.is_empty() else "spawn"
	var camera: Camera2D = region.player.get_node("Camera2D")
	if mode == "overview":
		root.size = Vector2i(1280, 1280)
		root.content_scale_size = Vector2i.ZERO
		camera.zoom = Vector2.ONE * 0.4
		region.get_node("HUD").hide()
	elif mode != "spawn":
		var points := {"north":Vector2(1670, 900), "east":Vector2(2320, 1535), "south":Vector2(1710, 2320), "grove":Vector2(960, 1190), "spring":Vector2(1675,1485), "hollow":Vector2(1200,2060), "fern_nook":Vector2(1900,950)}
		region.player.position = points[mode]
	camera.reset_smoothing()
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var output := "res://docs/world/clareira_%s.png" % mode
	var result := root.get_texture().get_image().save_png(output)
	print("CAPTURE ", output, " result=", result, " fps=", Engine.get_frames_per_second())
	quit(result)

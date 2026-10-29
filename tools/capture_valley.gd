extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(960,540)
	var world:Node2D=load("res://scenes/regions/ValeDasNascentes.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	var args:=OS.get_cmdline_user_args()
	var mode:=args[0] if not args.is_empty() else "springs"
	var points:={"entrance":Vector2(1600,450),"springs":Vector2(1380,1410),"west":Vector2(360,730),"east":Vector2(2710,700),"lagoons":Vector2(1000,1980),"bridge":Vector2(828,1680),"marsh":Vector2(1120,2510),"south":Vector2(2850,3020)}
	var camera:Camera2D=world.player.get_node("Camera2D")
	if mode=="overview":
		root.size=Vector2i(1280,1280)
		root.content_scale_size=Vector2i.ZERO
		world.player.position=Vector2(1600,1600)
		camera.zoom=Vector2(.4,.4)
		world.get_node("HUD").hide()
	else: world.player.position=points[mode]
	camera.reset_smoothing()
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var path:="res://docs/world/vale/vale_%s.png"%mode
	var error:=root.get_texture().get_image().save_png(path)
	print("CAPTURE ",mode," result=",error)
	quit(error)

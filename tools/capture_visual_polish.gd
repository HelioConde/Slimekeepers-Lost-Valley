extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(960,540)
	var args:=OS.get_cmdline_user_args()
	var stage:=args[0] if args.size()>0 else "after"
	var maps := [
		["forest","res://scenes/regions/FlorestaDoDespertarV2.tscn",{"spawn":Vector2(3200,3200),"hills":Vector2(5110,1480),"mushrooms":Vector2(2100,2860),"log":Vector2(2800,3660),"old_tree":Vector2(2860,1880),"habitat":Vector2(4920,3170),"moss":Vector2(1980,2120)}],
		["valley","res://scenes/regions/ValeDasNascentes.tscn",{"west":Vector2(360,730),"springs":Vector2(1380,1410),"east":Vector2(2710,700),"bridge":Vector2(828,1680),"lagoons":Vector2(1000,1980),"marsh":Vector2(1120,2510)}]]
	DirAccess.make_dir_recursive_absolute("res://docs/world/living_v3/visual")
	for map in maps:
		var region: Node2D=load(map[1]).instantiate()
		root.add_child(region)
		current_scene=region
		for i in 8:await physics_frame
		for key in map[2]:
			region.player.position=map[2][key]
			region.player.get_node("Camera2D").reset_smoothing()
			await create_timer(2).timeout
			await RenderingServer.frame_post_draw
			var path:="res://docs/world/living_v3/visual/%s_%s_%s.png"%[stage,map[0],key]
			var code:=root.get_texture().get_image().save_png(path)
			print("VISUAL_CAPTURE ",path," result=",code)
		region.queue_free()
		await process_frame
	quit()

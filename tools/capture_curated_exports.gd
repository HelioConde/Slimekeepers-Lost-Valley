extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var output := "res://docs/world/"+(args[0] if args.size() else "curated_exports")
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(960,540)
	for map in ["FlorestaDoDespertarV2","ValeDasNascentes"]:
		var region: Node2D=load("res://scenes/regions/%s.tscn"%map).instantiate()
		root.add_child(region)
		current_scene=region
		for i in 10: await physics_frame
		var art: Node2D=region.get_node("MapArt")
		var camera: Camera2D=region.player.get_node("Camera2D")
		camera.position_smoothing_enabled=false
		var views:={}
		if map=="FlorestaDoDespertarV2":views={"clareira":Vector2(3200,3200),"cogumelos":Vector2(2100,2860),"musgo":Vector2(1980,2120),"norte_sem_banco":Vector2(5190,1230),"caminho_sem_poste":Vector2(3120,5570)}
		else:views={"lagoas":Vector2(1000,1980),"margem_leste":Vector2(2980,1900),"entrada_sem_banco":Vector2(1410,680),"oeste_sem_poste":Vector2(745,1450),"leste_sem_poste":Vector2(2390,1450)}
		for prop in art.get_children():
			if prop.get_meta("curated_asset")=="ruins_b" and not views.has("ruinas"):
				views["ruinas"]=prop.position+Vector2(55,45)
		for label in views:
			region.player.position=views[label]
			camera.reset_smoothing()
			await create_timer(.8).timeout
			await RenderingServer.frame_post_draw
			var file:="%s/%s_%s.png"%[output,map,label]
			root.get_texture().get_image().save_png(file)
			print("CURATED_CAPTURE ",file)
		region.queue_free()
		await process_frame
	quit()

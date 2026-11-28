extends SceneTree
## Captura de evidências de iluminação SEM o Godot MCP (precisa de janela, não --headless):
##   godot --path . --rendering-driver opengl3 --script res://tools/capture_lighting.gd -- \
##     --scene=FlorestaDoDespertarV2 --out=C:/tmp/shots --tag=antes --times=9:00,12:00,18:30,22:00
## Opcional: --at=x,y (posição do jogador), --walk (faixa com o jogador andando),
## --fps (mede tempo de quadro com vsync desligado, 300 quadros por horário),
## --layers (mesma cena sem luzes locais, sem sombras e sem tom ambiente),
## --anim=N (N quadros a cada 5 frames, para provar movimento em GIF).

var args := {}


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	call_deferred("run")


func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var scene: String = args.get("scene", "FlorestaDoDespertarV2")
	var out: String = args.get("out", "user://lighting")
	var tag: String = args.get("tag", "shot")
	DirAccess.make_dir_recursive_absolute(out)
	var region: Node2D = load("res://scenes/regions/%s.tscn" % scene).instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var clock := root.get_node("GameClock")
	clock.stop()
	var player: Node2D = region.get_node("Player")
	if args.has("at"):
		var xy: PackedStringArray = args["at"].split(",")
		player.global_position = Vector2(float(xy[0]), float(xy[1]))
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	for time_text in String(args.get("times", "9:00,12:00,18:30,22:00")).split(","):
		var hm := time_text.split(":")
		if args.has("day"):
			clock.load_save_data({"version": 1, "day": int(args["day"]), "minutes": float(int(hm[0]) * 60 + (int(hm[1]) if hm.size() > 1 else 0))})
		else:
			clock.set_time(int(hm[0]), int(hm[1]) if hm.size() > 1 else 0)
		if camera: camera.reset_smoothing()
		# Partículas (chama, brasas, vagalumes) precisam de ~1,5 s para encher depois
		# de ligadas; capturar antes disso mostra a fogueira "acabando de acender".
		for i in 90: await process_frame
		var stamp := "%02d%02d" % [int(hm[0]), int(hm[1]) if hm.size() > 1 else 0]
		var image: Image = await frame_image()
		image.save_png("%s/%s_%s_%s.png" % [out, tag, scene, stamp])
		if args.has("layers"):
			await _capture_layers(region, "%s/%s_%s_%s" % [out, tag, scene, stamp])
		if args.has("anim"):
			# Sequência com o relógio parado: só partículas, shaders e água se movem.
			for index in int(args["anim"]):
				for i in 5: await process_frame
				var still: Image = await frame_image()
				still.save_png("%s/%s_%s_%s_anim%02d.png" % [out, tag, scene, stamp, index])
		if args.has("fps"):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			for i in 30: await process_frame
			var start := Time.get_ticks_usec()
			var worst := 0
			var slow := 0
			var last := start
			for i in 300:
				await process_frame
				var now := Time.get_ticks_usec()
				worst = maxi(worst, now - last)
				if now - last > 20000: slow += 1
				last = now
			var avg_ms := float(Time.get_ticks_usec() - start) / 300.0 / 1000.0
			print("FPS %s %s %s avg_ms=%.2f fps=%.0f worst_ms=%.2f slow_frames=%d draw_calls=%d objects=%d" % [
				tag, scene, stamp, avg_ms, 1000.0 / avg_ms, worst / 1000.0, slow,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		if args.has("walk"):
			# Jogador atravessa a área em passos de 24 px: luz/sombra e câmera estável.
			var origin := player.global_position
			for step in 6:
				player.global_position = origin + Vector2(step * 24 - 72, 0)
				for i in 12: await process_frame
				var walk: Image = await frame_image()
				walk.save_png("%s/%s_%s_%s_walk%d.png" % [out, tag, scene, stamp, step])
			player.global_position = origin
	print("CAPTURE_DONE ", out)
	region.queue_free()
	await process_frame
	quit(0)


## Mesma imagem com uma camada desligada por vez, para achar a origem de cada mancha.
func _capture_layers(region: Node2D, prefix: String) -> void:
	var lighting := region.get_node("DayNightLighting") as CanvasModulate
	var lights := lighting.get_node_or_null("AmbientLights") as Node2D
	var shadows := lighting.get_node_or_null("DayShadows") as Node2D
	var tint := lighting.color
	var point_lights := region.find_children("*", "PointLight2D", true, false)
	for layer in ["sem_luzes", "sem_sombras", "sem_ambiente"]:
		match layer:
			"sem_luzes":
				for light in point_lights: light.enabled = false
				if lights: lights.hide()
			"sem_sombras":
				if shadows: shadows.hide()
			"sem_ambiente":
				lighting.set_process(false)
				lighting.color = Color.WHITE
		var image: Image = await frame_image()
		image.save_png("%s_%s.png" % [prefix, layer])
		for light in point_lights: light.enabled = true
		if lights: lights.show()
		if shadows: shadows.show()
		lighting.set_process(true)
		lighting.color = tint

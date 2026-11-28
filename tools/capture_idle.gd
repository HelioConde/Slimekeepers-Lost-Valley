extends SceneTree
## Idles do Aren (aprovadas em 2026-11-23): parado alguns segundos, toca a idle A ou B
## uma vez e volta à pose fixa. Salva quadros para montar um GIF.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_idle.gd -- <pasta>

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
	var player: Node2D = region.get("player")
	(player.get_node("Camera2D") as Camera2D).position_smoothing_enabled = false
	var frames: SpriteFrames = player.sprite.sprite_frames
	check(frames.has_animation("idle_a_south") and frames.has_animation("idle_b_north"), "idles A e B carregadas")
	check(frames.get_frame_count("idle_a_south") == 9, "idle A tem 9 quadros")
	var seen := {}
	var k := 0
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 14000:
		await create_timer(0.15).timeout
		var anim: String = player.current_animation
		seen[anim.substr(0, 7)] = true
		if out != "" and k < 90:
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			var vp := player.get_viewport()
			var at: Vector2 = vp.get_canvas_transform() * player.global_position * (Vector2(img.get_size()) / vp.get_visible_rect().size)
			img.get_region(Rect2i(Vector2i(at) - Vector2i(80, 170), Vector2i(160, 190))).save_png("%s/idle_%02d.png" % [out, k])
			k += 1
	check(seen.has("idle_a_") or seen.has("idle_b_"), "parado, toca uma idle (%s)" % str(seen.keys()))
	check(seen.has("idle_so"), "volta à pose parada")
	# Muito tempo parado: senta e medita (Aren, de frente).
	player.set("_still_time", 25.0)
	await create_timer(2.5).timeout
	check(str(player.current_animation).begins_with("meditate"), "parado 20 s, senta e medita (%s)" % player.current_animation)
	if out != "":
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var vp := player.get_viewport()
		var at: Vector2 = vp.get_canvas_transform() * player.global_position * (Vector2(img.get_size()) / vp.get_visible_rect().size)
		img.get_region(Rect2i(Vector2i(at) - Vector2i(80, 170), Vector2i(160, 190))).save_png("%s/meditando.png" % out)
	print("IDLE: %d failures" % failures)
	quit(1 if failures else 0)

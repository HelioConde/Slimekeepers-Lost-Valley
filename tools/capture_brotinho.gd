extends SceneTree
## Brotinho novo (2026-11-23) no jogo: parado, comendo e recebendo carinho.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_brotinho.gd -- <pasta>

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
	for i in 30: await process_frame
	var slime: Node2D = null
	for s in region.get("slimes"):
		if str(s.get("slime_type")) == "brotinho": slime = s; break
	check(slime != null, "há um Brotinho na Floresta")
	if slime == null:
		quit(1)
		return
	var player: Node2D = region.get("player")
	(player.get_node("Camera2D") as Camera2D).position_smoothing_enabled = false
	player.global_position = slime.global_position + Vector2(40, 10)
	var sprite: AnimatedSprite2D = slime.get("sprite")
	check(sprite.sprite_frames.has_animation("comer") and sprite.sprite_frames.has_animation("receber_carinho"), "Brotinho tem comer e receber carinho")
	var k := 0
	for step in [["", 1.2], ["comer", 1.6], ["receber_carinho", 1.6]]:
		if not str(step[0]).is_empty(): slime.call("react", step[0])
		var t := 0.0
		while t < float(step[1]):
			await create_timer(0.12).timeout
			t += 0.12
			if out != "":
				await RenderingServer.frame_post_draw
				var img := root.get_texture().get_image()
				var vp := slime.get_viewport()
				var at: Vector2 = vp.get_canvas_transform() * slime.global_position * (Vector2(img.get_size()) / vp.get_visible_rect().size)
				img.get_region(Rect2i(Vector2i(at) - Vector2i(90, 110), Vector2i(180, 140))).save_png("%s/brot_%02d.png" % [out, k])
				k += 1
		if not str(step[0]).is_empty():
			check(str(sprite.animation) == str(step[0]), "reage com %s (%s)" % [step[0], sprite.animation])
	print("BROTINHO: %d failures" % failures)
	quit(1 if failures else 0)

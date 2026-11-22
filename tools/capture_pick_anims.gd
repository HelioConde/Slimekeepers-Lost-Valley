extends SceneTree
## Captura real: Aren e Moni arrancando mato ([E] segurado, agachado com as duas mãos)
## e pegando graveto (um toque, ajoelhado com uma mão) na Floresta.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_pick_anims.gd -- OUT_DIR

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func hold(action: String, seconds: float) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await create_timer(seconds).timeout
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func shot(out: String, name: String, player: Node2D) -> void:
	if out.is_empty(): return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var vp: Viewport = player.get_viewport()
	# Tela em pixels da janela (a viewport base é menor e é esticada).
	var at: Vector2 = vp.get_canvas_transform() * player.global_position * (Vector2(img.get_size()) / vp.get_visible_rect().size)
	var r := Rect2i(Vector2i(at) - Vector2i(130, 190), Vector2i(260, 240)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	img.get_region(r).save_png("%s/%s.png" % [out, name])


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	if not out.is_empty(): DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for who in ["aren", "moni"]:
		for k in ["forest_bag_items", "forage_taken"]:
			if has_meta(k): remove_meta(k)
		set_meta("protagonist", who)
		var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
		root.add_child(region)
		for i in 30: await process_frame
		await physics_frame
		for i in 5: await process_frame
		var forage: Node2D = region.get("forage")
		var player: Node2D = region.get_node("Player")
		var cam := player.get_node_or_null("Camera2D") as Camera2D
		if cam: cam.position_smoothing_enabled = false  # teleporte: câmera já no lugar
		var mato: Dictionary = {}
		var graveto: Dictionary = {}
		for spot: Dictionary in forage.spots:
			if spot.item == "fibra" and mato.is_empty() and spot.has("sprite"): mato = spot
			if spot.item == "graveto" and graveto.is_empty(): graveto = spot
		# Mato: segurando [E], fica agachado no quadro das mãos no chão.
		player.global_position = mato.at + Vector2(0, 14)
		await physics_frame
		hold("interact", 4.3)
		await create_timer(1.5).timeout
		check(str(player.current_animation).begins_with("pick_big_") and player.sprite.frame == player.PICK_BIG_GROUND,
			"%s agachado no mato (%s q%d)" % [who, player.current_animation, player.sprite.frame])
		await shot(out, who + "_arrancar_mato", player)
		await create_timer(3.4).timeout
		check(str(player.current_animation).begins_with("pick_big_") and player.sprite.is_playing() or not player.is_using_tool(), "%s levanta depois de arrancar" % who)
		while player.is_using_tool(): await process_frame
		# Graveto: um toque, ajoelha com uma mão.
		player.global_position = graveto.at + Vector2(0, 14)
		await physics_frame
		await process_frame
		var down := InputEventAction.new()
		down.action = "interact"
		down.pressed = true
		Input.parse_input_event(down)
		await process_frame
		await process_frame
		var up := InputEventAction.new()
		up.action = "interact"
		up.pressed = false
		Input.parse_input_event(up)
		await create_timer(0.35).timeout
		check(str(player.current_animation).begins_with("pick_small_"), "%s pega graveto com uma mão (%s)" % [who, player.current_animation])
		await shot(out, who + "_pegar_graveto", player)
		region.queue_free()
		await process_frame
	remove_meta("protagonist")
	print("PICK_ANIMS: %d failures" % failures)
	quit(1 if failures else 0)

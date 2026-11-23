extends SceneTree
## Retrato, vida e energia no canto (referência do usuário) e, no multijogador, o
## cartão menor do outro jogador abaixo. Salva a captura do canto.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_player_status.gd -- [pasta]

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	set_meta("player_energy", 64)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var hud: Control = region.get_node_or_null("HUD/Interface/PlayerStatus")
	check(hud != null and region.get_node_or_null("HUD/Interface/EnergyBar") == null, "status no canto no lugar da barra antiga")
	check(int(hud._own.energy.value) == 64 and int(hud._own.health.value) == 100, "barras mostram energia 64 e vida cheia")
	check(hud._own.face.texture != null, "retrato do protagonista")
	check(hud.get_global_rect().position.x < 40 and hud.get_global_rect().position.y < 40, "fica no canto superior esquerdo")
	set_meta("player_energy", 20)
	for i in 3: await process_frame
	check(bool(hud.get("_warned")), "energia abaixo de 25 avisa uma vez")
	set_meta("player_energy", 64)
	for i in 3: await process_frame
	check(not bool(hud.get("_warned")), "aviso volta a valer depois de recuperar")
	hud.force_other = true
	hud.show_other("moni")
	hud.other_stats = {"h": 80, "e": 35}
	for i in 3: await process_frame
	check(hud._other.root.visible and int(hud._other.energy.value) == 35, "outro jogador abaixo (energia 35)")
	check(hud._other.root.get_global_rect().size.x < hud._own.root.get_global_rect().size.x, "cartão do outro é menor")
	if out != "":
		await create_timer(3.5).timeout  # título do lugar some
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().get_region(Rect2i(0, 0, 460, 200)).save_png("%s/player_status.png" % out)
	print("PLAYER_STATUS: %d failures" % failures)
	quit(1 if failures else 0)

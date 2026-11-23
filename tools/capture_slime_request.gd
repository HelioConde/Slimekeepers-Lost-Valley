extends SceneTree
## Pedido do slime: balãozinho com a comida por cima do slime amigo; dar a comida pedida
## tira o balão. Salva a captura.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_slime_request.gd -- [pasta]
const REQ := preload("res://scripts/systems/slime_requests.gd")
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
	var slime: Node2D = get_nodes_in_group("living_slimes")[0]
	slime.call("make_friend")
	var clock: Node = root.get_node("GameClock")
	var want := ""
	for d in range(1, 60):
		want = REQ.wanted(self, str(slime.get("persistent_id")), str(slime.get("slime_type")), d)
		if not want.is_empty():
			clock.day_number = d
			break
	var player: Node2D = region.get("player")
	player.global_position = slime.global_position + Vector2(-50, 20)
	await create_timer(1.0).timeout
	check(slime.get_node_or_null("RequestBubble") != null, "amigo perto mostra o balão do pedido (%s)" % want)
	if out != "":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/pedido.png" % out)
	REQ.fulfill(self, str(slime.get("persistent_id")), str(slime.get("slime_type")), clock.day_number, want)
	await create_timer(1.0).timeout
	check(slime.get_node_or_null("RequestBubble") == null, "atendido, o balão some")
	print("REQUEST: %d failures" % failures)
	quit(1 if failures else 0)

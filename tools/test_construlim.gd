extends SceneTree
## Construlim (2026-11-23): sozinho, vai até a planta mais perto e constrói no ritmo do
## jogador (a bancada de 10 s); gasta energia; ama raízes (cenoura, beterraba).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_construlim.gd -- [pasta]

const FEEDING := preload("res://scripts/systems/slime_feeding.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in ["farm_helpers_done", "placed_stations", "slime_work_off", "slime_at_farm"]:
		if has_meta(k): remove_meta(k)
	set_meta("forest_slime_friends", {"construlim/t/0": true})
	root.get_node("GameClock").set_time(8, 0)
	check(FEEDING.is_favorite("cenoura", "construlim") and FEEDING.is_favorite("beterraba", "construlim") and not FEEDING.is_favorite("cenoura_assada", "construlim"), "Construlim ama raízes cruas")
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var placer: Node2D = region.get("placer")
	var player: Node2D = region.get("player")
	player.global_position += Vector2(0, -500)  # longe: só o Construlim trabalha
	var farm: Node2D = region.get("farm")
	var at := Vector2(farm.cell_at(Vector2(3200, 3200)) * 32) + Vector2(140, 90)
	set_meta("placed_stations", [{"region": placer.region_id, "x": at.x, "y": at.y, "kind": "bancada", "built": false, "progress": 0.0}])
	placer.call("reload")
	if out != "": player.global_position = at + Vector2(0, -150)  # captura: obra na tela, jogador longe da planta
	check(placer.call("blueprints").size() == 1, "planta da bancada no chão")
	var shot := 0
	var built_at := -1.0
	for t in 400:  # até 20 s
		await create_timer(0.05).timeout
		if out != "" and t % 40 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/construlim_%02d.png" % [out, shot])
			shot += 1
		if placer.call("blueprints").is_empty():
			built_at = t * 0.05
			break
	check(built_at > 0.0, "Construlim construiu a bancada sozinho (%.1f s)" % built_at)
	var saved: Array = get_meta("placed_stations", [])
	check(not saved.is_empty() and bool(saved[0].built), "bancada pronta fica salva")
	var HELPERS: GDScript = load("res://scripts/world/farm_helpers.gd")  # depois dos autoloads
	var day: int = root.get_node("GameClock").day_number
	check(HELPERS.energy(self, "construlim", day) == HELPERS.ENERGY_MAX - 2 * HELPERS.TASK_COST, "10 s de obra gastam 2 tarefas de energia (%d)" % HELPERS.energy(self, "construlim", day))
	print("CONSTRULIM: %d failures" % failures)
	quit(1 if failures else 0)

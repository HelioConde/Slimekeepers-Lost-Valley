extends SceneTree
## Fluxo real da criação (CRIACAO.md) na Floresta: coleta com [E] nos pontos da
## Clareira, [C] abre a janela, fabrica corda e machado, o machado vai para a barra.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_crafting_flow.gd -- [OUT_DIR]

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
var failures := 0


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func _initialize() -> void:
	call_deferred("run")


func press(action: String) -> void:
	Input.action_press(action)
	await process_frame
	await process_frame
	Input.action_release(action)
	await process_frame


func key(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	root.push_input(e)
	await process_frame
	await process_frame


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in ["forest_bag_items", "forage_taken"]:
		if has_meta(k): remove_meta(k)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	await physics_frame
	await process_frame
	var forage: Node2D = region.get("forage")
	check(is_instance_valid(forage) and forage.spots.size() >= 20, "pontos de coleta na Clareira (%d)" % (forage.spots.size() if forage else 0))
	var player: Node2D = region.get_node("Player")
	for spot: Dictionary in forage.spots:
		player.global_position = spot.at + Vector2(0, 6)
		await physics_frame
		await process_frame
		await press("interact")
	var bag := BAG.inventory_snapshot(self)
	check(int(bag.get("fibra", 0)) >= 6 and int(bag.get("graveto", 0)) >= 2 and int(bag.get("pedra_pequena", 0)) >= 2, "coleta com [E] encheu a bolsa %s" % str(bag))
	check(not HOTBAR.slots(self).has("machado"), "sem machado antes de fabricar")
	var panel: Control = region.get("crafting_panel")
	await key(KEY_C)
	check(panel.visible, "[C] abre a janela de fabricação")
	if out != "": (await _shot()).save_png(out + "/crafting_panel.png")
	panel.call("_craft", "corda")
	panel.call("_craft", "corda")
	check(BAG.count_item(self, "corda") >= 2, "fabricou corda com fibra")
	panel.call("_craft", "machado")
	check(BAG.count_item(self, "machado") == 1, "fabricou o machado sem bancada")
	await key(KEY_C)
	check(not panel.visible, "[C] fecha a janela")
	check(HOTBAR.slots(self).has("machado"), "machado aparece na barra rápida")
	# Coletado some até amanhã.
	var spot: Dictionary = forage.spots[0]
	check(forage.nearest(spot.at, 1).is_empty(), "ponto coletado some no mesmo dia")
	check(not forage.nearest(spot.at, 2).is_empty(), "ponto coletado volta no dia seguinte")
	print("CRAFTING_FLOW: %d failures" % failures)
	quit(1 if failures else 0)


func _shot() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

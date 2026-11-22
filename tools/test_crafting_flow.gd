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


## Evento de entrada real (mesmo caminho do teclado): vale para is_action_just_pressed
## no _process da região, sem depender da ordem do await.
func press(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
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
	# Etapa 3: árvore comum -> toco + tronco -> madeira.
	var chop: Node = region.get("choppable")
	check(is_instance_valid(chop) and chop.trees.size() > 100, "árvores cortáveis registradas (%d)" % (chop.trees.size() if chop else 0))
	var protected_ok := true
	for key in chop.trees:
		for h in preload("res://scripts/world/forest_layout.gd").habitats():
			if (chop.trees[key] as Node2D).global_position.distance_to(h.center) < float(h.radius) + 80.0: protected_ok = false
	check(protected_ok, "nenhuma árvore cortável dentro de habitat de slime")
	var best_key := ""
	var best_d := 1e9
	for key in chop.trees:
		var d := (chop.trees[key] as Node2D).global_position.distance_to(Vector2(3200, 3200))
		if d < best_d: best_d = d; best_key = key
	var tree_node: Node2D = chop.trees[best_key]
	HOTBAR.select(self, HOTBAR.slots(self).find("machado"))
	player.global_position = tree_node.global_position + Vector2(0, 20)
	await physics_frame
	await process_frame
	var wood_before := BAG.count_item(self, "madeira")
	for i in 3:
		await press("interact")
		await _swing_done()
	check(chop.state(self).has(best_key), "árvore caiu após 3 golpes")
	check(not (tree_node.get_node("Sprite") as CanvasItem).visible, "árvore some e fica o toco")
	player.global_position = tree_node.global_position + chop.LOG_OFFSET + Vector2(0, 16)
	await physics_frame
	await process_frame
	if out != "": (await _shot()).save_png(out + "/tree_felled.png")
	for i in 2:
		await press("interact")
		await _swing_done()
	check(BAG.count_item(self, "madeira") == wood_before + chop.WOOD_PER_LOG, "tronco processado em %d madeiras" % chop.WOOD_PER_LOG)
	chop.apply_day(1 + chop.REGROW_DAYS)
	check((tree_node.get_node("Sprite") as CanvasItem).visible and not chop.state(self).has(best_key), "árvore volta a crescer após %d dias" % chop.REGROW_DAYS)
	# Etapa 4: mais 3 árvores (13 madeiras no total), bancada fabricada e colocada.
	var keys: Array = chop.trees.keys()
	keys.sort_custom(func(a, b): return (chop.trees[a] as Node2D).global_position.distance_to(Vector2(3200, 3200)) < (chop.trees[b] as Node2D).global_position.distance_to(Vector2(3200, 3200)))
	var cut := 0
	for k in keys:
		if cut >= 3: break
		if chop.state(self).has(k): continue
		await _fell_and_process(region, player, chop, k)
		cut += 1
	set_meta("player_energy", 100)
	check(BAG.count_item(self, "madeira") >= 13, "madeira suficiente após 4 árvores (%d)" % BAG.count_item(self, "madeira"))
	for i in 6: panel.call("_craft", "corda")
	panel.call("_craft", "bancada")
	check(BAG.count_item(self, "bancada") == 1, "fabricou a bancada (madeira + corda + pedra)")
	var placer: Node2D = region.get("placer")
	HOTBAR.select(self, HOTBAR.slots(self).find("bancada"))
	player.global_position = Vector2(3200, 3200)
	player.set("facing", "south")
	await physics_frame
	await process_frame
	check(placer.can_place(placer.spot_for(player)), "chão livre aceito para a bancada")
	if out != "": (await _shot()).save_png(out + "/bench_preview.png")
	await press("interact")
	check(BAG.count_item(self, "bancada") == 0 and get_meta("placed_stations", []).size() == 1, "bancada colocada e salva")
	check(not placer.can_place(placer.spot_for(player)), "não coloca outra em cima")
	await press("interact")
	check(panel.visible and panel.station == "bancada", "[E] na bancada abre a fabricação da bancada")
	panel.call("_craft", "enxada")
	panel.call("_craft", "regador")
	check(BAG.count_item(self, "enxada") == 1 and BAG.count_item(self, "regador") == 1, "enxada e regador feitos na bancada")
	if out != "": (await _shot()).save_png(out + "/bench_panel.png")
	await key(KEY_ESCAPE)
	player.global_position = Vector2(3200, 3150)
	await physics_frame
	if out != "": (await _shot()).save_png(out + "/bench_placed.png")
	print("CRAFTING_FLOW: %d failures" % failures)
	quit(1 if failures else 0)


func _fell_and_process(region: Node, player: Node2D, chop: Node, k: String) -> void:
	set_meta("player_energy", 100)
	var node: Node2D = chop.trees[k]
	player.global_position = node.global_position + Vector2(0, 20)
	await physics_frame
	await process_frame
	for i in chop.HITS_TO_FELL:
		await press("interact")
		await _swing_done()
	player.global_position = node.global_position + chop.LOG_OFFSET + Vector2(0, 16)
	await physics_frame
	await process_frame
	for i in chop.HITS_TO_PROCESS:
		await press("interact")
		await _swing_done()


## Espera o golpe terminar (duração vem da animação: o golpe aprovado tem pausas).
func _swing_done() -> void:
	var p: CharacterBody2D = root.find_child("Player", true, false)
	await process_frame
	for i in 600:
		if not p.is_using_tool(): break
		await process_frame
	await create_timer(0.1).timeout


func _shot() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

extends SceneTree
## Obra em etapas (playtest ID 40) na Floresta, um jogador: planta sem custo -> depósito
## parcial -> materiais completos (muda de cor) -> construir -> concluída uma vez; cancelar
## devolve; salvar/carregar obra incompleta; casa pequena e grande; lugar inválido.
## Dupla real (ID 24) em tools/test_mp_build.gd.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_build_stages.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const BUILD := preload("res://scripts/systems/build_site.gd")
const HOUSE := preload("res://scripts/systems/house_state.gd")
const SAVE := preload("res://scripts/systems/save_game.gd")
const PLACER := preload("res://scripts/world/station_placer.gd")
var failures := 0


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func _initialize() -> void:
	call_deferred("run")


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


## Tecla F de verdade (vale para a janela e para a ação "interact" no mesmo quadro).
func key_f() -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = KEY_F
		e.physical_keycode = KEY_F
		e.pressed = pressed
		Input.parse_input_event(e)
		await process_frame
		await process_frame


func wait_until(cond: Callable, seconds: float) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		if cond.call(): return true
		await process_frame
	return false


func entry_at(region_id: String, kind: String) -> Dictionary:
	for e: Dictionary in get_meta("placed_stations", []):
		if str(e.region) == region_id and str(e.kind) == kind and not bool(e.get("built", true)): return e
	return {}


func give(items: Dictionary) -> void:
	for item in items: BAG.add_item(self, item, int(items[item]))


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in ["forest_bag_items", "placed_stations", HOUSE.KEY, "tutorial_step"]:
		if has_meta(k): remove_meta(k)
	set_meta("tutorial_step", 99)  # sem balão do tutorial
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	await physics_frame
	var player: Node2D = region.get("player")
	var placer: Node2D = region.get("placer")
	var panel: Control = region.get("crafting_panel")
	var house: Node2D = region.get("house")
	Input.warp_mouse(Vector2.ZERO)  # prévia à frente do jogador
	player.global_position = Vector2(3200, 3200)
	player.set("facing", "south")
	await physics_frame

	# 1) Planta da bancada pela fabricação, sem nada na bolsa.
	panel.call("open", "maos")
	var rows: Array = panel.call("entries", "producao")
	var bench := rows.map(func(r: Dictionary) -> String: return str(r.id)).find("bancada")
	panel.set("selected", bench)
	panel.call("refresh")
	var action: Button = panel.get("_action")
	check(not action.disabled and action.text == "Colocar planta", "fabricação oferece colocar a planta sem material (%s)" % action.text)
	await key_f()  # [F] na janela aperta o botão; o mesmo [F] não confirma a planta
	check(not panel.visible and get_meta("placed_stations", []).is_empty() and (placer.get("_ghost") as Sprite2D).visible, "prévia aberta, nada colocado ainda")
	await press("interact")
	var site := entry_at(placer.region_id, "bancada")
	var id := BUILD.station_id(site) if not site.is_empty() else "?"
	check(not site.is_empty() and BUILD.stage(site) == "plan", "planta confirmada aguardando material")
	check(BAG.count_item(self, "graveto") == 0 and site.get("cost", {}) == {"graveto": 6, "pedra_pequena": 4, "corda": 2} and (site.get("deposited", {}) as Dictionary).is_empty(),
		"planta sem custo: guarda o custo da receita e nada depositado")
	if site.is_empty():
		quit(1)
		return

	# 2) Sem material: [F] não deposita nem constrói.
	player.global_position = Vector2(site.x, site.y) + Vector2(0, 20)
	await physics_frame
	await press("interact")
	await create_timer(0.5).timeout
	check(str(placer.get("_building")).is_empty() and float(site.progress) == 0.0, "sem material não começa a construir")
	check(not BUILD.work(self, id, 5.0) and float(site.progress) == 0.0, "obra recusa progresso antes de completar o material")

	# 3) Depósito parcial.
	give({"graveto": 3})
	await press("interact")
	check(int(site.deposited.get("graveto", 0)) == 3 and BAG.count_item(self, "graveto") == 0 and BUILD.stage(site) == "plan", "depósito parcial: 3/6 gravetos")
	var label: Label = (placer.call("_node", id) as Node2D).get_node("Needs")
	check(label.visible and label.text.contains("3/6"), "junto da obra aparece o que falta (%s)" % label.text.replace("\n", " | "))
	# 4) Completa (com sobra na bolsa): só leva o que falta, uma vez.
	give({"graveto": 10, "pedra_pequena": 4, "corda": 2})
	await press("interact")
	check(BUILD.stage(site) == "ready" and site.deposited == site.cost, "materiais completos")
	check(BAG.count_item(self, "graveto") == 7 and BAG.count_item(self, "pedra_pequena") == 0, "não cobra duas vezes nem leva a sobra (%d gravetos)" % BAG.count_item(self, "graveto"))
	var node: Node2D = placer.call("_node", id)
	var fill := (node.get_node("Sprite") as Sprite2D).material as ShaderMaterial
	check(fill != null and Color(fill.get_shader_parameter("plan_color")).is_equal_approx(PLACER.READY) and (node.get_node("Needs") as Label).text.contains("completos"),
		"pronta: planta muda de cor e avisa no texto")

	# 5) Construir sozinho (10 s); conclui uma vez.
	await press("interact")
	await create_timer(3.0).timeout
	check(str(placer.get("_building")) == id and BUILD.stage(site) == "building", "constrói depois de completar")
	var started := Time.get_ticks_msec()
	check(await wait_until(func() -> bool: return bool(site.built), 12.0), "bancada concluída")
	print("  solo: %.1f s depois dos 3 s" % ((Time.get_ticks_msec() - started) / 1000.0))
	await process_frame
	await process_frame
	check(not BUILD.work(self, id, 1.0) and BAG.count_item(self, "graveto") == 7, "conclui uma vez: mais obra não faz nada")
	node = placer.call("_node", id)
	check(node != null and (node.get_node("Sprite") as Sprite2D).material == null and (node.get_node("Body") as StaticBody2D).collision_layer == 2, "pronta: arte normal e sólida")

	# 6) Dois construtores somam (unidade da regra; dupla real em test_mp_build.gd).
	var a := BUILD.new_station("teste", Vector2(1, 1), "bau_campo", true)
	var b := BUILD.new_station("teste", Vector2(2, 2), "bau_campo", true)
	set_meta("placed_stations", get_meta("placed_stations") + [a, b])
	var solo_steps := 0
	while not bool(a.built) and solo_steps < 1000:
		BUILD.work(self, BUILD.station_id(a), 0.1)
		solo_steps += 1
	var duo_steps := 0
	while not bool(b.built) and duo_steps < 1000:
		BUILD.work(self, BUILD.station_id(b), 0.1)
		BUILD.work(self, BUILD.station_id(b), 0.1)
		duo_steps += 1
	check(duo_steps * 2 <= solo_steps + 1, "dupla termina na metade do tempo (%d x %d passos)" % [duo_steps, solo_steps])

	# 7) Cancelar devolve o depositado.
	var sticks := BAG.count_item(self, "graveto")
	player.global_position = Vector2(3200, 3330)
	player.set("facing", "south")
	await physics_frame
	placer.call("begin_plan", "bancada")
	await process_frame
	await press("interact")
	var other := entry_at(placer.region_id, "bancada")
	check(not other.is_empty() and BAG.count_item(self, "graveto") == sticks, "segunda planta, sem custo")
	player.global_position = Vector2(other.x, other.y) + Vector2(0, 20)
	await physics_frame
	await press("interact")  # deposita os 6 gravetos que sobraram
	check(int(other.deposited.get("graveto", 0)) == 6, "depositou na segunda planta")
	placer.call("cancel_site", BUILD.station_id(other))
	check(entry_at(placer.region_id, "bancada").is_empty() and BAG.count_item(self, "graveto") == sticks, "cancelar tira a planta e devolve o depositado")

	# 8) Salvar e carregar uma obra incompleta.
	placer.call("begin_plan", "bancada")
	await process_frame
	await press("interact")
	var keep := entry_at(placer.region_id, "bancada")
	player.global_position = Vector2(keep.x, keep.y) + Vector2(0, 20)
	await physics_frame
	await press("interact")  # 6 gravetos
	SAVE.path = "user://test_build_stages_save.txt"
	check(SAVE.save(self, root.get_node("GameClock"), region.scene_file_path), "salvou com a obra incompleta")
	remove_meta("placed_stations")
	check(SAVE.restore(self, root.get_node("GameClock")) != "", "carregou o save")
	SAVE.delete()
	SAVE.path = SAVE.DEFAULT_PATH
	set_meta("tutorial_step", 99)
	placer.call("reload")
	var back := entry_at(placer.region_id, "bancada")
	check(not back.is_empty() and BUILD.stage(back) == "plan" and int(back.deposited.get("graveto", 0)) == 6 and placer.call("_node", BUILD.station_id(back)) != null,
		"obra incompleta volta do save com o depositado")
	placer.call("cancel_site", BUILD.station_id(back))

	# 9) Casa pequena (mínima) e grande: planta sem custo, depósito e construção.
	BAG.spend_item(self, "graveto", BAG.count_item(self, "graveto"))
	var origin := Vector2i((player.global_position / 32.0).floor()) + Vector2i(3, -2)
	var small := Rect2i(origin, HOUSE.MIN_SIZE)
	for tries in 60:
		if HOUSE.place_problem(self, small, house.blocked_world, house.player_cell()).is_empty() and placer.can_place(Vector2(small.position * 32)): break
		small.position += Vector2i(1, 1) if tries % 2 == 0 else Vector2i(-2, 1)
	house.toggle_build()
	house.mode = "house"
	check(house.build_rect(Rect2i(small.position, Vector2i(4, 4))).contains("Pequena demais"), "área menor que o mínimo é recusada")
	check(house.build_rect(small) == "" and HOUSE.planned(self) and not HOUSE.exists(self), "casa pequena: planta marcada sem material")
	check(house.build_rect(small.grow(1)).contains("Já há uma planta"), "sobreposição: só uma planta de casa")
	check(house.get_node("HouseCollision").get_child_count() == 0, "planta da casa não bloqueia a passagem")
	house.toggle_build()
	await process_frame
	var plan_node: Node2D = placer.call("_node", BUILD.HOUSE_ID)
	check(plan_node != null, "obra da casa aparece junto da planta")
	var cost := HOUSE.rect_cost(small)
	check(HOUSE.data(self).cost == cost, "custo da casa pelo tamanho (%s)" % HOUSE.cost_text(cost))
	check(not placer.can_place(Vector2(small.get_center() * 32)), "bancada não entra na planta da casa")
	player.global_position = plan_node.global_position + Vector2(0, 18)
	await physics_frame
	give({"madeira": 10})
	await press("interact")
	var hsite := BUILD.find(self, BUILD.HOUSE_ID)
	check(int(hsite.deposited.get("madeira", 0)) == 10 and BUILD.stage(hsite) == "plan", "casa: depósito parcial (10 madeiras)")
	give(BUILD.remaining(hsite))
	await press("interact")
	check(BUILD.stage(hsite) == "ready", "casa: materiais completos")
	await press("interact")
	await create_timer(1.0).timeout
	check(BUILD.stage(hsite) == "building" and str(placer.get("_building")) == BUILD.HOUSE_ID, "casa: construindo")
	BUILD.work(self, BUILD.HOUSE_ID, BUILD.time_of(hsite) - float(hsite.progress) - 0.3)  # adianta a obra
	check(await wait_until(func() -> bool: return HOUSE.exists(self), 5.0), "casa concluída pela construção")
	await process_frame
	await process_frame
	check(house.get_node("HouseCollision").get_child_count() > 10 and placer.call("_node", BUILD.HOUSE_ID) == null and str(placer.get("_building")).is_empty(), "casa pronta: paredes sólidas, obra sai")
	check(HOUSE.demolish(self), "demolir a casa pronta")
	var big := Rect2i(small.position, Vector2i(12, 8))
	for tries in 60:
		if HOUSE.place_problem(self, big, house.blocked_world, house.player_cell()).is_empty(): break
		big.position += Vector2i(1, 1) if tries % 2 == 0 else Vector2i(-2, 1)
	var wood := BAG.count_item(self, "madeira")
	house.toggle_build()
	house.mode = "house"
	check(house.build_rect(big) == "" and HOUSE.planned(self) and BAG.count_item(self, "madeira") == wood, "casa grande: planta sem custo")
	check(int(HOUSE.data(self).cost.madeira) > int(cost.madeira) and BUILD.time_of(HOUSE.data(self)) > BUILD.time_of({"time": 8.0 + 0.25 * small.get_area()}), "casa grande custa e demora mais")
	house.toggle_build()
	await process_frame
	plan_node = placer.call("_node", BUILD.HOUSE_ID)
	player.global_position = plan_node.global_position + Vector2(0, 18)
	await physics_frame
	await press("interact")
	var deposited := int(BUILD.find(self, BUILD.HOUSE_ID).deposited.get("madeira", 0))
	check(deposited > 0 and BAG.count_item(self, "madeira") == wood - deposited, "casa grande: depositou %d madeiras" % deposited)
	house.toggle_build()
	house.mode = "house"
	check(house.erase_at(big.position + Vector2i(1, 1)) and not HOUSE.planned(self) and BAG.count_item(self, "madeira") == wood, "cancelar a planta da casa devolve a madeira")
	house.toggle_build()
	print("BUILD_STAGES: %d failures" % failures)
	quit(1 if failures else 0)

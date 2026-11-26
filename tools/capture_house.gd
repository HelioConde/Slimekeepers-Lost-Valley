extends SceneTree
## Casa construída pelo jogador na Floresta (CASA.md): sem casa no início; modo
## construir [B], arrastar um retângulo (prévia verde/vermelha e custo), construir
## com materiais, mobiliar, entrar e dormir na cama; não deixa construir uma segunda.
##   godot --path . --rendering-driver opengl3 --script res://tools/capture_house.gd -- [pasta]

const House := preload("res://scripts/systems/house_state.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func shot(path: String) -> void:
	if path.begins_with("/"): return  # sem pasta de saída
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else ""
	if not out.is_empty(): DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for key in [House.KEY, Bag.INVENTORY_KEY]:
		if has_meta(key): remove_meta(key)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	await physics_frame
	var house: Node2D = region.get("house")
	var player: Node2D = region.get("player")
	check(is_instance_valid(house) and not House.exists(self), "Floresta: sem casa no início, construtor presente")
	(player.get_node("Camera2D") as Camera2D).position_smoothing_enabled = false
	# Área livre perto do início.
	var origin := Vector2i((player.global_position / 32.0).floor()) + Vector2i(3, -2)
	var rect := Rect2i(origin, Vector2i(7, 5))
	for tries in 40:
		if House.build_problem(self, rect, house.blocked_world, house.player_cell()).begins_with("Falta"): break
		rect.position += Vector2i(1, 1) if tries % 2 == 0 else Vector2i(-2, 1)
	house.toggle_build()
	house.mode = "house"
	house.drag_start = rect.position
	house.cursor_cell = rect.end - Vector2i.ONE
	check(house.build_hint().contains("7×5") and house.build_hint().contains("madeira"), "Prévia do arraste mostra tamanho e custo")
	await shot(out + "/casa_arrastando.png")
	# Menor que o mínimo: aviso na dica, recusa sem gastar nada (ID 49).
	house.cursor_cell = rect.position + Vector2i(3, 3)
	check(house.build_hint().contains("Pequena demais (mínimo 5×5)"), "Arrastar menor que o mínimo avisa na dica (%s)" % house.build_hint())
	check(house.build_rect(house.drag_area()).contains("Pequena demais") and not House.exists(self), "Casa menor que o mínimo é recusada")
	await shot(out + "/casa_pequena_demais.png")
	house.cursor_cell = rect.end - Vector2i.ONE
	check(house.build_rect(rect).begins_with("Falta"), "Sem material não constrói")
	var cost := House.rect_cost(rect)
	for item in cost: Bag.add_item(self, item, int(cost[item]))
	for item in House.FURNITURE_COSTS.cama: Bag.add_item(self, item, int(House.FURNITURE_COSTS.cama[item]))
	for item in House.FURNITURE_COSTS.mesa: Bag.add_item(self, item, int(House.FURNITURE_COSTS.mesa[item]))
	check(house.build_rect(rect) == "", "Arraste constrói a casa %s (%s)" % [str(rect), House.cost_text(cost)])
	house.drag_start = null
	check(house.get_node("HouseCollision").get_child_count() > 10, "Paredes sólidas")
	house.mode = "furniture"
	house.furniture_choice = "cama"
	check(house.place_at(rect.position + Vector2i(1, 1)), "Cama colocada (paga)")
	house.furniture_choice = "mesa"
	check(house.place_at(rect.position + Vector2i(4, 2)), "Mesa colocada (paga)")
	house.mode = "house"
	house.drag_start = rect.position + Vector2i(12, 0)
	house.cursor_cell = rect.position + Vector2i(17, 4)
	check(house.build_rect(house.drag_area()).contains("já tem uma casa"), "Só uma casa no jogo")
	house.drag_start = null
	house.toggle_build()
	await shot(out + "/casa_fora.png")
	player.global_position = Vector2(rect.position * 32) + Vector2(2 * 32 + 16, 2 * 32 + 16)
	for i in 3: await physics_frame
	await shot(out + "/casa_dentro.png")
	# Porta: a célula da porta e a soleira são piso interno (ID 51), não capim de fora.
	var door_px: Rect2 = house.door_floor_rect()
	check(door_px.position == Vector2(House.door_of(rect) * 32) and door_px.size.x == 32.0 and door_px.size.y > 32.0 and not house.house().wall.has(House.door_of(rect)),
		"Célula da porta usa o piso interno (%s)" % str(door_px))
	check(house.near_bed(player), "Perto da cama pode dormir")
	# Fogão: cozinhar porções (substitui a fogueira do Vale).
	var Cooking := preload("res://scripts/systems/valley_cooking.gd")
	for item in House.FURNITURE_COSTS.fogao: Bag.add_item(self, item, int(House.FURNITURE_COSTS.fogao[item]))
	house.toggle_build()
	house.mode = "furniture"
	house.furniture_choice = "fogao"
	check(house.place_at(rect.position + Vector2i(5, 1)), "Fogão colocado (pago)")
	house.toggle_build()
	Bag.add_leaves(self)
	player.global_position = Vector2((rect.position + Vector2i(5, 2)) * 32) + Vector2(16, 16)
	for i in 3: await physics_frame
	for i in 3: await process_frame  # o HUD da região atualiza no _process
	check(house.near_furniture(player, "fogao") and str(region.hud_hint.text).contains("Cozinhar"), "Fogão oferece cozinhar (%s)" % region.hud_hint.text)
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
	await process_frame
	var stove_panel: Control = region.get("crafting_panel")
	check(stove_panel.visible and str(stove_panel.station) == "fogao", "[E] no fogão abre as receitas do fogão")
	stove_panel.call("_craft", "porcao_folhas_prototipo")
	check(Cooking.portions(self) == 1, "Cozinhou uma porção no fogão")
	Bag.add_item(self, "cenoura", 3)
	Bag.add_item(self, "beterraba", 1)
	Bag.add_item(self, "repolho", 1)
	stove_panel.call("_craft", "sopa_legumes")
	stove_panel.call("_craft", "cenoura_assada")
	check(Bag.count_item(self, "sopa_legumes") == 1 and Bag.count_item(self, "cenoura_assada") == 1 and Bag.count_item(self, "cenoura") == 0,
		"Sopa (cenoura+beterraba+repolho) e cenoura assada (2 cenouras) no fogão")
	stove_panel.call("close")
	await process_frame
	player.global_position = Vector2(rect.position * 32) + Vector2(2 * 32 + 16, 2 * 32 + 16)
	var clock := root.get_node("GameClock")
	var day: int = clock.day_number
	region.sleep_until_morning()
	check(clock.day_number == day + 1 and clock.get_hour() == 6, "Dormir na cama leva ao dia seguinte 06:00")
	# Baú: [E] abre a janela, E guarda a pilha da bolsa; cheio, não demole a casa.
	var Chest := preload("res://scripts/systems/chest_storage.gd")
	if has_meta(Chest.KEY): remove_meta(Chest.KEY)
	for item in House.FURNITURE_COSTS.bau: Bag.add_item(self, item, int(House.FURNITURE_COSTS.bau[item]))
	house.toggle_build()
	house.mode = "furniture"
	house.furniture_choice = "bau"
	check(house.place_at(rect.position + Vector2i(1, 3)), "Baú colocado (pago)")
	house.toggle_build()
	Bag.add_item(self, "graveto", 7)
	player.global_position = Vector2((rect.position + Vector2i(2, 3)) * 32) + Vector2(16, 16)
	for i in 3: await physics_frame
	for i in 3: await process_frame
	check(str(region.hud_hint.text).contains("baú"), "Baú oferece abrir (%s)" % region.hud_hint.text)
	await _tap("interact")
	var panel: Control = region.get_node_or_null("HUD/Interface/ChestPanel")
	check(panel != null and panel.visible, "[E] abre a janela do baú")
	if panel != null:
		var row: int = panel.entries(0).map(func(e: Array) -> String: return e[0]).find("graveto")
		panel.selected = row
		panel.move_selected()
		check(Chest.count(self, "graveto") == 7 and Bag.count_item(self, "graveto") == 0, "E guarda a pilha de gravetos no baú")
		await _key(KEY_ESCAPE)
		check(not panel.visible, "Esc fecha o baú")
	house.toggle_build()
	house.mode = "house"
	check(not house.erase_at(rect.position + Vector2i(2, 2)) and house.problem.contains("Esvazie"), "Baú cheio impede demolir a casa")
	house.toggle_build()
	# Acordado depois da meia-noite: desmaia e acorda às 06:00 ao lado da cama.
	clock.set_time(23, 59)
	player.global_position = Vector2(rect.position * 32) + Vector2(-64, -64)
	var faint_day: int = clock.day_number
	clock.advance_minutes(2.0)
	check(clock.day_number == faint_day + 1 and clock.get_hour() == 6, "Meia-noite acordado: desmaia e acorda às 06:00")
	check(int(get_meta("player_energy")) == region.FAINT_ENERGY, "Desmaio deixa metade da energia")
	check(house.near_bed(player), "Acorda ao lado da cama da casa")
	print("HOUSE: %d failures" % failures)
	quit(1 if failures else 0)


func _tap(action: String) -> void:
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


func _key(code: int) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	root.push_input(e)
	await process_frame
	await process_frame

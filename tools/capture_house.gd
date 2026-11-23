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
	check(Cooking.portions(self) == 1, "Cozinhou uma porção no fogão")
	player.global_position = Vector2(rect.position * 32) + Vector2(2 * 32 + 16, 2 * 32 + 16)
	var clock := root.get_node("GameClock")
	var day: int = clock.day_number
	region.sleep_until_morning()
	check(clock.day_number == day + 1 and clock.get_hour() == 6, "Dormir na cama leva ao dia seguinte 06:00")
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

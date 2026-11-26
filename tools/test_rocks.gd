extends SceneTree
## Pedras e recursos pelo mapa (pedido do usuário, 2026-11-23), na Floresta:
## - gravetos e pedras pequenas espalhados pelo mapa todo (não só perto do início);
## - pedras médias só com picareta (3 golpes, soltam 3 pedras pequenas);
## - pedras grandes pedem uma picareta melhor.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_rocks.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func press() -> void:
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


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in [BAG.INVENTORY_KEY, "rocks_broken", "forage_taken"]:
		if has_meta(k): remove_meta(k)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 40: await process_frame
	var gathering: Node = region.get("gathering")
	var forage: Node2D = gathering.forage
	var far: Array = forage.spots.filter(func(s: Dictionary) -> bool: return s.item in ["graveto", "pedra_pequena"] and s.at.distance_to(Vector2(3200, 3200)) > 600.0)
	check(far.size() >= 80, "gravetos e pedras longe do início (%d)" % far.size())
	var rocks: Node2D = gathering.rocks
	var medium: Array = rocks.rocks.values().filter(func(r: Dictionary) -> bool: return r.kind == "medium")
	var large: Array = rocks.rocks.values().filter(func(r: Dictionary) -> bool: return r.kind == "large")
	check(medium.size() >= 30 and large.size() >= 10, "pedras médias (%d) e grandes (%d) pelo mapa" % [medium.size(), large.size()])
	var player: Node2D = region.get("player")
	var rock: Dictionary = medium[0]
	player.global_position = rock.at + Vector2(0, -30)  # acima da pedra: golpe de frente
	for i in 4: await physics_frame
	for i in 3: await process_frame
	check(str(region.hud_hint.text).contains("picareta"), "sem picareta, a pedra média pede uma (%s)" % region.hud_hint.text)
	BAG.add_item(self, "picareta", 1)
	HOTBAR.select(self, HOTBAR.slots(self).find("picareta"))
	set_meta("player_energy", 100)
	for i in 3: await process_frame
	var before := BAG.count_item(self, "pedra_pequena")
	for i in 3:
		await press()
		if i == 0: check(str(player.get("current_animation")) == "pickaxe_south", "golpe próprio da picareta (%s)" % player.get("current_animation"))
		if i == 0: check(rocks.hits(rock.id) == 0, "pedra intacta até o contato da picareta (playtest ID 55)")
		while player.is_using_tool(): await process_frame
	check(not (rock.node as Node2D).visible, "3 golpes de picareta quebram a pedra média")
	region.get("item_drops").collect_all()
	check(BAG.count_item(self, "pedra_pequena") == before + 3, "pedra média solta 3 pedras pequenas")
	var big: Dictionary = large[0]
	player.global_position = big.at + Vector2(0, 40)
	for i in 4: await physics_frame
	for i in 3: await process_frame
	check(str(region.hud_hint.text).contains("picareta melhor"), "pedra grande aceita a picareta rudimentar e sugere uma melhor (%s)" % region.hud_hint.text)  # ID 54
	# Nível 2 (pedra polida): cada golpe vale 2; a picareta polida quebra a pedra grande.
	BAG.add_item(self, "picareta_polida", 1)
	set_meta("player_energy", 100)
	for i in 3: await process_frame
	await press()  # primeiro toque troca para a picareta polida (melhor da bolsa)
	for i in 2: await process_frame
	check(HOTBAR.selected_item(self) == "picareta_polida", "pedra grande escolhe a picareta polida (%s)" % HOTBAR.selected_item(self))
	before = BAG.count_item(self, "pedra_pequena")
	for i in 3:
		await press()
		if i == 0: check(str(player.get("current_animation")).begins_with("pickaxe_polished_"), "golpe com a cabeça de pedra polida (%s)" % player.get("current_animation"))
		while player.is_using_tool(): await process_frame
	check(not (big.node as Node2D).visible, "3 golpes da picareta polida quebram a pedra grande")
	region.get("item_drops").collect_all()
	check(BAG.count_item(self, "pedra_pequena") == before + 8, "pedra grande solta 8 pedras pequenas")
	# Machado polido: derruba a árvore grande (6 golpes = 3 de pedra polida) e rende o dobro.
	var trees: Node = gathering.choppable
	var big_tree := ""
	for key: String in trees.trees:
		if not trees.is_small(key) and (trees.trees[key] as Node2D).global_position.distance_to(Vector2(3200, 3200)) < 2500.0:
			big_tree = key
			break
	check(not big_tree.is_empty(), "há árvore grande cortável")
	if not big_tree.is_empty():
		check(trees.fell_hits(big_tree) == 6 and trees.wood(big_tree) == 8, "árvore grande: 6 golpes, 8 madeiras")
		var t := {"key": big_tree, "kind": "tree"}
		var results: Array = []
		for i in 3: results.append(trees.strike(t, 1, 2))
		check(results == ["hit", "hit", "felled"], "machado polido (vale 2) derruba a árvore grande em 3 golpes (%s)" % [results])
		var log: Sprite2D = trees._extras[big_tree][1]
		var log_len: float = 83.0 * absf(log.global_scale.x)
		check(log_len <= trees.visible_height(big_tree) * 0.5, "tronco caído menor que a árvore (%.0f px x %.0f px de altura; playtest ID 44)" % [log_len, trees.visible_height(big_tree)])
	# ID 53: com a picareta na mão, um toque recolhe o monte de pedrinhas.
	var pebbles: Array = forage.spots.filter(func(sp: Dictionary) -> bool: return sp.item == "pedra_pequena" and not forage.is_taken(self, sp.id, root.get_node("GameClock").day_number))
	if not pebbles.is_empty():
		var sp: Dictionary = pebbles[0]
		HOTBAR.select(self, HOTBAR.slots(self).find("picareta"))
		player.global_position = sp.at + Vector2(0, -18)
		for i in 4: await physics_frame
		for i in 3: await process_frame
		var had := BAG.count_item(self, "pedra_pequena")
		await press()
		while player.is_using_tool(): await process_frame
		for i in 3: await process_frame
		region.get("item_drops").collect_all()
		check(BAG.count_item(self, "pedra_pequena") == had + 1, "um toque com a picareta recolhe as pedrinhas (playtest ID 53)")
	print("ROCKS: %d failures" % failures)
	quit(1 if failures else 0)

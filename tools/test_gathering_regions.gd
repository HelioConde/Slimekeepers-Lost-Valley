extends SceneTree
## Regressão: cortar árvore e arrancar mato funcionam fora da Clareira — na Floresta
## longe do início e no Vale das Nascentes (o bug era só existir na Floresta).
## Mato: 3 s segurando [E]; 2 s não arranca.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_gathering_regions.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const REGIONS := {"floresta": "res://scenes/regions/FlorestaDoDespertarV2.tscn",
	"vale": "res://scenes/regions/ValeDasNascentes.tscn"}
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


func hold(seconds: float) -> void:
	var down := InputEventAction.new()
	down.action = "interact"
	down.pressed = true
	Input.parse_input_event(down)
	await create_timer(seconds).timeout
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	await process_frame


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for name: String in REGIONS:
		for k in ["forest_bag_items", "forage_taken", "chopped_trees"]:
			if has_meta(k): remove_meta(k)
		var region: Node2D = load(REGIONS[name]).instantiate()
		root.add_child(region)
		for i in 30: await process_frame
		await physics_frame
		for i in 5: await process_frame
		var gathering: Node = region.get("gathering")
		check(is_instance_valid(gathering), "%s: tem corte e coleta" % name)
		if not is_instance_valid(gathering):
			region.queue_free()
			await process_frame
			continue
		var player: Node2D = region.get("player")
		var spawn: Vector2 = player.global_position
		var chop: Node = gathering.choppable
		check(chop.trees.size() > 10, "%s: árvores cortáveis (%d)" % [name, chop.trees.size()])
		BAG.add_item(self, "machado")
		for i in 3: await process_frame
		HOTBAR.select(self, HOTBAR.slots(self).find("machado"))
		# Machado rudimentar: árvore grande não cai (aviso de machado melhor).
		var big_key := ""
		var small_key := ""
		for key: String in chop.trees:
			var d: float = (chop.trees[key] as Node2D).global_position.distance_to(spawn)
			if chop.is_small(key):
				if small_key == "" or d > (chop.trees[small_key] as Node2D).global_position.distance_to(spawn): small_key = key
			elif big_key == "":
				big_key = key
		if big_key != "":
			var big: Node2D = chop.trees[big_key]
			player.global_position = big.global_position + Vector2(0, 14)
			await physics_frame
			for i in 3: await process_frame
			await press()
			await create_timer(1.1).timeout
			check(not chop.state(self).has(big_key) and str(region.hud_hint.text).contains("machado melhor"), "%s: árvore grande pede machado melhor" % name)
		# Árvore pequena mais longe do início cai (o Vale só tem árvores grandes).
		if name == "vale":
			check(small_key == "", "vale: só árvores grandes (machado rudimentar não corta)")
		else:
			var tree: Node2D = chop.trees[small_key]
			player.global_position = tree.global_position + Vector2(0, 14)
			await physics_frame
			for i in 3: await process_frame
			for i in chop.HITS_TO_FELL:
				await press()
				await create_timer(1.1).timeout
			check(chop.state(self).has(small_key), "%s: árvore pequena longe do início cai (%s, %d px)" % [name, small_key, int(tree.global_position.distance_to(spawn))])
			var stump: Sprite2D = tree.get_child(tree.get_child_count() - 2) as Sprite2D
			check(stump != null and is_equal_approx(stump.scale.x, chop.STUMP_SCALE * chop.tree_scale(small_key)), "%s: toco proporcional à árvore" % name)
		HOTBAR.select(self, -1)
		if name == "vale":
			var sticks: Array = gathering.forage.spots.filter(func(s: Dictionary) -> bool: return s.item in ["graveto", "pedra_pequena"])
			check(sticks.size() >= 8 and sticks.all(func(s: Dictionary) -> bool: return str(s.id).begins_with("vale_")), "vale: gravetos e pedras com ids próprios (%d)" % sticks.size())
		# Mato longe do início.
		var mato: Array = gathering.forage.spots.filter(func(s: Dictionary) -> bool: return s.item == "fibra")
		check(mato.size() > 10, "%s: mato coletável (%d)" % [name, mato.size()])
		mato.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at.distance_to(spawn) > b.at.distance_to(spawn))
		var got := false
		for spot: Dictionary in mato.slice(0, 8):
			var before := BAG.count_item(self, "fibra")
			player.global_position = spot.at + Vector2(0, 6)
			await physics_frame
			for i in 3: await process_frame
			if gathering.forage.nearest(player.global_position, root.get_node("GameClock").day_number).get("id", "") != spot.id: continue
			await hold(2.0)
			check(BAG.count_item(self, "fibra") == before, "%s: 2 s segurando não arranca" % name)
			await hold(3.3)
			got = BAG.count_item(self, "fibra") == before + 1
			break
		check(got, "%s: 3 s segurando arranca mato longe do início" % name)
		region.queue_free()
		await process_frame
		await process_frame
	print("GATHERING_REGIONS: %d failures" % failures)
	quit(1 if failures else 0)

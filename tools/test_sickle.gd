extends SceneTree
## Foice: corta o mato de um golpe e às vezes solta semente; com a mão, mato só dá fibra.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_sickle.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func seeds() -> int:
	var n := 0
	for s in ["semente_cenoura", "semente_beterraba", "semente_repolho", "sementes_silvestres"]: n += BAG.count_item(self, s)
	return n


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in [BAG.INVENTORY_KEY, "forage_taken"]:
		if has_meta(k): remove_meta(k)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var forage: Node = region.get("forage")
	var gathering: Node = region.get("gathering")
	var player: Node2D = region.get("player")
	var drops: Node = region.get("item_drops")
	var day: int = root.get_node("GameClock").day_number
	var mato: Array = forage.spots.filter(func(s: Dictionary) -> bool: return s.item == "fibra")
	BAG.add_item(self, "foice")
	for i in 3: await process_frame
	var before := seeds()
	# Semente sorteada: escolhe a semente do sorteio para cair na primeira tentativa.
	for s in 1000:
		var r := RandomNumberGenerator.new()
		r.seed = s
		if r.randf() < gathering.SEED_CHANCE:
			gathering.rng.seed = s
			break
	HOTBAR.select(self, HOTBAR.slots(self).find("foice"))
	# Um ponto de mato com vizinhos no raio do golpe (área, playtest ID 09).
	var spot: Dictionary = mato[0]
	for cand: Dictionary in mato:
		if gathering.sickle_targets(cand.at).size() >= 2:
			spot = cand
			break
	var in_arc: Array = gathering.sickle_targets(spot.at)
	var outside: Array = mato.filter(func(s: Dictionary) -> bool:
		var d: float = (s.at as Vector2).distance_to(spot.at)
		return d > gathering.SICKLE_RADIUS + 8.0 and d < gathering.SICKLE_RADIUS + 60.0)
	player.global_position = spot.at + Vector2(0, 6)
	for i in 4: await physics_frame
	check(str(region.hud_hint.text).contains("foice"), "com a foice o mato oferece cortar (%s)" % region.hud_hint.text)
	Input.action_press("interact")
	for i in 3: await process_frame
	check(str(player.get("current_animation")).begins_with("sickle_"), "golpe próprio da foice, de lado (%s)" % player.get("current_animation"))
	Input.action_release("interact")
	await create_timer(0.5).timeout
	drops.collect_all()
	check(forage.is_taken(self, spot.id, day), "um golpe corta o mato")
	check(in_arc.size() >= 2 and in_arc.all(func(s: Dictionary) -> bool: return forage.is_taken(self, s.id, day)), "um golpe corta todo o mato do arco (%d tufos; playtest ID 09)" % in_arc.size())
	check(outside.is_empty() or outside.all(func(s: Dictionary) -> bool: return not forage.is_taken(self, s.id, day)), "mato fora do arco fica (%d)" % outside.size())
	check(BAG.count_item(self, "fibra") >= 1 and seeds() >= before + 1, "foice dá fibra e, com sorte, semente (fibra %d, sementes %d)" % [BAG.count_item(self, "fibra"), seeds() - before])
	# Com a mão: arranca (3 s) e não dá semente.
	HOTBAR.select(self, -1)
	while player.is_using_tool(): await process_frame  # termina o golpe da foice
	var spot2: Dictionary = mato.filter(func(s: Dictionary) -> bool: return (s.at as Vector2).distance_to(spot.at) > 300.0)[0]
	player.global_position = spot2.at + Vector2(0, 6)
	for i in 4: await physics_frame
	var seeds_hand := seeds()
	Input.action_press("interact")
	for i in 3: await process_frame
	Input.action_release("interact")
	await create_timer(3.6).timeout
	drops.collect_all()
	check(forage.is_taken(self, spot2.id, day) and seeds() == seeds_hand, "com a mão o mato não dá semente")
	print("SICKLE: %d failures" % failures)
	quit(1 if failures else 0)

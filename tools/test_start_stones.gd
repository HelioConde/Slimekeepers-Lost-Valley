extends SceneTree
## Playtest ID 19: pedrinha decorativa ao lado do jogador parecia coletável e não era.
## Toda pedrinha visível (arte pebbles.png) perto do spawn precisa ser ponto de coleta.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const FOREST := "res://scenes/regions/FlorestaDoDespertarV2.tscn"
const RADIUS := 600.0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, what: String) -> void:
	if ok: print("PASS: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _run() -> void:
	var forest := load(FOREST).instantiate() as Node2D
	root.add_child(forest)
	current_scene = forest
	for i in 12: await physics_frame
	var forage: Node2D = forest.forage
	forage.drop = Callable()  # direto na bolsa
	var spawn: Vector2 = forest.player.global_position
	var by_sprite := {}
	for s in forage.spots: if s.has("sprite"): by_sprite[s.sprite] = s
	var found := 0
	var stack: Array = [forest]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		var sp := n as Sprite2D
		if sp == null or sp.texture == null or not sp.is_visible_in_tree(): continue
		if not sp.texture.resource_path.ends_with("ground/pebbles.png"): continue
		if sp.global_position.distance_to(spawn) > RADIUS: continue
		found += 1
		check(by_sprite.has(sp) and by_sprite[sp].item == "pedra_pequena", "pedrinha %s é ponto de coleta" % sp.get_path())
	check(found > 0, "há pedrinhas visíveis perto do spawn (%d)" % found)
	var near: Dictionary = forage.nearest(spawn, root.get_node("GameClock").day_number)
	for s in forage.spots:
		if s.item == "pedra_pequena" and s.sprite.visible and s.at.distance_to(spawn) < RADIUS:
			near = s
			break
	if not near.is_empty():
		var day: int = root.get_node("GameClock").day_number
		var before := BAG.count_item(self, "pedra_pequena")
		check(forage.nearest(near.at, day).get("id", "") == near.id, "alvo encontrado ao lado da pedrinha")
		check(forage.take(near, day) == "", "coleta aceita")
		check(BAG.count_item(self, "pedra_pequena") == before + 1, "coletar dá 1 pedra_pequena")
		check(not near.sprite.visible and forage.nearest(near.at, day).get("id", "") != near.id, "pedrinha some e não coleta de novo")
	print("START_STONES: %d failures" % failures)
	quit(1 if failures > 0 else 0)

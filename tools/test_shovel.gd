extends SceneTree
## Pá (relatório de playtest ID 30): feita na bancada; perto de um toco, [F] cava e o toco
## sai no contato, dá 1 madeira e o lugar fica livre de vez (a árvore não volta).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_shovel.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var recipes: Array = load("res://data/crafting/recipes.gd").RECIPES
	check(recipes.any(func(r: Dictionary) -> bool: return r.id == "pa" and r.station == "bancada" and r.category == "ferramentas"), "pá na aba Ferramentas da bancada")
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var clock: Node = root.get_node("GameClock")
	var chop: Node = region.get("gathering").choppable
	var player: Node2D = region.get("player")
	var spawn := Vector2(3200, 3200)
	var key := ""
	for k: String in chop.trees:
		if not (chop.trees[k] as CanvasItem).is_visible_in_tree(): continue
		if key == "" or (chop.trees[k] as Node2D).global_position.distance_to(spawn) < (chop.trees[key] as Node2D).global_position.distance_to(spawn): key = k
	var at: Vector2 = (chop.trees[key] as Node2D).global_position
	for i in chop.fell_hits(key): chop.strike({"key": key, "kind": "tree"}, clock.day_number, 1, at + Vector2.LEFT * 30)
	BAG.add_item(self, "pa", 1)
	HOTBAR.select(self, HOTBAR.slots(self).find("pa"))
	set_meta("player_energy", 100)
	player.global_position = at + Vector2(0, 26)
	for i in 4: await physics_frame
	for i in 3: await process_frame
	check(str(region.hud_hint.text).contains("toco"), "com a pá, o toco oferece arrancar (%s)" % region.hud_hint.text)
	var wood := BAG.count_item(self, "madeira")
	var down := InputEventAction.new()
	down.action = "interact"
	down.pressed = true
	Input.parse_input_event(down)
	for i in 3: await process_frame
	var anim := str(player.get("current_animation"))
	check(anim.begins_with("shovel_") or anim.begins_with("hoe_"), "cava com a pá (%s)" % anim)
	check(not bool((chop.state(self)[key] as Dictionary).get("stump_removed", false)), "toco fica até o contato da pá")
	var up := InputEventAction.new()
	up.action = "interact"
	Input.parse_input_event(up)
	while player.is_using_tool(): await process_frame
	for i in 3: await process_frame
	region.get("item_drops").collect_all()
	check(bool((chop.state(self)[key] as Dictionary).get("stump_removed", false)), "o toco saiu")
	check(BAG.count_item(self, "madeira") == wood + 1, "arrancar o toco dá 1 madeira")
	chop.apply_day(clock.day_number + 10)
	check(chop.state(self).has(key) and not (chop.trees[key].get_node("Sprite") as CanvasItem).visible, "sem toco, a árvore não volta a crescer")
	print("SHOVEL: %d failures" % failures)
	quit(1 if failures else 0)

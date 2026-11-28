extends SceneTree
## Tocos e troncos de cenário (relatório de playtest ID 50): o machado processa o tronco
## caído em madeira; a pá arranca o toco; os dois somem de vez.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_scenery_wood.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func swing(player: Node2D) -> void:
	var down := InputEventAction.new()
	down.action = "interact"
	down.pressed = true
	Input.parse_input_event(down)
	for i in 3: await process_frame
	var up := InputEventAction.new()
	up.action = "interact"
	Input.parse_input_event(up)
	while player.is_using_tool(): await process_frame
	for i in 3: await process_frame


func run() -> void:
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var chop: Node = region.get("gathering").choppable
	var player: Node2D = region.get("player")
	var logs: Array = chop.scenery.keys().filter(func(k: String) -> bool: return chop.scenery[k].kind == "log")
	var stumps: Array = chop.scenery.keys().filter(func(k: String) -> bool: return chop.scenery[k].kind == "stump")
	check(not logs.is_empty() and not stumps.is_empty(), "cenário tem troncos (%d) e tocos (%d) interativos" % [logs.size(), stumps.size()])
	set_meta("player_energy", 100)
	if not logs.is_empty():
		var key: String = logs[0]
		BAG.add_item(self, "machado", 1)
		player.global_position = chop.spot_of(key) + Vector2(0, 22)
		for i in 4: await physics_frame
		for i in 3: await process_frame
		check(str(region.hud_hint.text).contains("Processar"), "machado no tronco de cenário oferece processar (%s)" % region.hud_hint.text)
		var wood := BAG.count_item(self, "madeira")
		for i in chop.HITS_TO_PROCESS: await swing(player)
		region.get("item_drops").collect_all()
		check(not (chop.scenery[key].node as CanvasItem).visible and BAG.count_item(self, "madeira") == wood + chop.WOOD_PER_LOG, "tronco de cenário vira %d madeiras e some" % chop.WOOD_PER_LOG)
	if not stumps.is_empty():
		var key2: String = stumps[0]
		BAG.add_item(self, "pa", 1)
		HOTBAR.select(self, HOTBAR.slots(self).find("pa"))
		player.global_position = chop.spot_of(key2) + Vector2(0, 22)
		for i in 4: await physics_frame
		for i in 3: await process_frame
		check(str(region.hud_hint.text).contains("toco"), "pá no toco de cenário oferece arrancar (%s)" % region.hud_hint.text)
		var before: Dictionary = chop.state(self).duplicate()
		await swing(player)
		var removed: Array = chop.state(self).keys().filter(func(k): return not before.has(k) and chop.scenery.has(k) and chop.scenery[k].kind == "stump")
		check(removed.size() == 1 and not (chop.scenery[removed[0]].node as CanvasItem).visible, "o toco de cenário mais perto é arrancado e some (%s)" % [removed])
	print("SCENERY_WOOD: %d failures" % failures)
	quit(1 if failures else 0)

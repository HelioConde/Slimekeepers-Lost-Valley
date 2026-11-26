extends SceneTree
## Playtest ID 03: todo painel fechável tem um X; o X fecha sem mexer no inventário.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_close_buttons.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	if has_meta(BAG.INVENTORY_KEY): remove_meta(BAG.INVENTORY_KEY)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	BAG.add_item(self, "fibra", 3)
	BAG.add_item(self, "madeira", 2)
	var before := [BAG.count_item(self, "fibra"), BAG.count_item(self, "madeira"), BAG.count_item(self, "corda")]
	var chest := preload("res://scripts/ui/chest_panel.gd").new()
	chest.player = region.get("player")
	region.get_node("HUD/Interface").add_child(chest)
	var cases := [["mochila", region.get("inventory_panel"), "open", []],
		["fabricação (mãos)", region.get("crafting_panel"), "open", ["maos"]],
		["bancada", region.get("crafting_panel"), "open", ["bancada"]],
		["fogão", region.get("crafting_panel"), "open", ["fogao"]],
		["baú", chest, "open", []]]
	for c: Array in cases:
		var panel: Control = c[1]
		check(panel != null, "%s existe" % c[0])
		if panel == null: continue
		panel.callv(c[2], c[3])
		for i in 3: await process_frame
		var x: Button = panel.get_node_or_null("CloseButton")
		check(x != null and x.is_visible_in_tree(), "%s tem X visível" % c[0])
		if x == null: continue
		var r := x.get_global_rect()
		check(r.end.x <= panel.get_global_rect().end.x and r.position.y >= panel.get_global_rect().position.y, "%s: X dentro do canto superior direito" % c[0])
		check(x.mouse_filter == Control.MOUSE_FILTER_STOP, "%s: X consome o clique" % c[0])
		x.emit_signal("pressed")
		for i in 3: await process_frame
		check(not panel.visible, "%s fecha pelo X" % c[0])
		check(before == [BAG.count_item(self, "fibra"), BAG.count_item(self, "madeira"), BAG.count_item(self, "corda")], "%s: inventário igual" % c[0])
	print("CLOSE_BUTTONS: %d failures" % failures)
	quit(1 if failures else 0)

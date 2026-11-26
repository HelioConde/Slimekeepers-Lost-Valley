extends SceneTree
## Playtest ID 04: clicar numa receita só escolhe e mostra; fabricar só pelo botão
## (ou [F]/Enter), uma vez, gastando o material certo. Sem material o botão fica desligado.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_craft_select.gd

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
	var panel: Control = region.get("crafting_panel")
	BAG.add_item(self, "fibra", 3)
	panel.call("open", "maos")
	for i in 3: await process_frame
	var rows: Array = panel.get("_rows")
	var at := -1
	for i in rows.size():
		if str(rows[i].id) == "corda": at = i
	check(at >= 0, "receita da corda na lista")
	rows[at].node.emit_signal("clicked")
	for i in 3: await process_frame
	check(BAG.count_item(self, "corda") == 0 and BAG.count_item(self, "fibra") == 3, "clicar só escolhe: inventário igual")
	check(int(panel.get("selected")) == at, "a corda fica escolhida")
	var action: Button = panel.get("_action")
	check(not action.disabled and action.text == "Fabricar", "botão Fabricar ligado")
	action.emit_signal("pressed")
	for i in 3: await process_frame
	check(BAG.count_item(self, "corda") == 1 and BAG.count_item(self, "fibra") == 0, "Fabricar faz uma corda e gasta 3 fibras")
	check(action.disabled, "sem fibra, o botão desliga")
	action.emit_signal("pressed")
	for i in 3: await process_frame
	check(BAG.count_item(self, "corda") == 1, "botão desligado não fabrica de novo")
	print("CRAFT_SELECT: %d failures" % failures)
	quit(1 if failures else 0)

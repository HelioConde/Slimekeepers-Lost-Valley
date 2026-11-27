extends SceneTree
## Playtest ID 45: janela do baú em duas colunas. Clique = 1, Shift+clique = metade,
## Ctrl+clique = tudo, arrastar move a pilha — nas duas direções.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_chest_move.gd

const CHEST := preload("res://scripts/systems/chest_storage.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
var failures := 0
var panel: Control


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func counts() -> Array:
	return [BAG.count_item(self, "madeira"), CHEST.count(self, "madeira")]


## Clique de verdade no espaço: aperta e solta o botão com os modificadores.
func click(slot_name: String, shift := false, ctrl := false, drag := false) -> void:
	await process_frame
	var slot: Control = panel.find_child(slot_name, true, false)
	if slot == null:
		check(false, "espaço %s existe" % slot_name)
		return
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.shift_pressed = shift
		ev.ctrl_pressed = ctrl
		ev.position = slot.size * 0.5
		slot.gui_input.emit(ev)
		if pressed and drag: panel.notification(Control.NOTIFICATION_DRAG_BEGIN)


func bag_slot() -> String:
	return "Bag%d" % BAG.layout(self).find("madeira")


func run() -> void:
	for k in [CHEST.KEY, CHEST.PLACED_KEY, BAG.INVENTORY_KEY, BAG.LAYOUT_KEY]:
		if has_meta(k): remove_meta(k)
	panel = preload("res://scripts/ui/chest_panel.gd").new()
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(ui)
	ui.add_child(panel)
	BAG.add_item(self, "madeira", 10)
	panel.call("open", "")
	for i in 3: await process_frame
	check(panel.find_child("Bag0", true, false) != null and panel.find_child("Chest0", true, false) != null, "duas colunas: bolsa e baú")
	check(panel.find_child("Bag19", true, false) != null, "bolsa mostra barra rápida e mochila (20 espaços)")
	# Bolsa -> baú
	await click(bag_slot())
	check(counts() == [9, 1], "clique guarda 1 %s" % [counts()])
	await click(bag_slot(), true)
	check(counts() == [4, 6], "Shift+clique guarda metade (5 de 9) %s" % [counts()])
	await click(bag_slot(), false, false, true)
	check(counts() == [4, 6], "soltar depois de arrastar não conta como clique %s" % [counts()])
	await click(bag_slot(), false, true)
	check(counts() == [0, 10], "Ctrl+clique guarda tudo %s" % [counts()])
	# Baú -> bolsa
	await click("Chest0")
	check(counts() == [1, 9], "clique pega 1 %s" % [counts()])
	await click("Chest0", true)
	check(counts() == [6, 4], "Shift+clique pega metade (5 de 9) %s" % [counts()])
	await click("Chest0", false, true)
	check(counts() == [10, 0], "Ctrl+clique pega tudo %s" % [counts()])
	# Arrastar entre colunas move a pilha inteira.
	panel.call("_drop", Vector2.ZERO, {"bag_slot": BAG.layout(self).find("madeira")}, 1, -1)
	check(counts() == [0, 10], "arrastar da bolsa para o baú guarda a pilha %s" % [counts()])
	panel.call("_drop", Vector2.ZERO, {"chest_item": "madeira"}, 0, 15)
	check(counts() == [10, 0] and BAG.layout(self)[15] == "madeira", "arrastar do baú para o espaço 16 da mochila")
	BAG.add_item(self, "pedra_pequena", 2)
	var stone := BAG.layout(self).find("pedra_pequena")
	panel.call("_drop", Vector2.ZERO, {"bag_slot": stone}, 0, 3)
	check(BAG.layout(self)[3] == "pedra_pequena", "arrastar dentro da bolsa troca de lugar")
	await process_frame
	check(str(panel.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)).contains("Shift+clique"), "dica dos atalhos na janela")
	panel.call("close")
	print("CHEST_MOVE: %d failures" % failures)
	quit(1 if failures else 0)

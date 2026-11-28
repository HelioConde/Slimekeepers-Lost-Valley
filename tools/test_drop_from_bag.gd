extends SceneTree
## Soltar itens no chão (playtest ID 21), modo solo, na Floresta:
## - [Q] na barra solta 1; Shift+[Q] a pilha; quem soltou não puxa de volta parado;
## - afastar e voltar recolhe; ferramenta também solta;
## - mochila: quantidade escolhida + botão "Soltar no chão"; não solta mais do que tem.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_drop_from_bag.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func press_q(shift: bool) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_Q
	key.keycode = KEY_Q
	key.shift_pressed = shift
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	var up := key.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func select(item: String) -> void:
	HOTBAR.select(self, HOTBAR.slots(self).find(item))


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in ["forest_bag_items", "forage_taken"]:
		if has_meta(k): remove_meta(k)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	var player: Node2D = region.get("player")
	var drops: Node2D = region.get("item_drops")
	BAG.add_item(self, "fibra", 10)
	select("fibra")
	await press_q(false)
	check(BAG.count_item(self, "fibra") == 9 and drops.pending() == 1, "[Q] solta 1 fibra (%d na bolsa)" % BAG.count_item(self, "fibra"))
	await create_timer(1.5).timeout
	check(BAG.count_item(self, "fibra") == 9 and drops.pending() == 1, "parado, quem soltou não puxa de volta")
	await press_q(true)
	check(BAG.count_item(self, "fibra") == 0 and drops.pending() == 10, "Shift+[Q] solta a pilha toda")
	await press_q(false)
	check(drops.pending() == 10, "[Q] sem item não solta nada")
	var home := player.global_position
	await create_timer(1.2).timeout
	player.global_position = home + Vector2(0, -200)  # sai do alcance do ímã
	for i in 5: await process_frame
	player.global_position = home
	await create_timer(1.5).timeout
	check(BAG.count_item(self, "fibra") == 10 and drops.pending() == 0, "afastar e voltar recolhe (%d)" % BAG.count_item(self, "fibra"))
	# Ferramenta.
	BAG.add_item(self, "machado", 1)
	select("machado")
	await press_q(false)
	check(BAG.count_item(self, "machado") == 0 and drops.pending() == 1, "ferramenta também pode ser solta")
	drops.collect_all()
	check(BAG.count_item(self, "machado") == 1, "machado volta à bolsa ao recolher")
	# Mochila: quantidade escolhida.
	var panel: Control = region.get("inventory_panel")
	select("fibra")
	panel.call("open")
	await process_frame
	var spin: SpinBox = panel.get("_amount")
	spin.value = 4
	(panel.find_child("DropButton", true, false) as Button).pressed.emit()
	check(BAG.count_item(self, "fibra") == 6 and drops.pending() == 4, "mochila solta a quantidade escolhida (4)")
	check(int(spin.max_value) == 6, "quantidade máxima segue a bolsa (%d)" % int(spin.max_value))
	check(not drops.drop_from_bag("fibra", 7), "não solta mais do que tem")
	await press_q(false)
	check(BAG.count_item(self, "fibra") == 5, "[Q] com a mochila aberta solta pela mochila (sem soltar em dobro)")
	panel.call("close")
	print("DROP_FROM_BAG: %d failures" % failures)
	quit(1 if failures else 0)

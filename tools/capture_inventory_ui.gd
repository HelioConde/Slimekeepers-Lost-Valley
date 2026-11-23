extends SceneTree
## Mochila e fabricação em grade (pedido do usuário, 2026-11-22), na Floresta:
## - [E] abre/fecha a mochila (10 espaços); [F] é a tecla de interagir;
## - a mochila recusa o 11º item diferente; o craft avisa "Mochila cheia";
## - fabricação em grade, dica com ingredientes ao passar o mouse.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_inventory_ui.gd -- <pasta>

const BAG := preload("res://scripts/systems/forest_bag.gd")
const CRAFTING := preload("res://scripts/systems/crafting.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	root.push_input(ev)
	await process_frame
	var up := ev.duplicate()
	up.pressed = false
	root.push_input(up)
	for i in 2: await process_frame


func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	if has_meta(BAG.INVENTORY_KEY): remove_meta(BAG.INVENTORY_KEY)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	set_meta(BAG.INVENTORY_KEY, {})  # sem o kit de sementes inicial
	var interact: Array = InputMap.action_get_events("interact")
	check(not interact.is_empty() and (interact[0] as InputEventKey).physical_keycode == KEY_F, "[F] é a tecla de interagir")
	for item in ["machado", "madeira", "fibra", "graveto", "pedra_pequena", "corda", "cenoura", "beterraba", "repolho"]:
		BAG.add_item(self, item, 1 if item == "machado" else 5)
	check(BAG.add_item(self, "folhas_frescas", 2) and BAG.used_slots(self) == 10, "10 itens diferentes enchem a mochila")
	check(not BAG.add_item(self, "sementes_silvestres", 1), "11º item diferente não cabe")
	check(BAG.add_item(self, "madeira", 3), "pilha que já existe ainda cresce")
	var panel: Control = region.get("inventory_panel")
	await key(KEY_E)
	check(is_instance_valid(panel) and panel.visible, "[E] abre a mochila")
	await process_frame
	if out != "": await shot(out + "/mochila.png")
	await key(KEY_E)
	check(not panel.visible, "[E] fecha a mochila")
	BAG.spend_item(self, "folhas_frescas", 2)
	BAG.add_item(self, "fibra", 10)
	var craft: Control = region.get("crafting_panel")
	await key(KEY_C)
	check(craft.visible and craft.get("_list") is GridContainer, "[C] abre a fabricação em grade")
	# Dica do mouse: ingredientes tem/precisa.
	var first: Control = craft.get("_list").get_child(0)
	var tip: Control = first.call("_make_custom_tooltip", "")
	var text := ""
	for label in tip.find_children("*", "Label", true, false): text += (label as Label).text + "\n"
	check(text.contains("Fibra vegetal") and text.contains("/3"), "dica mostra ingredientes (%s)" % text.replace("\n", " | "))
	if out != "":
		root.add_child(tip)
		tip.position = first.global_position + Vector2(48, 0)
		await process_frame
		await shot(out + "/fabricacao.png")
		tip.queue_free()
	BAG.add_item(self, "folhas_frescas", 1)  # 10/10 de novo
	check(CRAFTING.missing(self, "bancada").begins_with("Falta") or CRAFTING.missing(self, "corda").is_empty(), "corda com pilha existente não precisa de espaço")
	await key(KEY_C)
	print("INVENTORY_UI: %d failures" % failures)
	quit(1 if failures else 0)

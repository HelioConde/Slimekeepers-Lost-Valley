extends SceneTree
## Captura para conferir os dígitos (playtest ID 33): barra com pilhas 25/58/2 e a receita da
## picareta com requisitos em vermelho. Uso: ... --script res://tools/capture_digits.gd -- <pasta>

const BAG := preload("res://scripts/systems/forest_bag.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DisplayServer.window_set_size(Vector2i(1280, 720))
	if has_meta(BAG.INVENTORY_KEY): remove_meta(BAG.INVENTORY_KEY)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	BAG.add_item(self, "pedra_pequena", 2)
	BAG.add_item(self, "graveto", 25)
	BAG.add_item(self, "fibra", 58)
	BAG.add_item(self, "madeira", 5)
	BAG.add_item(self, "machado", 1)
	var panel: Control = region.get("crafting_panel")
	panel.call("open", "bancada")
	panel.call("show_category", "ferramentas")
	var list: Array = panel.call("entries")
	var at := list.map(func(r: Dictionary) -> String: return str(r.id)).find("picareta")
	if at >= 0:
		panel.set("selected", at)
		panel.call("refresh")
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/digitos.png" % out)
	print("DIGITS: salvo")
	quit()

extends SceneTree
## Captura real do HUD na Floresta (relógio, energia, slime por perto, barra rápida).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_hud.gd -- <pasta>

const BAG := preload("res://scripts/systems/forest_bag.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DisplayServer.window_set_size(Vector2i(1280, 720))
	set_meta(BAG.INVENTORY_KEY, {})
	for item in ["machado", "madeira", "fibra", "graveto", "pedra_pequena", "corda", "cenoura", "repolho"]:
		BAG.add_item(self, item, 1 if item == "machado" else 6)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	var hud: Node = region.get_node("HUD/Interface")
	check(hud.get_node_or_null("Hotbar") != null and hud.get_node_or_null("PlayerStatus") != null, "barra e energia no HUD")
	var slime: Node2D = region.get("slimes")[0]
	region.get("player").global_position = slime.global_position + Vector2(0, 30)
	for i in 10: await process_frame
	var bond: Control = hud.get_node_or_null("SlimeBond")
	check(bond != null and bond.visible, "painel do slime aparece perto de um slime")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/hud.png")
	print("HUD: %d failures" % failures)
	quit(1 if failures else 0)

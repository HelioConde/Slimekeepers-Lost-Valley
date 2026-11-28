extends SceneTree
## Slimes amigos trabalhando na fazenda da Floresta: Brotinho planta, Bolhinha rega,
## Musguinho aduba. Verifica o efeito e salva quadros.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_farm_helpers.gd -- [pasta]

const FARM := preload("res://scripts/systems/farm_state.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in [FARM.KEY, BAG.INVENTORY_KEY, "farm_helpers_done"]:
		if has_meta(k): remove_meta(k)
	set_meta("forest_slime_friends", {"brotinho/t/0": true, "musguinho/t/1": true})
	set_meta("valley_slime_friends", {"bolhinha/t/2": true})
	root.get_node("GameClock").set_time(8, 0)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	var farm: Node2D = region.get("farm")
	var player: Node2D = region.get("player")
	var base: Vector2i = farm.cell_at(player.global_position) + Vector2i(2, 1)
	var cells: Array[Vector2i] = []
	for x in 3:
		var cell := base + Vector2i(x, 0)
		if FARM.till(self, cell, farm.field_id): cells.append(cell)
	BAG.add_item(self, "semente_cenoura", 5)
	farm.refresh()
	check(cells.size() == 3, "3 covas aradas perto do jogador (%d)" % cells.size())
	var shot := 0
	for t in 240:  # ~12 s
		await create_timer(0.05).timeout
		if out != "" and t % 12 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/helpers_%02d.png" % [out, shot])
			shot += 1
	var planted := cells.filter(func(c: Vector2i) -> bool: return FARM.crop(self, c, farm.field_id) != "")
	var watered := cells.filter(func(c: Vector2i) -> bool: return FARM.is_watered(self, c, farm.field_id))
	var fed := cells.filter(func(c: Vector2i) -> bool: return FARM.is_fertilized(self, c, farm.field_id))
	check(planted.size() == 3, "Brotinho plantou (%d/3)" % planted.size())
	check(watered.size() >= 1, "Bolhinha regou (%d)" % watered.size())
	check(fed.size() >= 1, "Musguinho adubou (%d)" % fed.size())
	print("HELPERS: %d failures" % failures)
	quit(1 if failures else 0)

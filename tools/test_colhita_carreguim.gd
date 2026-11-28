extends SceneTree
## Colhita colhe a planta pronta e deixa no chão; Carreguim leva ao baú colocado.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_colhita_carreguim.gd -- [pasta]

const FARM := preload("res://scripts/systems/farm_state.gd")
const CHEST := preload("res://scripts/systems/chest_storage.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in [FARM.KEY, "farm_helpers_done", "placed_stations", "placed_chest_items", "carreguim_chest", "slime_work_off", "slime_at_farm"]:
		if has_meta(k): remove_meta(k)
	set_meta("forest_slime_friends", {"colhita/t/0": true, "carreguim/t/0": true})
	root.get_node("GameClock").set_time(8, 0)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var farm: Node2D = region.get("farm")
	var player: Node2D = region.get("player")
	player.global_position += Vector2(0, -400)  # longe: o ímã do jogador não pega a colheita
	var cell: Vector2i = farm.cell_at(Vector2(3200, 3200)) + Vector2i(3, 2)
	FARM.till(self, cell, farm.field_id)
	preload("res://scripts/systems/forest_bag.gd").add_item(self, "semente_cenoura", 1)  # sem kit inicial de sementes
	FARM.plant(self, cell, "cenoura", farm.field_id)
	for d in 6:
		FARM.water(self, cell, farm.field_id)
		FARM.advance_day(self)
	check(FARM.is_ready(self, cell, farm.field_id), "cenoura pronta")
	var chest_at := Vector2(cell * 32) + Vector2(120, 40)
	set_meta("placed_stations", [{"region": "floresta", "x": chest_at.x, "y": chest_at.y, "kind": "bau_campo", "built": true}])
	region.get("placer").call("reload")
	farm.refresh()
	var shot := 0
	for t in 300:  # ~15 s
		await create_timer(0.05).timeout
		if out != "" and t % 30 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/colhita_%02d.png" % [out, shot])
			shot += 1
	check(FARM.crop(self, cell, farm.field_id).is_empty(), "Colhita colheu")
	var chest_id := "floresta_%d_%d" % [int(chest_at.x), int(chest_at.y)]
	check(CHEST.count(self, "cenoura", chest_id) >= 1, "Carreguim levou a cenoura ao baú %s" % str(CHEST.items(self, chest_id)))
	print("COLHITA_CARREGUIM: %d failures" % failures)
	quit(1 if failures else 0)

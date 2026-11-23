extends SceneTree
## Captura do plantio livre na Floresta: um pedaço arado (terra seca e molhada com
## os tilesets PixelLab em dual-grid) e culturas em estágios diferentes.
##   godot --path . --rendering-driver opengl3 --script res://tools/capture_farm_field.gd -- <pasta>

const FARM := preload("res://scripts/systems/farm_state.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	if has_meta(FARM.KEY): remove_meta(FARM.KEY)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	await physics_frame
	var farm: Node2D = region.get("farm")
	var player: Node2D = region.get("player")
	(player.get_node("Camera2D") as Camera2D).position_smoothing_enabled = false
	var start: Vector2i = farm.cell_at(player.global_position) + Vector2i(-3, 2)
	var tilled := 0
	for y in 3:
		for x in 5:
			var cell := start + Vector2i(x, y)
			if farm.contains(cell) and FARM.till(self, cell, farm.field_id):
				farm._clear_cell_decor(cell)  # como a enxada faz
				tilled += 1
				if x < 3: FARM.water(self, cell, farm.field_id)
	for extra in [Vector2i(7, 0), Vector2i(7, 1), Vector2i(9, 2)]:
		if farm.contains(start + extra) and FARM.till(self, start + extra, farm.field_id): farm._clear_cell_decor(start + extra)
	for pair in [[Vector2i(0, 0), "cenoura"], [Vector2i(1, 1), "beterraba"], [Vector2i(3, 2), "folhas_silvestres"]]:
		FARM.plant(self, start + pair[0], pair[1], farm.field_id)
	var cells: Dictionary = FARM.cells(self, farm.field_id)
	if cells.has(start + Vector2i(1, 1)): cells[start + Vector2i(1, 1)]["stage"] = 2
	farm.refresh()
	print("arado: %d células" % tilled)
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out + "/plantio_livre.png")
	quit()

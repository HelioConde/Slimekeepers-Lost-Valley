extends SceneTree
## Simula alguns dias de cultivo no Vale e captura o campo (precisa de janela):
##   godot --path . --rendering-driver opengl3 --script res://tools/capture_farm_field.gd -- <pasta>
func _initialize(): call_deferred("run")
func shot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var out: String = OS.get_cmdline_user_args()[0]
	var region: Node2D = load("res://scenes/regions/ValeDasNascentes.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var clock := root.get_node("GameClock"); clock.stop(); clock.set_time(10, 0)
	var field = region.farm_field
	var player: Node2D = region.player
	var farm = load("res://scripts/systems/farm_state.gd")
	var tree := self
	# Ara o campo todo, planta 3 culturas em fileiras, rega metade.
	var crops := ["cenoura", "beterraba", "repolho", "cenoura"]
	for y in field.size_cells.y:
		for x in field.size_cells.x:
			var cell: Vector2i = field.origin_cell + Vector2i(x, y)
			if x == 5 and y == 3: continue
			farm.till(tree, cell)
			if x < 4: farm.plant(tree, cell, crops[y])
	for day in 3:
		for y in field.size_cells.y:
			for x in field.size_cells.x:
				var cell: Vector2i = field.origin_cell + Vector2i(x, y)
				if x < 2 + day: farm.water(tree, cell)
		farm.advance_day(tree)
	for y in 2: for x in 6: farm.water(tree, field.origin_cell + Vector2i(x, y))
	field.refresh()
	player.global_position = Vector2(field.world_rect().get_center().x, field.world_rect().end.y + 30)
	player.get_node("Camera2D").reset_smoothing()
	for i in 60: await process_frame
	await shot(out + "/farm_1000.png")
	clock.set_time(17, 0)
	for i in 30: await process_frame
	await shot(out + "/farm_1700.png")
	print("FARM_PROBE ok")
	quit()

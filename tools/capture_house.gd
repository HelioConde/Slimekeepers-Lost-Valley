extends SceneTree
## Captura a casa do jogador por fora, por dentro e no modo construir (precisa de janela):
##   godot --path . --rendering-driver opengl3 --script res://tools/capture_house.gd -- <pasta>
func _initialize(): call_deferred("run")
func shot(path: String) -> void:
	for i in 40: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var out: String = OS.get_cmdline_user_args()[0]
	var farm: Node2D = load("res://scenes/regions/Fazenda.tscn").instantiate()
	root.add_child(farm)
	for i in 20: await process_frame
	root.get_node("GameClock").stop(); root.get_node("GameClock").set_time(10, 0)
	var player: Node2D = farm.player
	var camera: Camera2D = player.get_node("Camera2D")
	player.global_position = Vector2(528, 440)
	camera.reset_smoothing()
	await shot(out + "/casa_fora.png")
	player.global_position = Vector2(528, 300)
	camera.reset_smoothing()
	await shot(out + "/casa_dentro.png")
	var house = farm.house
	house.toggle_build()
	house.mode = "furniture"
	house.furniture_choice = "estante"
	house.place_at(Vector2i(19, 9))
	house.mode = "floor"
	for x in range(21, 24):
		for y in range(7, 10): house.place_at(Vector2i(x, y))
	house.mode = "wall"
	for y in range(6, 11): house.place_at(Vector2i(24, y))
	for x in range(20, 25): house.place_at(Vector2i(x, 6)); house.place_at(Vector2i(x, 10))
	house.erase_at(Vector2i(20, 8))
	house.mode = "furniture"
	house.furniture_choice = "fogao"
	house.place_at(Vector2i(22, 7))
	house.furniture_choice = "planta"
	house.cursor_cell = Vector2i(23, 9)
	await shot(out + "/casa_construindo.png")
	house.toggle_build()
	player.global_position = Vector2(560, 300)
	camera.reset_smoothing()
	await shot(out + "/casa_ampliada.png")
	print("HOUSE_CAPTURE ok")
	quit()

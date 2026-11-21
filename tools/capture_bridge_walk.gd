extends SceneTree
## Teste de caminhada na ponte oeste do Vale (V11): relógio congelado às 21h16, a
## personagem atravessa a ponte de verdade (entrada de movimento, colisões e câmera
## normais) e um quadro é salvo a cada 6 frames. Mede também o FPS na travessia.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_bridge_walk.gd -- OUT_DIR

func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://bridge_walk"
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var region: Node2D = load("res://scenes/regions/ValeDasNascentes.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var clock := root.get_node("GameClock")
	clock.stop()
	clock.load_save_data({"version": 1, "day": 2, "minutes": 21 * 60 + 16})
	var player: Node2D = region.get_node("Player")
	player.global_position = Vector2(828, 1470)  # cabeceira norte da ponte (784..872, 1510..1850)
	(player.get_node("Camera2D") as Camera2D).reset_smoothing()
	for i in 60: await process_frame
	var start_y := player.global_position.y
	var frames := 0
	var t0 := Time.get_ticks_usec()
	Input.action_press("move_down")
	for step in 260:
		await process_frame
		if step % 6 == 0:
			(await frame_image()).save_png("%s/walk_%03d.png" % [out, frames])
			frames += 1
		if player.global_position.y > 1900.0: break
	Input.action_release("move_down")
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0
	print("BRIDGE_WALK frames=%d from_y=%.0f to_y=%.0f x=%.0f avg_ms_incl_capture=%.2f" % [frames, start_y, player.global_position.y, player.global_position.x, ms / 260.0])
	quit()

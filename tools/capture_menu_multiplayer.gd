extends SceneTree
## Clica de verdade em "Multijogador" no menu e salva a tela.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_menu_multiplayer.gd -- <pasta>

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	change_scene_to_file("res://scenes/start_menu.tscn")
	for i in 40: await process_frame
	var button: Button = current_scene.get_node("Actions/Multijogador")
	var at := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		root.push_input(ev)
		await process_frame
	for i in 20: await process_frame
	var layer: Variant = current_scene.get("options_layer")
	print("MP_PANEL: ", is_instance_valid(layer), " ", (layer as Node).name if is_instance_valid(layer) else "")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/menu_mp_click.png")
	quit()

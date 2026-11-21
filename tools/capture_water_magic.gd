extends SceneTree
## Protótipo da água encantada (V11): mesmo enquadramento e horário, camadas
## ligadas aos poucos (A atual, B +fios, C +bordas, D completa) e uma sequência
## animada da versão D. Uso:
## godot --path . --rendering-driver opengl3 --script res://tools/capture_water_magic.gd -- OUT_DIR

func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _initialize() -> void:
	call_deferred("run")


func set_layers(overlays: Array, values: Array) -> void:
	for o in overlays:
		var m: ShaderMaterial = o.material
		m.set_shader_parameter("layer_threads", values[0])
		m.set_shader_parameter("layer_edges", values[1])
		m.set_shader_parameter("layer_stars", values[2])
		m.set_shader_parameter("layer_plants", values[3])
		o.visible = values.max() > 0.0


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://water_magic"
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var region: Node2D = load("res://scenes/regions/ValeDasNascentes.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var clock := root.get_node("GameClock")
	clock.stop()
	clock.load_save_data({"version": 1, "day": 2, "minutes": 21 * 60 + 16})
	var player: Node2D = region.get_node("Player")
	player.global_position = Vector2(828, 1650)
	(player.get_node("Camera2D") as Camera2D).reset_smoothing()
	for i in 60: await process_frame
	var overlays: Array = region.find_child("WaterReflections", true, false).magic_overlays
	var steps := {"A_atual": [0, 0, 0, 0], "B_fios": [1, 0, 0, 0], "C_fios_bordas": [1, 1, 0, 0], "D_completa": [1, 1, 1, 1]}
	for tag in steps:
		set_layers(overlays, steps[tag])
		for i in 3: await process_frame
		(await frame_image()).save_png("%s/%s.png" % [out, tag])
	set_layers(overlays, [1, 1, 1, 1])
	for index in 8:
		for i in 15: await process_frame  # ~0,25 s entre quadros
		(await frame_image()).save_png("%s/D_anim%02d.png" % [out, index])
	print("WATER_MAGIC_CAPTURE done")
	quit()

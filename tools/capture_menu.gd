extends SceneTree
## Capturas reais do menu principal (cenário de ruínas em camadas):
## - quadros sequenciais para conferir as animações (água, folhas, vaga-lumes, slime);
## - o menu em três resoluções;
## - a janela de Multijogador em desenvolvimento.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_menu.gd -- <pasta>

func _initialize() -> void:
	call_deferred("run")


func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	load("res://scripts/systems/save_game.gd").path = "user://capture_menu_no_save.txt"
	load("res://scripts/systems/save_game.gd").prefix = "user://capture_menu_slot_"  # menu lê os espaços: nunca os do jogador
	for size in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(960, 540)]:
		DisplayServer.window_set_size(size)
		root.size = size
		var menu: Control = load("res://scenes/start_menu.tscn").instantiate()
		root.add_child(menu)
		for i in 40: await process_frame
		await shot("%s/menu_%dx%d.png" % [out, size.x, size.y])
		if size.x == 1280:
			for k in 16:
				await create_timer(0.12).timeout
				await shot("%s/anim_%02d.png" % [out, k])
			(menu.get_node("Actions/Multijogador") as Button).pressed.emit()
			for i in 5: await process_frame
			await shot("%s/menu_multijogador.png" % out)
		menu.queue_free()
		await process_frame
	quit()

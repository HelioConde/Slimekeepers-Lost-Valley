extends SceneTree
## Testes A e B do V10: o reflexo da Lua fica preso ao MUNDO.
## Com o relógio congelado às 19h30, captura a tela com e sem os overlays de
## reflexo; a diferença são os pixels do reflexo. O centróide desses pixels é
## convertido para coordenadas de mundo pela transformação do canvas. Repetido
## com o jogador em pontos diferentes da ponte e com zoom diferente: a posição no
## mundo tem de ficar estável. Precisa de janela (--rendering-driver opengl3).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_reflection_world.gd [-- out.png]

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1


func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _initialize() -> void:
	call_deferred("run")


## Pixels (em coordenadas de mundo, grade de 4 px) que mudam quando o reflexo
## aparece, e o retângulo de mundo visível no enquadramento.
func reflection_world_pixels(region: Node, overlays: Array) -> Dictionary:
	paused = true  # partículas e animações param: só o overlay muda entre as capturas
	await process_frame
	for o in overlays: o.visible = false
	var without: Image = await frame_image()
	for o in overlays: o.visible = true
	var with: Image = await frame_image()
	paused = false
	var scale := float(with.get_width()) / region.get_viewport().get_visible_rect().size.x
	var to_world := region.get_viewport().get_canvas_transform().affine_inverse()
	var points := {}
	for y in range(0, with.get_height(), 2):
		for x in range(0, with.get_width(), 2):
			var a := with.get_pixel(x, y)
			var b := without.get_pixel(x, y)
			if (a.r + a.g + a.b) - (b.r + b.g + b.b) > 0.25:
				var w: Vector2 = to_world * (Vector2(x, y) / scale)
				points[Vector2i((w / 4.0).round())] = true
	var top_left: Vector2 = to_world * Vector2.ZERO
	var bottom_right: Vector2 = to_world * (Vector2(with.get_width(), with.get_height()) / scale)
	return {"points": points, "view": Rect2(top_left, bottom_right - top_left).grow(-24.0)}


## Dos pixels de A dentro da área vista por B, quantos B também tem (±1 célula).
func agreement(a: Dictionary, b: Dictionary) -> float:
	var total := 0
	var hit := 0
	for key: Vector2i in a.points:
		if not (b.view as Rect2).has_point(Vector2(key) * 4.0): continue
		total += 1
		var found := false
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if b.points.has(key + Vector2i(dx, dy)): found = true
		if found: hit += 1
	return 1.0 if total == 0 else float(hit) / total


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var region: Node2D = load("res://scenes/regions/ValeDasNascentes.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var clock := root.get_node("GameClock")
	clock.stop()
	var hour := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 19
	clock.load_save_data({"version": 1, "day": 3, "minutes": hour * 60 + 30})
	var reflections := region.find_child("WaterReflections", true, false)
	reflections.reduce_motion = true  # congela a animação: só a posição importa
	var overlays: Array = reflections.surfaces
	# A interface não é mundo: escondida para não cobrir pixels do reflexo.
	for layer in region.find_children("*", "CanvasLayer", true, false):
		if layer.name != "WorldGrade": layer.visible = false
	var player: Node2D = region.get_node("Player")
	var camera := player.get_node("Camera2D") as Camera2D
	var results: Array = []
	# Ponte oeste vertical do Vale (784, 1510, 88×340), posição pedida pelo usuário.
	var cases := [[Vector2(976, 1754), camera.zoom], [Vector2(828, 1560), camera.zoom], [Vector2(828, 1700), camera.zoom], [Vector2(828, 1840), camera.zoom], [Vector2(976, 1754), camera.zoom * 1.25], [Vector2(976, 1754), camera.zoom * 0.8]]
	for c in cases:
		player.global_position = c[0]
		camera.zoom = c[1]
		camera.reset_smoothing()
		camera.force_update_scroll()
		for i in 10: await process_frame
		var r: Dictionary = await reflection_world_pixels(region, overlays)
		print("REFLECTION player=%s zoom=%s world_pixels=%d" % [c[0], c[1], r.points.size()])
		check(r.points.size() > 20 or hour != 22, "Reflexo visível às 22h com o jogador em %s, zoom %s" % [c[0], c[1]])
		results.append(r)
	var worst := 1.0
	for i in results.size():
		for j in results.size():
			if i != j: worst = minf(worst, agreement(results[i], results[j]))
	print("REFLECTION agreement_min=%.3f" % worst)
	check(worst > 0.9, "Mesmos pixels de reflexo no mundo em todos os enquadramentos (jogador e zoom mudando)")
	print("REFLECTION_WORLD: %d failures" % failures)
	quit(1 if failures else 0)

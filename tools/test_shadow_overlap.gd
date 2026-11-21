extends SceneTree
## Sombras de duas árvores sobrepostas não podem escurecer mais que uma só
## (faixas diagonais no chão da Clareira). Precisa de janela.
func _initialize(): call_deferred("run")
func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run():
	DisplayServer.window_set_size(Vector2i(960, 540))
	var region := Node2D.new()
	root.add_child(region)
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([Vector2.ZERO, Vector2(2000, 0), Vector2(2000, 2000), Vector2(0, 2000)])
	ground.color = Color(.63, .69, .44)
	ground.z_index = -10
	region.add_child(ground)
	var art := Node2D.new()
	art.name = "MapArt"
	region.add_child(art)
	for x in [400, 470]:
		var tree := Node2D.new()
		tree.position = Vector2(x, 330)
		art.add_child(tree)
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = load("res://assets/world/forest/pine_crisp.png")
		sprite.centered = false
		sprite.position = Vector2(-96, -182)
		sprite.scale = Vector2(2, 2)
		tree.add_child(sprite)
	var lighting = load("res://scripts/world/day_night_lighting.gd").new()
	region.add_child(lighting)
	for i in 4: await process_frame
	root.get_node("GameClock").stop()
	root.get_node("GameClock").set_time(18, 0)
	lighting._process(0)
	var shadows: Node2D = lighting.get_node("DayShadows")
	# Só a sombra projetada: o contato (mais escuro, na base) fica fora da medição.
	shadows.get_node("StaticContactShadows").hide()
	shadows.get_node("DynamicContactShadows").hide()
	shadows.update_for_time(0)
	var image: Image = await frame_image()
	if OS.get_cmdline_user_args().size() > 0: image.save_png(OS.get_cmdline_user_args()[0])
	var k := image.get_width() / 960.0
	var ground_g := image.get_pixel(int(900 * k), int(500 * k)).g
	# Abaixo da base das árvores só há chão e sombra projetada (para a direita às 18h).
	var darkest := 1.0
	var lightest := 0.0
	var shadow_pixels := 0
	for y in range(334, 420, 2):  # abaixo da base das árvores
		for x in range(380, 700, 2):
			var g := image.get_pixel(int(x * k), int(y * k)).g
			if g < ground_g - .02:
				shadow_pixels += 1
				darkest = minf(darkest, g)
				lightest = maxf(lightest, g)
	var ok := shadow_pixels > 50 and lightest - darkest < .02
	print("SHADOW_OVERLAP pixels=%d darkest=%.3f lightest=%.3f ground=%.3f -> %s" % [shadow_pixels, darkest, lightest, ground_g, "PASS" if ok else "FAIL"])
	quit(0 if ok else 1)

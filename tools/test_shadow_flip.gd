extends SceneTree
## Árvore espelhada (flip_h) precisa projetar a sombra sob ela mesma, igual à normal.
## No GL Compatibility um retângulo de largura negativa não espelha: desloca o desenho
## uma largura inteira e a sombra aparecia no meio da clareira. Precisa de janela.
func _initialize(): call_deferred("run")


func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func shadow_span(flip: bool) -> Vector2:
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
	var tree := Node2D.new()
	tree.position = Vector2(480, 330)
	art.add_child(tree)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load("res://assets/menu/environment/oak.png")
	sprite.centered = false
	sprite.flip_h = flip
	sprite.position = Vector2(-96, -182)
	sprite.scale = Vector2(2, 2)
	tree.add_child(sprite)
	var lighting = load("res://scripts/world/day_night_lighting.gd").new()
	region.add_child(lighting)
	for i in 4: await process_frame
	root.get_node("GameClock").stop()
	root.get_node("GameClock").set_time(16, 30)
	lighting._process(0)
	var shadows: Node2D = lighting.get_node("DayShadows")
	shadows.update_for_time(0)
	sprite.hide()  # o próprio sprite não entra na medição...
	shadows.set_process(false)
	lighting.set_process(false)
	sprite.show()
	sprite.self_modulate.a = 0.0  # ...mas continua "visível" para projetar sombra
	shadows.update_for_time(0)
	var image: Image = await frame_image()
	var k := image.get_width() / 960.0
	var ground_g := image.get_pixel(int(5 * k), int(5 * k)).g
	var lo := 9999.0
	var hi := -9999.0
	for y in range(200, 540, 2):
		for x in range(0, 960, 2):
			if image.get_pixel(int(x * k), int(y * k)).g < ground_g - .02:
				lo = minf(lo, x)
				hi = maxf(hi, x)
	region.queue_free()
	await process_frame
	return Vector2(lo, hi)


func run() -> void:
	DisplayServer.window_set_size(Vector2i(960, 540))
	var normal: Vector2 = await shadow_span(false)
	var flipped: Vector2 = await shadow_span(true)
	# Pé em x=480: a sombra tem que começar sob a copa (±96 px) nos dois casos.
	var ok := absf(normal.x - flipped.x) < 24 and absf(normal.y - flipped.y) < 24 and flipped.x < 480
	print("SHADOW_FLIP normal=%s flipped=%s -> %s" % [normal, flipped, "PASS" if ok else "FAIL"])
	quit(0 if ok else 1)

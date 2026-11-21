extends SceneTree
## Encaixe das sombras de objetos baixos e do mato (precisa de janela):
## - toda sombra fica colada ao objeto (cada pixel de sombra a até 8 px do sprite);
## - a sombra encosta no objeto (sem fresta entre a base e a sombra);
## - o tufo de mato tem sombra.
func _initialize(): call_deferred("run")


func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


const OBJECTS := {
	"arbusto": "res://assets/sprites/objects/bush_small_compact_leafy_for/rotations/bush_small_compact_leafy_for.png",
	"pedra": "res://assets/world/forest/mossy_rock.png",
	"fogueira": "res://assets/objects/pixellab_exports/campfire_unlit_compact_64x48_292e36a0/campfire_unlit_compact_64x48.png",
	"samambaia": "res://assets/world/forest/fern.png",
	"mato": "res://assets/menu/environment/grass.png",
}


func measure(file: String, hour: int, minute: int) -> Dictionary:
	var region := Node2D.new()
	root.add_child(region)
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([Vector2.ZERO, Vector2(2000, 0), Vector2(2000, 2000), Vector2(0, 2000)])
	ground.color = Color(.63, .69, .44)
	ground.z_index = -10
	region.add_child(ground)
	var art := Node2D.new()
	art.name = "Decorations"
	region.add_child(art)
	var anchor := Node2D.new()
	anchor.position = Vector2(480, 300)
	art.add_child(anchor)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load(file)
	sprite.centered = false
	sprite.scale = Vector2.ONE  # escala usada nos mapas
	var used: Rect2i = sprite.texture.get_image().get_used_rect()
	sprite.position = -Vector2(used.position.x + used.size.x * 0.5, used.end.y)
	anchor.add_child(sprite)
	var lighting = load("res://scripts/world/day_night_lighting.gd").new()
	region.add_child(lighting)
	for i in 4: await process_frame
	root.get_node("GameClock").stop()
	root.get_node("GameClock").set_time(hour, minute)
	lighting._process(0)
	lighting.set_process(false)
	var shadows: Node2D = lighting.get_node("DayShadows")
	shadows.update_for_time(0)
	var with_shadow: Image = await frame_image()
	shadows.hide()
	var without: Image = await frame_image()
	var k := with_shadow.get_width() / 960.0
	# Pixels do objeto (sem sombra, diferentes do chão) e pixels de sombra (escurecidos).
	var ground_c := without.get_pixel(int(5 * k), int(5 * k))
	var object := {}
	var shade: Array[Vector2i] = []
	for y in range(150, 400):
		for x in range(330, 630):
			var a := with_shadow.get_pixel(int(x * k), int(y * k))
			var b := without.get_pixel(int(x * k), int(y * k))
			if absf(b.r - ground_c.r) + absf(b.g - ground_c.g) + absf(b.b - ground_c.b) > .04: object[Vector2i(x, y)] = true
			elif b.g - a.g > .02: shade.append(Vector2i(x, y))
	var far := 0
	var touching := 0
	for p in shade:
		var best := 99
		for d in range(1, 9):
			for o in [Vector2i(-d, 0), Vector2i(d, 0), Vector2i(0, -d), Vector2i(0, d), Vector2i(-d, -d), Vector2i(d, -d), Vector2i(-d, d), Vector2i(d, d)]:
				if object.has(p + o):
					best = mini(best, d)
		if best > 8: far += 1
		if best <= 1: touching += 1
	region.queue_free()
	await process_frame
	return {"shade": shade.size(), "far": far, "touching": touching}


func run() -> void:
	DisplayServer.window_set_size(Vector2i(960, 540))
	var failures := 0
	for name in OBJECTS:
		for time in [[12, 0], [16, 30], [7, 0]]:
			var m: Dictionary = await measure(OBJECTS[name], time[0], time[1])
			var far_ratio := float(m.far) / maxf(1.0, m.shade)
			var ok: bool = m.shade > 6 and far_ratio < 0.05 and m.touching > 3
			if not ok: failures += 1
			print("SHADOW_FIT %s %02d:%02d shade=%d far=%d touching=%d %s" % [name, time[0], time[1], m.shade, m.far, m.touching, "ok" if ok else "FAIL"])
	print("SHADOW_FIT_TEST: %s (%d falhas)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

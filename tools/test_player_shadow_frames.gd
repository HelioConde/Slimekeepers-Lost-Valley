extends SceneTree
## Sombra do jogador em todas as direções e quadros de caminhada/corrida (precisa de janela):
##   godot --path . --rendering-driver opengl3 --script res://tools/test_player_shadow_frames.gd -- --out=<pasta>
## Para cada quadro compara sombras ligadas × desligadas: a sombra precisa tocar os pés
## (pixels escuros até 4 px abaixo da base visível) e apontar para o lado oposto ao sol.
## Gera uma folha de contato por horário.

const DIRS := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
const CELL := Vector2i(72, 84)
var failures := 0
var checks := 0


func _initialize() -> void: call_deferred("run")


func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func run() -> void:
	var out := "user://player_shadow"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var region := Node2D.new()
	root.add_child(region)
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	ground.color = Color(.63, .69, .44)
	ground.z_index = -10
	region.add_child(ground)
	var player = load("res://scenes/player.tscn").instantiate()
	player.get_node("Camera2D").enabled = false
	player.position = Vector2(640, 400)
	player.scale = Vector2(2, 2)  # amplia para inspeção; a sombra usa a escala global
	region.add_child(player)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var lighting = load("res://scripts/world/day_night_lighting.gd").new()
	region.add_child(lighting)
	for i in 4: await process_frame
	var shadows = lighting.get_node("DayShadows")
	var clock := root.get_node("GameClock")
	clock.stop()
	var sprite: AnimatedSprite2D = player.sprite
	for hour in [[7, 0], [12, 0], [16, 30]]:
		clock.set_time(hour[0], hour[1])
		lighting._process(0)
		var sun: Vector2 = shadows.profile_at(hour[0] * 60.0 + hour[1])["vector"]
		var cells: Array[Image] = []
		for dir in DIRS:
			for anim in ["walk_", "run_"]:
				var name: String = anim + dir
				for frame in sprite.sprite_frames.get_frame_count(name):
					sprite.animation = name
					sprite.frame = frame
					shadows.show()
					shadows.update_for_time(0)
					var on: Image = await frame_image()
					shadows.hide()
					var off: Image = await frame_image()
					var base_y := int(round((sprite.global_transform * Vector2(0, shadows.ground_bottom(sprite))).y))
					var touching := 0
					var side := 0.0
					var count := 0
					for y in range(base_y - 6, base_y + 60):
						for x in range(520, 760):
							var a := on.get_pixel(x, y)
							var b := off.get_pixel(x, y)
							if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > .02:
								count += 1
								side += x - 640
								if absi(y - base_y) <= 4 and absi(x - 640) < 44: touching += 1
					checks += 1
					var points_away := sun.x * side >= 0.0 or absf(sun.x) < .1
					if touching == 0 or count == 0 or not points_away:
						failures += 1
						print("PLAYER_SHADOW_FAIL %s f%d %02d:%02d touching=%d pixels=%d side=%.0f" % [name, frame, hour[0], hour[1], touching, count, side])
					if anim == "walk_" or frame % 2 == 0:
						cells.append(on.get_region(Rect2i(640 - CELL.x / 2, base_y - 70, CELL.x, CELL.y)))
		var columns := 14
		var sheet := Image.create(columns * CELL.x, ceili(cells.size() / float(columns)) * CELL.y, false, Image.FORMAT_RGBA8)
		for i in cells.size():
			var cell := cells[i]
			cell.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % columns) * CELL.x, (i / columns) * CELL.y))
		sheet.save_png("%s/player_shadow_%02d%02d.png" % [out, hour[0], hour[1]])
	print("PLAYER_SHADOW_FRAMES: %d checks; %d failures" % [checks, failures])
	region.queue_free()
	await process_frame
	quit(1 if failures else 0)

extends SceneTree
## Depuração visual (precisa de janela): sombras projetadas em vermelho, contato em
## laranja, pé de cada objeto que projeta sombra em ciano e sprites sólidos visíveis
## sem sombra com um quadrado amarelo.
##   godot --path . --rendering-driver opengl3 --script res://tools/debug_shadow_owners.gd -- \
##     --scene=ValeDasNascentes --at=1440,500 --time=16:30 --out=C:/tmp/debug.png

const DEBUG_SHADER := "shader_type canvas_item;\nrender_mode unshaded;\nuniform vec4 tint : source_color;\nvoid fragment(){ COLOR = vec4(tint.rgb, texture(TEXTURE,UV).a * tint.a); }"


func _initialize() -> void: call_deferred("run")


func run() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var region: Node2D = load("res://scenes/regions/%s.tscn" % args.get("scene", "FlorestaDoDespertarV2")).instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var clock := root.get_node("GameClock")
	clock.stop()
	var hm: PackedStringArray = String(args.get("time", "16:30")).split(":")
	clock.set_time(int(hm[0]), int(hm[1]))
	var player: Node2D = region.get_node("Player")
	if args.has("at"):
		var xy: PackedStringArray = args["at"].split(",")
		player.global_position = Vector2(float(xy[0]), float(xy[1]))
	player.get_node("Camera2D").reset_smoothing()
	for i in 30: await process_frame
	var shadows: Node2D = region.get_node("DayNightLighting/DayShadows")
	for pass_name in ["CastShadows/StaticGroundShadows", "CastShadows/DynamicGroundShadows", "StaticContactShadows", "DynamicContactShadows"]:
		var pass_node := shadows.get_node(pass_name) as CanvasItem
		var material := ShaderMaterial.new()
		material.shader = Shader.new()
		material.shader.code = DEBUG_SHADER
		material.set_shader_parameter("tint", Color(1, 0, 0, 0.55) if "Ground" in pass_name else Color(1, 0.6, 0, 0.8))
		pass_node.material = material
	shadows.cast_group.self_modulate.a = 1.0
	if args.has("no_group"):
		# Passes fora do CanvasGroup (desenho direto), para comparar posições.
		for pass_name in ["StaticGroundShadows", "DynamicGroundShadows"]:
			var pass_node: Node = shadows.cast_group.get_node(pass_name)
			shadows.cast_group.remove_child(pass_node)
			shadows.add_child(pass_node)
	var markers := Node2D.new()
	markers.z_as_relative = false
	markers.z_index = 100
	region.add_child(markers)
	var feet: Array[Vector2] = []
	for id in shadows._casters:
		var sprite: Node2D = shadows._casters[id]
		if sprite.is_visible_in_tree(): feet.append(shadows.foot_for(sprite))
	var missing: Array[Rect2] = []
	for node in region.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if not sprite.is_visible_in_tree() or not sprite.texture or shadows.has_caster(sprite): continue
		if region.get_node("DayNightLighting").is_ancestor_of(sprite): continue
		var path := sprite.texture.resource_path.to_lower()
		if "grass" in path or "lily" in path or "waterfall" in path: continue
		missing.append(sprite.get_global_transform() * sprite.get_rect())
	markers.draw.connect(func():
		for foot in feet: markers.draw_rect(Rect2(foot - Vector2(2, 2), Vector2(4, 4)), Color.CYAN)
		for rect in missing: markers.draw_rect(rect, Color(1, 1, 0, 0.9), false, 2.0))
	shadows.set_meta("debug_quads", [])
	if args.has("only"): shadows.set_meta("only", args["only"])
	shadows.update_for_time(0)
	shadows.set_process(false)
	shadows.get_parent().set_process(false)  # DayNightLighting chamaria update_for_time de novo
	shadows.cast_group.self_modulate.a = 1.0
	if args.has("outline"):
		var outline := Node2D.new()
		outline.z_as_relative = false
		outline.z_index = 101
		region.add_child(outline)
		outline.draw.connect(func():
			for entry in shadows.get_meta("debug_quads"):
				var pts: PackedVector2Array = entry[1]
				pts.append(pts[0])
				outline.draw_polyline(pts, Color.MAGENTA if entry[2] == "StaticGroundShadows" else Color.BLUE, 1.0))
		for i in 3: await process_frame
		outline.queue_redraw()
	if args.has("hide"):
		for pass_name in String(args["hide"]).split("+"):
			var hidden_node := shadows.find_child(pass_name, true, false) as CanvasItem
			if hidden_node: hidden_node.hide()
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args.get("out", "user://debug_shadows.png"))
	print("DEBUG_SHADOWS feet=%d missing=%d" % [feet.size(), missing.size()])
	for n in [shadows, shadows.cast_group, shadows.get_node("CastShadows/StaticGroundShadows"), shadows.get_node("CastShadows/DynamicGroundShadows"), shadows.get_node("StaticContactShadows")]:
		print("XFW ", n.name, " global=", (n as Node2D).global_transform, " canvas=", (n as CanvasItem).get_global_transform_with_canvas().origin, " top=", (n as CanvasItem).top_level)
	if args.has("probe"):
		var xy0: PackedStringArray = args["probe"].split(",")
		var w0: Vector2 = root.get_canvas_transform().affine_inverse() * (Vector2(float(xy0[0]), float(xy0[1])) * (Vector2(root.get_visible_rect().size) / Vector2(1280, 720)))
		print("DRAWN_COUNT ", shadows.get_meta("debug_quads").size(), " w0=", w0, " visible_rect=", root.get_visible_rect(), " img=", root.get_texture().get_size(), " player_screen=", root.get_canvas_transform() * region.get_node("Player").global_position)
		var best := []
		for entry in shadows.get_meta("debug_quads"):
			var c: Vector2 = (entry[1][0] + entry[1][2]) * 0.5
			best.append([c.distance_to(w0), entry[0], entry[1]])
		best.sort_custom(func(a, b): return a[0] < b[0])
		var band := Rect2(3060, 3168, 130, 32)
		for entry in shadows.get_meta("debug_quads"):
			var bb := Rect2(entry[1][0], Vector2.ZERO)
			for q in entry[1]: bb = bb.expand(q)
			if bb.intersects(band): print("BAND ", entry[0], " pass=", entry[2], " bb=", bb)
		for entry in shadows.get_meta("debug_quads"):
			if Geometry2D.is_point_in_polygon(w0, entry[1]): print("DRAWN_OWNER ", entry[0], " quad=", entry[1])
		# Ponto da tela (1280×720) -> mundo; lista quem projeta sombra sobre ele.
		var xy: PackedStringArray = args["probe"].split(",")
		var screen := Vector2(float(xy[0]), float(xy[1])) * (Vector2(root.get_visible_rect().size) / Vector2(1280, 720))
		var world: Vector2 = root.get_canvas_transform().affine_inverse() * screen
		print("PROBE screen=%s world=%s" % [screen, world.round()])
		var profile: Dictionary = shadows.profile_at(int(hm[0]) * 60 + int(hm[1]))
		for id in shadows._casters:
			var sprite: Node2D = shadows._casters[id]
			if not shadows.casts_on_ground(sprite): continue
			var texture: Texture2D = shadows._texture_for(sprite)
			if not texture: continue
			var rect: Rect2 = shadows._rect_for(sprite, texture)
			var foot: Vector2 = shadows.foot_for(sprite)
			var direction: Vector2 = shadows.cast_direction(sprite)
			var xf: Transform2D = shadows.projection_for(sprite, foot, direction)
			var quad := PackedVector2Array([xf * rect.position, xf * Vector2(rect.end.x, rect.position.y), xf * rect.end, xf * Vector2(rect.position.x, rect.end.y)])
			var box := Rect2(quad[0], Vector2.ZERO)
			for q in quad: box = box.expand(q)
			if box.grow(4).has_point(world):
				print("PROBE_NEAR %s foot=%s box=%s" % [region.get_path_to(sprite), foot.round(), box])
			if Geometry2D.is_point_in_polygon(world, quad):
				print("PROBE_OWNER %s kind=%s foot=%s sprite_pos=%s tex=%s rect=%s scale=%s" % [region.get_path_to(sprite), shadows._kinds[id], foot.round(), sprite.global_position.round(), texture.resource_path.get_file(), rect, sprite.global_scale])
	quit()

extends SceneTree
## Native pixel regression with original map props and the original player sprite.
## Isolated viewport checks occlusion itself, separately from full-map navigation.
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")

func capture(view: SubViewport) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()

func run() -> void:
	var samples := {}
	var source: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	for name_ in ["VegetationHigh","ExpandedForest","Decorations","WoodlandDetails"]:
		for prop in source.get_node(name_).get_children():
			var sprite := prop as Sprite2D if prop is Sprite2D else prop.get_node_or_null("Sprite") as Sprite2D
			if sprite == null or sprite.texture == null or not prop.visible: continue
			var path := sprite.texture.resource_path.to_lower()
			for kind in ["oak","bush","mushroom","log"]:
				if kind in path and not samples.has(kind): samples[kind] = prop
	var view := SubViewport.new()
	view.size = Vector2i(320,320)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	for kind in samples:
		var world := Node2D.new()
		var group := Node2D.new()
		group.name = "Decorations"
		world.add_child(group)
		var prop: Node2D = samples[kind].duplicate()
		if prop is Sprite2D:
			var direct := prop as Sprite2D
			prop = Node2D.new()
			direct.name = "Sprite"
			direct.position = Vector2.ZERO
			prop.add_child(direct)
		prop.position = Vector2(160,240)
		group.add_child(prop)
		var sprite: Sprite2D = prop.get_node("Sprite")
		sprite.material = null
		var actor := Node2D.new()
		var art := Sprite2D.new()
		art.texture = load("res://assets/player/rotations/south.png")
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.position = Vector2(0,-34)
		art.scale = Vector2(.65,.65)
		actor.add_child(art)
		world.add_child(actor)
		view.add_child(world)
		preload("res://scripts/world/visual_rules.gd").new().apply(world,{})
		for side in [-1,1]:
			actor.position = prop.position + Vector2(0,side*12)
			actor.hide()
			var object_only: Image = await capture(view)
			prop.hide()
			actor.show()
			var actor_only: Image = await capture(view)
			prop.show()
			var combined: Image = await capture(view)
			if kind == "oak" and side < 0:
				object_only.save_png("res://docs/world/living_v3/visual/depth_object_isolated.png")
				actor_only.save_png("res://docs/world/living_v3/visual/depth_player_isolated.png")
			var overlap := 0
			var wrong := 0
			for y in range(100,270):
				for x in range(120,200):
					var a := actor_only.get_pixel(x,y)
					var b := object_only.get_pixel(x,y)
					if a.a < .99 or b.a < .99 or absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) < .1: continue
					overlap += 1
					var expected := b if side < 0 else a
					var actual := combined.get_pixel(x,y)
					if absf(expected.r-actual.r)+absf(expected.g-actual.g)+absf(expected.b-actual.b) > .04: wrong += 1
			checks += 1
			if overlap < 8 or wrong > 0: failures += 1
			print("DEPTH ",kind," side=",side," overlap=",overlap," wrong=",wrong)
			combined.save_png("res://docs/world/living_v3/visual/depth_%s_%s.png" % [kind,"behind" if side < 0 else "front"])
		world.free()
		await process_frame
	if samples.size() != 4:
		failures += 1
		push_error("Missing representative prop class: " + str(samples.keys()))
	source.free()
	view.queue_free()
	await process_frame
	print("NATIVE_DEPTH: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)

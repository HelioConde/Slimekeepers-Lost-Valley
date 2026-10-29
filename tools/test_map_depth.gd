extends SceneTree
## Real regions/parents/TileMap cells and the actual player. Never reparent props.
var failures := 0
var checks := 0
var records := []
var stage := "before"

func _initialize() -> void: call_deferred("run")

func shot() -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(960,540)
	root.transparent_bg = true
	if OS.get_cmdline_user_args().size(): stage = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute("res://docs/world/depth_followup")
	for map in ["FlorestaDoDespertarV2","ValeDasNascentes"]:
		var region: Node2D = load("res://scenes/regions/%s.tscn" % map).instantiate()
		root.add_child(region)
		current_scene = region
		for i in 8: await physics_frame
		region.process_mode = Node.PROCESS_MODE_DISABLED
		var player: CharacterBody2D = region.player
		var camera: Camera2D = player.get_node("Camera2D")
		camera.limit_left = -10000
		camera.limit_top = -10000
		camera.limit_right = 10000
		camera.limit_bottom = 10000
		camera.position_smoothing_enabled = false
		var samples := []
		var low := region.get_node_or_null("VegetationLow") as TileMapLayer
		if low:
			for source_id in [2,3,5,6,7,8]:
				var cells := low.get_used_cells_by_id(source_id)
				if cells.is_empty(): continue
				var cell: Vector2i = cells[0]
				var source: TileSetAtlasSource = low.tile_set.get_source(source_id)
				var used: Rect2i = source.texture.get_image().get_used_rect()
				var foot := low.to_global(low.map_to_local(cell) + Vector2(0,used.end.y-source.texture.get_height()*.5))
				samples.append({"name":"tile_"+str(source_id),"object":low,"foot":foot,"height":used.size.y,"cell":cell,"source":source_id,"alternative":low.get_cell_alternative_tile(cell),"atlas":low.get_cell_atlas_coords(cell)})
		var found := {}
		for group_name in ["WoodlandDetails","FlowerClusters","Decorations","LowVegetation"]:
			var group := region.get_node_or_null(group_name)
			if group == null: continue
			for prop in group.get_children():
				var sprite := prop as Sprite2D if prop is Sprite2D else prop.get_node_or_null("Sprite") as Sprite2D
				if sprite == null or sprite.texture == null or not prop.visible: continue
				for kind in ["flower","mushroom","fern","log","bush"]:
					if kind in sprite.texture.resource_path and not found.has(kind):
						found[kind] = true
						samples.append({"name":"prop_"+kind,"object":prop,"foot":prop.global_position,"height":sprite.texture.get_image().get_used_rect().size.y*sprite.scale.y})
		var art := region.get_node_or_null("MapArt")
		var curated_seen := {}
		if art:
			for prop in art.get_children():
				var key: String = prop.get_meta("curated_asset","")
				if key.is_empty() or curated_seen.has(key): continue
				curated_seen[key]=true
				var sprite: Sprite2D=prop.get_node("Sprite")
				samples.append({"name":"curated_"+key,"object":prop,"foot":prop.global_position,"height":sprite.texture.get_image().get_used_rect().size.y*sprite.scale.y})
		for sample in samples:
			# Isolate visibility, preserving every ancestor transform and sorting flag.
			for child in region.get_children():
				if child is CanvasItem: child.hide()
				if child is CanvasLayer: child.visible = false
			var object: Node2D = sample.object
			if object is TileMapLayer:
				object.clear()
				object.set_cell(sample.cell,sample.source,sample.atlas,sample.alternative)
			else:
				for sibling in object.get_parent().get_children():
					if sibling is CanvasItem: sibling.hide()
			var ancestor: Node = object
			while ancestor != region:
				if ancestor is CanvasItem: ancestor.show()
				ancestor = ancestor.get_parent()
			for scenario in [{"name":"lower_base","offset":-2.0,"side":-1},{"name":"upper_half","offset":-maxf(8,float(sample.height)*.5),"side":-1},{"name":"front","offset":6.0,"side":1}]:
				var side: int = scenario.side
				player.position = sample.foot + Vector2(0,scenario.offset)
				camera.reset_smoothing()
				camera.force_update_scroll()
				object.show()
				player.hide()
				var object_only: Image = await shot()
				object.hide()
				player.show()
				var player_only: Image = await shot()
				object.show()
				var combined: Image = await shot()
				var overlap := 0
				var wrong := 0
				for y in range(200,430):
					for x in range(530,750):
						var a := player_only.get_pixel(x,y)
						var b := object_only.get_pixel(x,y)
						if a.a < .99 or b.a < .99 or absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)<.1: continue
						overlap += 1
						var expected := b if side < 0 else a
						var actual := combined.get_pixel(x,y)
						if absf(expected.r-actual.r)+absf(expected.g-actual.g)+absf(expected.b-actual.b)>.04: wrong += 1
				checks += 1
				if wrong or overlap < 5: failures += 1
				var result := {"map":map,"object":sample.name,"scenario":scenario.name,"side":side,"overlap":overlap,"wrong":wrong,"foot":str(sample.foot)}
				records.append(result)
				print("MAP_DEPTH ",JSON.stringify(result))
				combined.save_png("res://docs/world/depth_followup/%s_%s_%s_%s.png" % [stage,map,sample.name,scenario.name])
		region.free()
		await process_frame
	FileAccess.open("res://docs/world/depth_followup/%s.json" % stage,FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	print("MAP_DEPTH: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)

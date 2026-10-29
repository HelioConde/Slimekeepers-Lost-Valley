extends SceneTree
## Physical acceptance of the expanded world, not just layout metadata.
var failures: Array[String] = []
var checks := 0
var samples := 0
var region: Node2D

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var path := "res://scenes/regions/FlorestaDoDespertarV2.tscn"
	check(ResourceLoader.exists(path), "Expanded scene exists")
	if not failures.is_empty():
		finish()
		return
	region = load(path).instantiate()
	root.add_child(region)
	current_scene = region
	for i in 6: await physics_frame
	var layout = load("res://scripts/world/forest_layout.gd")
	check(region.get_node("Ground").get_used_cells().size() == 40000, "40,000 real ground cells")
	check(region.get_node("Ground").get_used_rect() == Rect2i(0,0,200,200), "200x200 grid without scaling")
	check(region.player.position.is_equal_approx(Vector2(3200,3200)), "Central player spawn")
	var camera: Camera2D = region.player.get_node("Camera2D")
	check(camera.limit_right == 6400 and camera.limit_bottom == 6400, "Camera bounds 6400")
	check(camera.zoom.is_equal_approx(Vector2(1.14,1.14)), "Gameplay zoom preserved")
	check(region.get_node("VegetationHigh").get_child_count() > 900, "Original tree population preserved")
	var legacy := load("res://scenes/world.tscn").instantiate() as Node2D
	for layer_name in ["GroundDetails","VegetationLow"]:
		var original: TileMapLayer = legacy.get_node(layer_name)
		var expanded: TileMapLayer = region.get_node(layer_name)
		var preserved := true
		for cell in original.get_used_cells():
			var translated := cell+Vector2i(50,50)
			# The expanded pond intentionally relocates terrestrial tiles rooted in water.
			if layer_name == "VegetationLow":
				var water: Polygon2D = region.get_node("NaturalSpring/Pool/Water")
				var atlas := original.tile_set.get_source(original.get_cell_source_id(cell)) as TileSetAtlasSource
				var data := original.get_cell_tile_data(cell)
				var foot_y := atlas.texture.get_image().get_used_rect().end.y - atlas.texture_region_size.y * .5 - data.texture_origin.y
				var foot := expanded.to_global(expanded.map_to_local(translated) + Vector2(0, foot_y))
				if Geometry2D.is_point_in_polygon(water.to_local(foot), water.polygon): continue
			if original.get_cell_source_id(cell) != expanded.get_cell_source_id(translated) or original.get_cell_atlas_coords(cell) != expanded.get_cell_atlas_coords(translated) or original.get_cell_alternative_tile(cell) != expanded.get_cell_alternative_tile(translated):
				preserved = false
		check(preserved,"User painted core cells preserved: "+layer_name)
	var visibility_preserved := true
	for tree in legacy.get_node("VegetationHigh").get_children():
		if tree.visible != region.get_node("VegetationHigh").get_node(str(tree.name)).visible: visibility_preserved=false
	check(visibility_preserved,"User tree visibility overrides preserved")
	legacy.free()
	for water_path in ["NaturalSpring/Pool/Water","SouthernBrook/Water"]:
		var water: Polygon2D = region.get_node(water_path)
		var trees_in_water := 0
		for trees in [region.get_node("VegetationHigh"),region.get_node("ExpandedForest")]:
			for tree in trees.get_children():
				if tree.has_node("SolidBase") and Geometry2D.is_point_in_polygon(water.to_local(tree.global_position),water.polygon):
					trees_in_water+=1
					print("WATER_TRUNK ",tree.name," ",tree.global_position)
		check(trees_in_water==0,"Tree trunks stand on dry ground: "+water_path)
	check(not region.get_node("NaturalSpring").has_node("RockSpring"), "Rejected water spout stays removed")
	check(region.get_node("PointsOfInterest").get_child_count() >= 5, "Five or more discoverable micro locations")
	check(region.get_node("NoSlimeSpawnArea").get_node("CollisionShape2D").shape.radius == 960, "Explicit 30 tile exclusion")
	var expected_population := 10 if ResourceLoader.exists("res://assets/slimes/living_v3/musguinho/frames.tres") else 8
	check(region.slimes.size() == expected_population, "Expected bounded forest population")
	check(region.slimes.filter(func(s):return s.slime_type=="brotinho").size()==8,"Eight original Brotinhos preserved")
	var ids := {}
	for slime in region.slimes:
		check(slime.position.distance_to(layout.SPAWN) >= 960, "Slime outside exclusion: " + slime.persistent_id)
		check(slime.slime_type in ["brotinho","musguinho"], "Only forest species in first forest")
		check(not ids.has(slime.persistent_id), "Unique slime id")
		ids[slime.persistent_id] = true
	for label in layout.trails():
		var curve: Curve2D = layout.trails()[label]
		check(clear_curve(curve), "Traversable player capsule route: " + label)
	check(not occupied(layout.SPAWN), "Spawn capsule unobstructed")
	for y in range(-128,129,32):
		for x in range(-128,129,32):
			check(not occupied(layout.SPAWN + Vector2(x,y)), "Safe central walking area")
	for h in layout.habitats():
		check(not occupied(h.center), "Habitat accessible: " + h.id)
	region.player.position = layout.SOUTH_ARRIVAL
	for i in 4: await physics_frame
	check(not occupied(layout.SOUTH_ARRIVAL), "Southern arrival is clear")
	var friend: Node2D = region.slimes[0]
	var friend_id: String = friend.persistent_id
	friend.make_friend()
	region._update_hud()
	check(region.friends_count == 1, "HUD counts unique persistent friendships")
	friend.free()
	region.habitat_manager._elapsed += 21.0
	region.habitat_manager.populate()
	check(region.slimes.size() == expected_population, "Missing habitat slot respawns once")
	check(region.friends_count == 1, "Respawn cannot inflate the friendship counter")
	var restored := false
	for slime in region.slimes:
		if slime.persistent_id == friend_id: restored=slime.befriended
	check(restored, "Respawn restores the same individual friendship")
	finish()

func occupied(at: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 12
	shape.height = 34
	q.shape = shape
	q.transform = Transform2D(0,at+Vector2(0,-17))
	q.collision_mask = 2
	return not region.get_world_2d().direct_space_state.intersect_shape(q,1).is_empty()

func clear_curve(curve: Curve2D) -> bool:
	var length := curve.get_baked_length()
	var ok := true
	for i in range(int(length/12)+1):
		var at := curve.sample_baked(minf(i*12,length))
		if at.x < 24 or at.y < 44 or at.x > 6376 or at.y > 6376: continue
		samples += 1
		if occupied(at):
			if ok: print("BLOCKED ",at)
			ok = false
	return ok

func finish() -> void:
	print("FOREST_V2: checks=",checks," failures=",failures.size()," capsule_samples=",samples)
	if is_instance_valid(region):
		region.queue_free()
		await process_frame
		await process_frame
	quit(0 if failures.is_empty() else 1)

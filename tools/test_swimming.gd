extends SceneTree
var failures := 0
var checks := 0
func check(value: bool, description: String) -> void:
	checks += 1
	if not value: failures += 1
	print("PASS " if value else "FAIL ",description)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(960,540)
	var region: Node2D = load("res://scenes/regions/ValeDasNascentes.tscn").instantiate()
	root.add_child(region)
	current_scene = region
	for frame in 8: await physics_frame
	var manager: Node2D = region.habitat_manager
	check(manager.water_bodies.size() == preload("res://scripts/world/region_surfaces.gd").water_parts().size(),"Every baked water body classified without excluding cliff colliders")
	check(preload("res://scripts/world/region_surfaces.gd").classify_water(region) == manager.water_bodies,"Water classification remains stable on repeat calls")
	print("WATER_BODIES ",manager.water_bodies.size())
	for habitat in manager.habitats:
		var wet_targets := 0
		for point: Vector2 in habitat.water_points:
			if manager.is_water(point): wet_targets += 1
		check(wet_targets > 0,"Habitat "+str(habitat.id)+" has real water destinations")
	var visited := {}
	for slime in manager.spawned:
		slime.set_physics_process(false)
	for slime in manager.spawned:
		if visited.has(slime.habitat.id): continue
		visited[slime.habitat.id] = true
		region.player.position = slime.habitat.center+Vector2(0,80)
		region.player.get_node("Camera2D").reset_smoothing()
		var target: Vector2 = slime.habitat.water_points[0]
		# Choose a water destination not obstructed by its resting neighbour.
		for candidate: Vector2 in slime.habitat.water_points:
			if manager.is_position_allowed(candidate,slime.habitat,slime): target=candidate;break
		var shore: Vector2 = slime.position
		var entered := false
		var steps := 0
		slime._begin_visit("swim",target,60)
		while steps < 1400 and slime.position.distance_to(target)>6 and slime._moving:
			await physics_frame
			slime._physics_process(1.0/60)
			entered = entered or slime.swimming
			steps += 1
		check(entered and slime.position.distance_to(target)<7,slime.persistent_id+" enters water using physics movement")
		if not entered or slime.position.distance_to(target)>=7: print("SWIM_DIAGNOSTIC ",slime.position," target=",target," steps=",steps," behavior=",slime.behavior," path=",slime._swim_path)
		check(slime.get_collision_exceptions().size()==manager.water_bodies.size(),"Only tagged water bodies are bypassed")
		if DisplayServer.get_name() != "headless" and entered:
			region.player.get_node("Camera2D").position = slime.position-region.player.position
			region.player.get_node("Camera2D").reset_smoothing()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/world/depth_followup/swimming_%s.png" % slime.habitat.id)
		steps = 0
		slime._begin_visit("swim",shore,60)
		while steps < 1400 and slime.position.distance_to(shore)>6 and slime._moving:
			await physics_frame
			slime._physics_process(1.0/60)
			steps += 1
		check(not slime.swimming and slime.position.distance_to(shore)<7,"Returns from water to its accessible bank")
		# The very same water still blocks the original player collision mask.
		var query := PhysicsPointQueryParameters2D.new()
		query.position = target
		query.collision_mask = region.player.collision_mask
		check(not region.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"Water remains solid for player")
	region.queue_free()
	await process_frame
	print("SWIMMING: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)

extends SceneTree
## Existing real maps, physics and helper wiring; generated fixture only until wildlife art arrives.
var checks := 0
var failures := 0
var sampled := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var fixture := SpriteFrames.new()
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	fixture.add_frame("default", ImageTexture.create_from_image(image))
	var scenes := ["FlorestaDoDespertarV2", "ValeDasNascentes"]
	var visits := [[Vector2(3200,3200),Vector2(4480,3270),Vector2(1980,2120)], [Vector2(1600,180),Vector2(1070,1400),Vector2(1000,1980)]]
	var body := CircleShape2D.new()
	body.radius = 7.0
	for map_index in scenes.size():
		var region = load("res://scenes/regions/%s.tscn" % scenes[map_index]).instantiate()
		root.add_child(region)
		current_scene = region
		var life = region.ecosystem
		region.set_process(false)
		region.player.set_physics_process(false)
		region.habitat_manager.set_process(false)
		region.environmental_audio.set_muted(true)
		region.environmental_audio.set_process(false)
		life.set_process(false)
		life.set_reduced_motion(false)
		for species in ["squirrel", "bird"]:
			var path := "res://assets/wildlife/living_v3/%s/frames.tres" % species
			life.configure_wildlife_frames(species, load(path) if ResourceLoader.exists(path) else fixture)
		for frame in 4:
			await physics_frame
		var safe := true
		var bounded := true
		var observed := 0
		for location: Vector2 in visits[map_index]:
			region.player.position = location
			region.player.get_node("Camera2D").reset_smoothing()
			for frame in 3:
				await process_frame
			for step in 160:
				life._process(0.125)
				var state: Dictionary = life.debug_snapshot()
				bounded = bounded and state.wildlife <= 1
				observed = maxi(observed, state.wildlife)
				for record: Dictionary in life.wildlife_snapshot():
					if record.state == "fly": continue
					var query := PhysicsShapeQueryParameters2D.new()
					query.shape = body
					query.transform = Transform2D(0,record.position)
					query.collision_mask = 2
					safe = safe and region.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty() and life._valid_ground(record.position)
					sampled += 1
		_check(observed > 0, "%s spawns local wildlife at existing tree anchors" % scenes[map_index])
		_check(bounded, "%s limits decorative fauna to one individual" % scenes[map_index])
		_check(safe, "%s ground wildlife remains clear of physical water and props" % scenes[map_index])
		var saved: Array[Node] = []
		for record: Dictionary in life._wildlife:
			saved.append(record.sprite)
		region.free()
		await process_frame
		var released := true
		for sprite in saved:
			released = released and not is_instance_valid(sprite)
		_check(released, "%s teardown releases wildlife siblings" % scenes[map_index])
	print("ENVIRONMENT_REGIONS: %d checks; %d failures; %d physical creature samples" % [checks, failures, sampled])
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

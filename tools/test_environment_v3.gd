extends SceneTree
## Contract tests for shared weather, vegetation reactions and bounded wildlife.
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists("res://scripts/world/environment_state.gd"):
		_check(false, "Reusable environmental state exists")
		_finish()
		return
	var weather = load("res://scripts/world/environment_state.gd").new()
	weather.set_conditions("night", 2.0, -1.0, 4.0)
	var conditions: Dictionary = weather.snapshot()
	_check(conditions.period == "night" and conditions.rain == 1.0 and conditions.wind == 0.0 and conditions.fog == 1.0, "Weather inputs clamp to supported bounds")
	weather.set_conditions("unknown", 0.0, 1.0, 0.0)
	_check(weather.snapshot().period == "morning", "Unsupported periods fall back to morning")
	var life = load("res://scripts/world/forest_life.gd").new()
	var player := Node2D.new()
	root.add_child(player)
	player.position = Vector2(1000, 1000)
	var flowers: Array[Vector2] = [Vector2(1002, 1002), Vector2(1150, 1050)]
	life.configure(player, flowers)
	life.set_environment_state(weather)
	var grounds: Array[Vector2] = [Vector2(1220, 1030), Vector2(1180, 1200), Vector2(1080, 1210)]
	life.configure_wildlife(grounds, func(at: Vector2) -> bool: return at.x >= 900 and at.x <= 1250 and at.y >= 900 and at.y <= 1250)
	# Generated flat fixture is not a game asset.
	var picture := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	picture.fill(Color.WHITE)
	var frames := SpriteFrames.new()
	frames.add_frame("default", ImageTexture.create_from_image(picture))
	life.configure_wildlife_frames("squirrel", frames)
	life.configure_wildlife_frames("bird", frames)
	root.add_child(life)
	_check(life.debug_snapshot().wildlife == 0, "Wildlife waits until the first simulation tick before querying scene physics")
	life.set_reduced_motion(false)
	life.set_process(false)
	_check(life.get_wind_material("pine") == life.get_wind_material("pine"), "Pines share one material")
	_check(life.get_wind_material("pine") != life.get_wind_material("oak"), "Pine and broadleaf response differs")
	var slime := Node2D.new()
	root.add_child(slime)
	slime.position = Vector2(1040, 1010)
	life.register_reactor(slime)
	life.register_reactor(slime)
	life._process(0.125)
	_check(life.debug_snapshot().reactors == 2, "Player and unique nearby slime react with plants")
	_check(life.debug_snapshot().butterfly_flees > 0, "Approaching player gently startles nearby butterflies")
	# Each species reacts correctly without requiring both to crowd one viewport.
	for species in ["squirrel","bird"]:
		while not life._wildlife.is_empty():life._remove_wildlife(0)
		life._wildlife_frames.clear()
		life.configure_wildlife_frames(species,frames)
		life._wildlife_respawn=0
		player.position=Vector2(1000,1000)
		life._process(.125)
		var records: Array=life.wildlife_snapshot()
		_check(records.size()==1,"One occasional animal spawns at a time")
		if not records.is_empty():
			_check(player.position.distance_to(records[0].position)>=180,"Animal never spawns on the player")
			player.position=records[0].position-Vector2(20,0)
			life._process(.125)
			_check(life.wildlife_snapshot()[0].state==("flee" if species=="squirrel" else "fly"),"Approach startles "+species)
	life.configure_wildlife_frames("squirrel",frames)
	life.configure_wildlife_frames("bird",frames)
	player.position = Vector2(1000, 1000)
	var bounded := true
	var saw_wildlife := false
	var safe_ground := true
	var landed_on_flowers := true
	for step in 960:
		life._process(0.125)
		var state: Dictionary = life.debug_snapshot()
		saw_wildlife = saw_wildlife or state.wildlife > 0
		bounded = bounded and state.wildlife<=1 and state.cloud_shadows <= 1 and state.leaves <= 8
		for record: Dictionary in life.wildlife_snapshot():
			if record.state != "fly":
				safe_ground = safe_ground and record.position.x >= 900 and record.position.x <= 1250 and record.position.y >= 900 and record.position.y <= 1250
		for butterfly: Dictionary in life._butterflies:
			if butterfly.landed:
				landed_on_flowers = landed_on_flowers and butterfly.position in flowers
	_check(saw_wildlife and bounded, "Wildlife and clouds remain within budgets for two simulated minutes")
	_check(safe_ground, "Ground creatures never step across invalid terrain")
	_check(landed_on_flowers, "Butterflies return to flowers after escaping rather than resting in midair")
	slime.free()
	life._process(0.125)
	_check(life.debug_snapshot().reactors == 1, "Freed slime reactor is safely pruned")
	life.set_reduced_motion(true)
	var before: Array = life.wildlife_snapshot()
	for step in 20:
		life._process(0.125)
	_check(before == life.wildlife_snapshot(), "Reduce motion freezes wildlife positions and states")
	_check(life.debug_snapshot().cloud_shadows == 0, "Reduce motion removes cloud shadows")
	_check(life.get_wind_material("plant").get_shader_parameter("reactor_count") == 0, "Reduce motion disables plant impulses")
	life.set_reduced_motion(false)
	player.position = Vector2(6000, 6000)
	for step in 20:
		life._process(0.125)
	_check(life.debug_snapshot().wildlife == 0, "Wildlife is culled outside its anchored region")
	player.position = Vector2(1000, 1000)
	for step in 320:
		life._process(0.125)
	var siblings: Array[Node] = []
	for record: Dictionary in life._wildlife:
		siblings.append(record.sprite)
	_check(not siblings.is_empty(), "Returning to an anchored region repopulates wildlife")
	life.free()
	await process_frame
	var released := true
	for sprite in siblings:
		released = released and not is_instance_valid(sprite)
	_check(released, "Destroying the controller releases every sibling wildlife sprite")
	player.free()
	_finish()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _finish() -> void:
	print("ENVIRONMENT_V3: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

extends SceneTree
## Real habitats and creatures: configuration, night behavior, reactions and social bounds.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager = load("res://scripts/world/forest_habitats.gd").new()
	_check(manager.has_method("set_environment_state"), "Habitats accept environmental state for sleeping creatures")
	if not manager.has_method("set_environment_state"):
		manager.free()
		_finish()
		return
	var region := Node2D.new()
	root.add_child(region)
	var player := CharacterBody2D.new()
	region.add_child(player)
	player.position = Vector2(100, 100)
	region.add_child(manager)
	var data: Array[Dictionary] = [{"id": "bank", "center": Vector2(850, 350), "radius": 250.0, "species_slots": ["brotinho", "brotinho"], "spawn_points": [Vector2(800, 350), Vector2(880, 350)], "flower_points": [Vector2(830, 450)]}]
	manager.configure(region, player, Vector2(100, 100), data, {"world_bounds": Rect2(0, 0, 1400, 900), "exclusion_radius": 120.0, "max_population": 2, "protect_initial_view": false, "session_key": "test_ecosystem_friends"})
	await physics_frame
	await physics_frame
	manager.populate()
	_check(manager.spawned.size() == 2, "Custom small region and species slots populate actual bank positions")
	if manager.spawned.size() != 2:
		region.free()
		_finish()
		return
	var slime = manager.spawned[0]
	var peer = manager.spawned[1]
	for creature in manager.spawned:
		creature.set_physics_process(false)
	_check(slime.persistent_id == "brotinho/bank/0", "Species slots preserve legacy Brotinho identity")
	_check(not manager.is_position_allowed(Vector2(1450, 350), {"center": Vector2(1450, 350), "radius": 100.0}), "Custom bounds reject outside world")
	_check(not manager.is_position_allowed(Vector2(100, 100), {"center": Vector2(100, 100), "radius": 100.0}), "Custom exclusion remains protected")
	for index in 10:
		manager.populate()
	_check(manager.spawned.size() == 2, "Configured cap and stable slots prevent duplicate population")
	player.position = Vector2(500, 350)
	manager.set_environment_state({"period": "night"})
	slime._choose_behavior()
	_check(slime.behavior == "sleep", "Night makes a safe creature sleep")
	slime._physics_process(0.1)
	_check(slime.sprite.animation == &"sleep" and slime.velocity == Vector2.ZERO, "Sleep uses real animation and stops navigation")
	manager.set_environment_state({"period": "day"})
	slime._physics_process(0.1)
	_check(slime.behavior != "sleep", "Morning wakes night sleeper without waiting for full sleep duration")
	player.position = slime.position - Vector2(0, 90)
	player.velocity = Vector2(0, 210)
	slime._choose_behavior()
	_check(slime.behavior == "flee", "Approaching runner takes priority over leisure")
	_check(manager.is_position_allowed(slime._target, slime.habitat, slime), "Retreat target stays collision free and within habitat")
	player.velocity = Vector2.ZERO
	player.position = Vector2(500, 350)
	slime.position = Vector2(800, 350)
	peer.position = Vector2(880, 350)
	slime.behavior = "rest"
	peer.behavior = "rest"
	slime._social_cooldown = 0.0
	peer._social_cooldown = 0.0
	_check(slime.try_social_interaction(), "Available neighboring slimes can start a bounded social visit")
	_check(not peer.try_social_interaction(), "Partner reservation prevents overlapping social interactions")
	var shared_play_frames := 0
	for frame in 180:
		slime._physics_process(1.0 / 30.0)
		peer._physics_process(1.0 / 30.0)
		if slime.behavior == "play" and peer.behavior == "play":
			shared_play_frames += 1
	_check(shared_play_frames > 20 and shared_play_frames < 120, "Partners share a brief play moment and then stop")
	_check(slime.position.distance_to(peer.position) >= 49.9, "Social interaction preserves capsule separation")
	_check(slime._social_cooldown > 0 and peer._social_cooldown > 0, "Both social partners receive cooldown")
	_check(slime.make_friend() and not slime.make_friend(), "Friendship is idempotent")
	_check(get_meta("test_ecosystem_friends", {}).get("brotinho/bank/0", false), "Configured session key stores identity friendship")
	var saved_position: Vector2 = slime.position
	player.position = Vector2(-2000, -2000)
	for frame in 60:
		slime._physics_process(1.0 / 30.0)
	_check(slime.position == saved_position and slime.velocity == Vector2.ZERO, "Distant AI suspends movement")
	var species = load("res://scripts/world/slime_species.gd")
	_check(species.definition("musguinho").shyness > species.definition("brotinho").shyness, "Musguinho data favors timid behavior")
	_check(species.definition("bolhinha").sociability > species.definition("musguinho").sociability, "Bolhinha data favors social play")
	for creature in manager.spawned:
		creature.free()
	manager.free()
	manager = load("res://scripts/world/forest_habitats.gd").new()
	region.add_child(manager)
	manager.configure(region, player, Vector2(100, 100), data, {"world_bounds": Rect2(0, 0, 1400, 900), "exclusion_radius": 120.0, "max_population": 2, "protect_initial_view": false, "session_key": "test_ecosystem_friends"})
	manager.populate()
	_check(manager.spawned.size() == 2 and manager.spawned[0].befriended, "Custom session friendship restores after region recreation")
	for creature in manager.spawned:
		creature.free()
	manager.free()
	manager = load("res://scripts/world/forest_habitats.gd").new()
	region.add_child(manager)
	data[0].species_slots = ["brotinho", "bolhinha"]
	data[0].water_points = [Vector2(880, 410)]
	manager.configure(region, player, Vector2(100, 100), data, {"world_bounds": Rect2(0, 0, 1400, 900), "exclusion_radius": 120.0, "max_population": 2, "protect_initial_view": false})
	manager.populate()
	_check(manager.spawned.size() == 2, "Real Bolhinha artwork enables mixed species slots")
	if manager.spawned.size() == 2:
		var water_slime = manager.spawned[1]
		water_slime.set_physics_process(false)
		_check(water_slime.display_name() == "Bolhinha" and water_slime.sprite.sprite_frames.resource_path == "res://assets/slimes/living_v3/bolhinha/frames.tres", "Water species uses its own genuine SpriteFrames")
		player.position = Vector2(500, 350)
		water_slime._social_cooldown = 100.0
		for attempt in 20:
			water_slime._choose_behavior()
			if water_slime.behavior == "splash":
				break
		_check(water_slime.behavior == "splash" and water_slime._target == Vector2(880, 410), "Aquatic curiosity visits the provided accessible water bank")
		water_slime.position = Vector2(880, 410)
		water_slime._physics_process(0.1)
		_check(water_slime.sprite.animation == &"splash", "Arriving at water plays the actual splash animation")
		for animation in ["idle", "move", "happy", "curious", "plant", "play", "splash"]:
			_check(water_slime.sprite.sprite_frames.has_animation(animation) and water_slime.sprite.sprite_frames.get_frame_count(animation) > 1, "Bolhinha has usable multiframe animation: " + animation)
		if water_slime.sprite.sprite_frames.has_animation("sleep") or "--require-complete-art" in OS.get_cmdline_user_args():
			_check(water_slime.sprite.sprite_frames.has_animation("sleep") and water_slime.sprite.sprite_frames.get_frame_count("sleep") > 1, "Completed Bolhinha artwork includes multiframe sleep")
		else:
			print("ART_PENDING: Bolhinha sleep animation is absent; completion gate requires --require-complete-art")
		water_slime.position = Vector2(880, 350)
		water_slime._rest(0.1)
		var resting_frames := 0
		var moving_frames := 0
		var stayed_in_habitat := true
		for frame in 3600:
			water_slime._physics_process(1.0 / 30.0)
			if water_slime.behavior in ["rest", "sleep"]:
				resting_frames += 1
			if water_slime.velocity.length() > 0.0:
				moving_frames += 1
			stayed_in_habitat = stayed_in_habitat and water_slime.position.distance_to(Vector2(850, 350)) <= 238.0
		_check(resting_frames > 100 and moving_frames > 10, "Two simulated minutes contain movement and genuine pauses")
		_check(stayed_in_habitat, "Aquatic navigation never escapes its habitat during a long simulation")
	region.free()
	remove_meta("test_ecosystem_friends")
	_finish()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _finish() -> void:
	print("SLIME_ECOSYSTEM: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

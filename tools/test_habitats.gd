extends SceneTree
## Exercises real physics, population, exclusion, identity and session friendship.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists("res://scripts/world/forest_habitats.gd"):
		_check(false, "Habitat controller exists")
		_finish()
		return
	var script = load("res://scripts/world/forest_habitats.gd")
	var region := Node2D.new()
	root.add_child(region)
	var player := CharacterBody2D.new()
	region.add_child(player)
	player.position = Vector2(3200, 3200)
	var habitats: Array[Dictionary] = [
		{"id": "H01", "center": Vector2(4480, 3270), "radius": 220.0},
		{"id": "H02", "center": Vector2(1980, 2120), "radius": 220.0},
		{"id": "H03", "center": Vector2(3350, 4580), "radius": 220.0},
		{"id": "H04", "center": Vector2(4880, 1700), "radius": 220.0}]
	var manager = script.new()
	region.add_child(manager)
	manager.configure(region, player, Vector2(3200, 3200), habitats)
	await physics_frame
	await physics_frame
	manager.populate()
	_check(manager.spawned.size() == 8, "Four habitats spawn eight slimes")
	var ids: Dictionary = {}
	for slime in manager.spawned:
		_check(slime.position.distance_to(Vector2(3200, 3200)) >= 960.0, "Every initial spawn respects clearing exclusion")
		_check(not ids.has(slime.persistent_id), "Every instance has a unique persistent identity")
		ids[slime.persistent_id] = true
	_check(ids.has("brotinho/H01/0") and ids.has("brotinho/H04/1"), "Persistent identity includes species, habitat and slot")
	var separated := true
	for i in manager.spawned.size():
		for j in range(i + 1, manager.spawned.size()):
			separated = separated and manager.spawned[i].position.distance_to(manager.spawned[j].position) >= 50.0
	_check(separated, "Spawn spacing avoids prolonged sprite overlap")
	for i in 25:
		manager.populate()
	_check(manager.spawned.size() == 8, "Repeated population never duplicates live slots")
	var friend = manager.spawned[0]
	_check(friend.make_friend(), "First interaction makes one friendship")
	_check(not friend.make_friend(), "Repeated interaction does not count twice")
	_check(get_meta("forest_slime_friends", {}).get(friend.persistent_id, false), "Friendship is persisted immediately by instance")
	var friend_id: String = friend.persistent_id
	var removed = manager.spawned[1]
	var removed_id: String = removed.persistent_id
	removed.free()
	manager.populate()
	_check(manager.spawned.size() == 7, "Missing slot waits for respawn cooldown")
	manager._process(20.1)
	manager.populate()
	_check(manager.spawned.size() == 8, "Missing slot respawns after cooldown")
	_check(manager.spawned.any(func(slime): return slime.persistent_id == removed_id), "Respawn preserves instance identity")
	# A collision body in the habitat must reject both spawn probes and moving slimes.
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	wall.collision_mask = 0
	wall.position = Vector2(4490, 3270)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(24, 300)
	shape.shape = rectangle
	wall.add_child(shape)
	region.add_child(wall)
	await physics_frame
	await physics_frame
	_check(not manager.is_position_allowed(Vector2(4490, 3270), habitats[0]), "Solid prop blocks spawn")
	_check(not manager.is_position_allowed(Vector2(3200, 3200), habitats[0]), "Load and wander probes reject player spawn")
	# Isolate the wall sweep from the independently tested social separation rule.
	for index in manager.spawned.size():
		manager.spawned[index].set_physics_process(false)
		manager.spawned[index].position = Vector2(5000 + index * 60, 6000)
	friend.position = Vector2(4420, 3270)
	friend.set_physics_process(false)
	player.position = Vector2(4410, 3300)
	for i in 120:
		friend.move_toward_point(Vector2(4550, 3270), 1.0 / 30.0)
	_check(friend.position.x <= 4466.1, "Movement cannot tunnel through solid props")
	_check(friend.position.x > 4420.0, "Movement actually advances before reaching a collider")
	player.position = Vector2(3200, 3200)
	var old_position: Vector2 = friend.position
	for i in 120:
		friend._physics_process(1.0 / 30.0)
	_check(friend.position.is_equal_approx(old_position), "Far creatures suspend navigation while idle remains animated")
	for slime in manager.spawned:
		slime.free()
	manager.free()
	manager = script.new()
	region.add_child(manager)
	manager.configure(region, player, Vector2(3200, 3200), habitats)
	await physics_frame
	manager.populate()
	var restored := false
	for slime in manager.spawned:
		if slime.persistent_id == friend_id:
			restored = slime.befriended
	_check(restored, "Re-entering region restores friendship without duplication")
	# An invalid habitat must not force a creature into the protected clearing.
	for slime in manager.spawned:
		slime.free()
	manager.free()
	manager = script.new()
	region.add_child(manager)
	var invalid: Array[Dictionary] = [{"id": "unsafe", "center": Vector2(3200, 3200), "radius": 100.0}]
	manager.configure(region, player, Vector2(3200, 3200), invalid)
	await physics_frame
	manager.populate()
	_check(manager.spawned.is_empty(), "Fully excluded habitat stays empty instead of using an unsafe fallback")
	manager.free()
	manager = script.new()
	region.add_child(manager)
	var crowded: Array[Dictionary] = [{"id": "crowded", "center": Vector2(4800, 3200), "radius": 500.0, "population": 25}]
	manager.configure(region, player, Vector2(3200, 3200), crowded)
	await physics_frame
	manager.populate()
	_check(manager.spawned.size() == 10, "Oversized habitat is constrained by the global population budget")
	var boundary: Dictionary = {"id": "edge", "center": Vector2(4200, 3200), "radius": 400.0}
	_check(not manager.is_position_allowed(Vector2(4140, 3200), boundary), "Habitat overlap never admits a point inside clearing exclusion")
	_check(not manager.is_position_allowed(Vector2(4700, 3200), boundary), "Wander checks reject a point beyond habitat boundary")
	for slime in manager.spawned:
		slime.free()
	manager.free()
	manager = script.new()
	region.add_child(manager)
	player.position = Vector2(4800, 3200)
	var watched: Array[Dictionary] = [{"id": "watched", "center": Vector2(4800, 3200), "radius": 150.0}]
	manager.configure(region, player, Vector2(3200, 3200), watched)
	await physics_frame
	manager.populate()
	_check(manager.spawned.is_empty(), "Population never appears in the player's immediate view")
	region.free()
	_finish()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _finish() -> void:
	print("FOREST_HABITATS: %d checks; %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)

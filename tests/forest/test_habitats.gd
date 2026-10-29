extends GdUnitTestSuite
## Real habitat nodes in an isolated physics world, independent of map construction.
const HABITATS := preload("res://scripts/world/forest_habitats.gd")
const SPAWN := Vector2(3200, 3200)
var _region: Node2D
var _player: CharacterBody2D
var _manager: Node2D
var _old_friends: Dictionary

func before_test() -> void:
	_old_friends = get_tree().get_meta("forest_slime_friends", {}).duplicate(true)
	get_tree().set_meta("forest_slime_friends", {})
	_region = Node2D.new()
	add_child(_region)
	_player = CharacterBody2D.new()
	_region.add_child(_player)
	_player.position = SPAWN

func after_test() -> void:
	if is_instance_valid(_region):
		_region.free()
	get_tree().set_meta("forest_slime_friends", _old_friends)

func _four_habitats() -> Array[Dictionary]:
	return [
		{"id": "H01", "center": Vector2(4480, 3270), "radius": 220.0},
		{"id": "H02", "center": Vector2(1980, 2120), "radius": 220.0},
		{"id": "H03", "center": Vector2(3350, 4580), "radius": 220.0},
		{"id": "H04", "center": Vector2(4880, 1700), "radius": 220.0}]

func _populate(data: Array[Dictionary]) -> void:
	_manager = HABITATS.new()
	_region.add_child(_manager)
	_manager.configure(_region, _player, SPAWN, data)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	_manager.populate()
	for slime in _manager.spawned:
		slime.set_physics_process(false)

func test_four_habitats_have_unique_bounded_safe_populations() -> void:
	await _populate(_four_habitats())
	assert_int(_manager.spawned.size()).is_equal(8)
	var identities: Dictionary = {}
	var populations: Dictionary = {}
	for slime in _manager.spawned:
		assert_float(slime.position.distance_to(SPAWN)).is_greater_equal(960.0)
		assert_bool(identities.has(slime.persistent_id)).is_false()
		identities[slime.persistent_id] = true
		var habitat_id: String = slime.habitat.id
		populations[habitat_id] = int(populations.get(habitat_id, 0)) + 1
	assert_bool(identities.has("brotinho/H01/0")).is_true()
	assert_bool(identities.has("brotinho/H04/1")).is_true()
	for habitat_id in ["H01", "H02", "H03", "H04"]:
		assert_int(populations[habitat_id]).is_equal(2)
	for i in _manager.spawned.size():
		for j in range(i + 1, _manager.spawned.size()):
			assert_float(_manager.spawned[i].position.distance_to(_manager.spawned[j].position)).is_greater_equal(50.0)

func test_population_is_idempotent_and_respawn_waits_for_cooldown() -> void:
	await _populate(_four_habitats())
	for i in 25:
		_manager.populate()
	assert_int(_manager.spawned.size()).is_equal(8)
	var missing_id: String = _manager.spawned[0].persistent_id
	_manager.spawned[0].free()
	_manager.populate()
	assert_int(_manager.spawned.size()).is_equal(7)
	_manager._process(19.0)
	_manager.populate()
	assert_int(_manager.spawned.size()).is_equal(7)
	_manager._process(1.1)
	_manager.populate()
	assert_int(_manager.spawned.size()).is_equal(8)
	var matches := 0
	for slime in _manager.spawned:
		if slime.persistent_id == missing_id:
			matches += 1
	assert_int(matches).is_equal(1)

func test_global_cap_limits_oversized_habitat() -> void:
	var data: Array[Dictionary] = [{"id": "crowded", "center": Vector2(4800, 3200), "radius": 500.0, "population": 25}]
	await _populate(data)
	assert_int(_manager.spawned.size()).is_equal(10)
	_manager._process(40.0)
	_manager.populate()
	assert_int(_manager.spawned.size()).is_equal(10)

func test_exclusion_rejects_unsafe_spawn_and_wander_without_fallback() -> void:
	var data: Array[Dictionary] = [{"id": "unsafe", "center": SPAWN, "radius": 100.0}]
	await _populate(data)
	assert_int(_manager.spawned.size()).is_equal(0)
	_manager._process(60.0)
	_manager.populate()
	assert_int(_manager.spawned.size()).is_equal(0)
	var edge: Dictionary = {"id": "edge", "center": Vector2(4200, 3200), "radius": 400.0}
	assert_bool(_manager.is_position_allowed(Vector2(4140, 3200), edge)).is_false()
	assert_bool(_manager.is_position_allowed(Vector2(4700, 3200), edge)).is_false()

func test_friendship_survives_region_recreation_per_instance() -> void:
	await _populate(_four_habitats())
	var friend = _manager.spawned[0]
	var friend_id: String = friend.persistent_id
	assert_bool(friend.make_friend()).is_true()
	assert_bool(friend.make_friend()).is_false()
	assert_bool(get_tree().get_meta("forest_slime_friends", {}).get(friend_id, false)).is_true()
	for slime in _manager.spawned:
		slime.free()
	_manager.free()
	await _populate(_four_habitats())
	assert_int(_manager.spawned.size()).is_equal(8)
	var friends := 0
	for slime in _manager.spawned:
		if slime.befriended:
			friends += 1
			assert_str(slime.persistent_id).is_equal(friend_id)
	assert_int(friends).is_equal(1)

func test_physics_capsule_stops_movement_at_solid_prop() -> void:
	await _populate(_four_habitats())
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	wall.collision_mask = 0
	wall.position = Vector2(4490, 3270)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(24, 300)
	collision.shape = rectangle
	wall.add_child(collision)
	_region.add_child(wall)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var habitat: Dictionary = _four_habitats()[0]
	assert_bool(_manager.is_position_allowed(wall.position, habitat)).is_false()
	# Keep this movement assertion independent of the spacing assertion above.
	for index in _manager.spawned.size():
		_manager.spawned[index].position = Vector2(5000 + index * 60, 6000)
	var slime = _manager.spawned[0]
	slime.position = Vector2(4420, 3270)
	_player.position = Vector2(4410, 3300)
	for frame in 120:
		slime.move_toward_point(Vector2(4550, 3270), 1.0 / 30.0)
	assert_float(slime.position.x).is_greater(4420.0)
	assert_float(slime.position.x).is_less_equal(4466.1)
	_player.position = SPAWN
	var stopped: Vector2 = slime.position
	for frame in 120:
		slime._physics_process(1.0 / 30.0)
	assert_vector(slime.position).is_equal(stopped)

func test_population_does_not_appear_in_current_player_view() -> void:
	_player.position = Vector2(4800, 3200)
	var data: Array[Dictionary] = [{"id": "watched", "center": Vector2(4800, 3200), "radius": 150.0}]
	await _populate(data)
	assert_int(_manager.spawned.size()).is_equal(0)

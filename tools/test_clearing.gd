extends SceneTree
## Integration checks against the baked scene and Godot's real physics space.
const Layout = preload("res://scripts/world/clearing_layout.gd")
var checks := 0
var failures: Array[String] = []
var region: Node2D
var actor: CharacterBody2D
var samples := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	region = (load("res://scenes/world.tscn") as PackedScene).instantiate()
	root.add_child(region)
	current_scene = region
	actor = region.player
	await _settle()
	_check(actor.position.is_equal_approx(Vector2(1600, 1600)), "Spawn stays exactly central after physics frames")
	_check(region.get_node("Ground").get_used_cells().size() == 10000, "100 x 100 real ground tiles loaded")
	for name_ in ["Ground", "GroundDetails", "VegetationLow", "Obstacles"]:
		_check(region.get_node(name_) is TileMapLayer, name_ + " is an editable TileMapLayer")
	_check(region.y_sort_enabled and region.get_node("VegetationHigh").y_sort_enabled and region.get_node("Decorations").y_sort_enabled, "Feet-based sorting enabled across actors and props")
	var camera := actor.get_node("Camera2D") as Camera2D
	_check(camera.limit_left == 0 and camera.limit_top == 0 and camera.limit_right == 3200 and camera.limit_bottom == 3200, "Camera spans the new region, not the old prototype")
	_check(camera.position_smoothing_enabled, "Camera follows smoothly")
	var blocked_center := 0
	for y in range(-80, 81, 16):
		for x in range(-80, 81, 16):
			if _occupied(Layout.SPAWN + Vector2(x, y)):
				blocked_center += 1
	_check(blocked_center == 0, "Central 160 x 160 movement area is collision-free")
	var landmark: Node2D = region.get_node("AwakeningLandmark")
	_check(_occupied(landmark.global_position), "Ancestral spawn landmark has a solid base")
	var landmark_bank: Vector2 = landmark.get_node("Approach").global_position
	_check(not _occupied(landmark_bank), "Ancestral landmark has an open southern approach")
	var landmark_path := Curve2D.new()
	landmark_path.add_point(Layout.SPAWN)
	landmark_path.add_point(landmark_bank)
	_check(_clear_curve(landmark_path), "Spawn has a clear route to its visual landmark")
	_check(region.get_node("CanopyShade").get_child_count()>500, "Large trees cast ground shadows without new blockers")
	for label: String in Layout.trails():
		var path: Curve2D = Layout.trails()[label]
		_check(_clear_curve(path), "Player capsule can traverse " + label + " continuously")
	for slime: Node2D in region.slimes:
		var path := Curve2D.new()
		path.add_point(Layout.SPAWN)
		path.add_point(slime.position + Vector2(0, 24))
		_check(_clear_curve(path), "Physical route to " + slime.display_name())
	var tree_hits := 0
	var tree_colliders := 0
	var centre_trees := 0
	var blurry_trees := 0
	for tree: Node2D in region.get_node("VegetationHigh").get_children():
		if Layout.inside_clearing(tree.position):
			centre_trees += 1
		if tree.get_node("Sprite").texture.resource_path.ends_with("pine_wide.png"):
			blurry_trees += 1
		if tree.has_node("SolidBase"):
			tree_colliders += 1
			if _occupied(tree.position):
				tree_hits += 1
	_check(centre_trees == 0, "No trees placed inside the central clearing")
	_check(blurry_trees == 0, "Illustrated blurred pines replaced throughout the map")
	_check(tree_colliders > 900 and tree_colliders == tree_hits, "All %d tree bases block the player capsule" % tree_colliders)
	var solids_checked := 0
	var solids_working := 0
	for prop: Node2D in region.get_node("Decorations").get_children():
		if prop.has_node("SolidBase"):
			solids_checked += 1
			if _occupied(prop.position):
				solids_working += 1
	_check(solids_checked > 10 and solids_working == solids_checked, "Logs, stumps and mossy rocks have physical bases")
	var tile_rocks: TileMapLayer = region.get_node("Obstacles")
	var rock_hits := 0
	for cell in tile_rocks.get_used_cells():
		if _occupied(tile_rocks.map_to_local(cell) + Vector2(0, 10)):
			rock_hits += 1
	_check(rock_hits == tile_rocks.get_used_cells().size() and rock_hits > 0, "TileSet rock collision works on layer 2")
	for id in range(5, 9):
		_check(region.get_node("VegetationLow").tile_set.has_source(id), "Generated plant source %d is imported" % id)
	# Exercise input and the original animation controller, not only synthetic motion queries.
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		actor.position = Layout.SPAWN
		var action_x := "move_right" if direction.x > 0 else "move_left"
		var action_y := "move_down" if direction.y > 0 else "move_up"
		if direction.x != 0:
			Input.action_press(action_x)
		if direction.y != 0:
			Input.action_press(action_y)
		for frame in 8:
			await physics_frame
		var displacement := actor.position - Layout.SPAWN
		_check(displacement.length() > 5 and displacement.normalized().dot(direction.normalized()) > 0.99, "Movement works toward " + str(direction))
		Input.action_release(action_x)
		Input.action_release(action_y)
		await _settle()
	for exit_name in ["North", "East", "South"]:
		actor.position = region.get_node("Exits/" + exit_name).position
		await _settle()
		_check(region._visited_exits.has(exit_name), exit_name + " exit detects player without loading unfinished regions")
		_check(actor.position.distance_to(region.get_node("Exits/" + exit_name).position) < 1, "Old 1280 x 960 clamp does not affect " + exit_name)
	var spring := region.get_node("NaturalSpring")
	var bank: Vector2 = spring.get_node("InteractionPoint").global_position
	_check(not spring.has_node("RockSpring"), "Rejected rock formation and spout are removed")
	_check(not _occupied(spring.global_position+Vector2(-24,-60)), "Former rock formation leaves no invisible collision")
	_check(_occupied(spring.global_position), "Spring water blocks the player capsule")
	_check(not _occupied(bank), "Spring interaction bank is dry and accessible")
	var approach := Curve2D.new()
	approach.add_point(Layout.SPAWN)
	approach.add_point(bank)
	_check(_clear_curve(approach), "Spawn connects to the spring bank without obstacles")
	actor.position = bank
	await _settle()
	_check(region.hud_hint.text.contains("Examinar lago"), "Water interaction appears only near the bank")
	_check(actor.test_move(Transform2D(0,bank),spring.global_position-bank), "Physical sweep stops entry into the pool")
	Input.action_press("interact")
	await process_frame
	await process_frame
	Input.action_release("interact")
	_check(region.popup.text.contains("água cristalina"), "E examines the spring without inventing collected resources")
	_check(spring.is_in_group("water_sources"), "Source is identified for future water mechanics")
	actor.position = Layout.SPAWN
	await _settle()
	_check(not region.hud_hint.text.contains("Examinar lago"), "Water prompt clears after leaving the bank")
	actor.position = Vector2(-100, 3400)
	await _settle()
	_check(actor.position.x == 24 and actor.position.y == 3176, "Player stays within map bounds")
	print("CLEARING_INTEGRATION: %d checks, %d failures, %d capsule samples" % [checks, failures.size(), samples])
	quit(0 if failures.is_empty() else 1)

func _clear_curve(curve: Curve2D) -> bool:
	var previous := curve.sample_baked(0)
	var blocked: Array[Vector2] = []
	var length := curve.get_baked_length()
	var count := int(ceil(length / 10.0))
	for i in count + 1:
		var at := curve.sample_baked(minf(length, i * 10.0))
		if actor.world_bounds.has_point(at):
			if _occupied(at) or actor.test_move(Transform2D(0, previous), at - previous):
				blocked.append(at)
		previous = at
	if not blocked.is_empty():
		print("BLOCKED positions ", blocked.slice(0, 5))
	return blocked.is_empty()

func _occupied(at: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape: CollisionShape2D = actor.get_node("CollisionShape2D")
	query.shape = shape.shape
	query.transform = Transform2D(0, at + shape.position)
	query.collision_mask = 2
	query.collide_with_areas = false
	query.exclude = [actor.get_rid()]
	samples += 1
	return not actor.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _settle() -> void:
	for i in 4:
		await physics_frame

func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

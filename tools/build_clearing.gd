extends SceneTree
## Explicit editor-map bake. This overwrites ONLY the generated region and its TileSet.
## Run after importing textures: godot --headless --path . --script res://tools/build_clearing.gd
const Layout = preload("res://scripts/world/clearing_layout.gd")
const ENV := "res://assets/menu/environment/"
const FOREST := "res://assets/world/forest/"
const GROUND_TEXTURE := "res://assets/tilesets/grass_dirt_v3_32x32.png"
const TREE_TEXTURES := [ENV + "oak.png", ENV + "oak_medium.png", FOREST + "pine_crisp.png", FOREST + "oak_young.png"]
const LOW_TEXTURES := [ENV + "grass.png", ENV + "flowers.png", ENV + "crops.png"]
const BUSH := "res://assets/sprites/objects/bush_small_compact_leafy_for/rotations/bush_small_compact_leafy_for.png"
const LOG := "res://assets/sprites/objects/fallen_log_mossy_fallen_oak/rotations/fallen_log_mossy_fallen_oak.png"
var region: Node2D
var rng := RandomNumberGenerator.new()
var paths: Dictionary
var tiles: TileSet
var ground: TileMapLayer
var details: TileMapLayer
var low: TileMapLayer
var obstacles: TileMapLayer
var high: Node2D
var decorations: Node2D
var _used_rects: Dictionary = {}
var _textures: Dictionary = {}
var _buckets: Dictionary = {}
var _tree_count := 0
var _prop_count := 0
var _special_sources: Array[int] = []

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	rng.seed = Layout.SEED
	paths = Layout.trails()
	region = Node2D.new()
	region.name = "ClareiraDoDespertar"
	region.y_sort_enabled = true
	region.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	region.set_script(load("res://scripts/world/clearing_region.gd"))
	tiles = _make_tileset()
	ground = _layer("Ground", -20)
	details = _layer("GroundDetails", -16)
	low = _layer("VegetationLow", -5)
	obstacles = _layer("Obstacles", 0)
	obstacles.y_sort_enabled = true
	ground.modulate = Color(0.88, 1.11, 0.92)
	high = _group("VegetationHigh")
	high.y_sort_enabled = true
	decorations = _group("Decorations")
	decorations.y_sort_enabled = true
	_fill_ground()
	_make_paths()
	_plant_forest()
	_scatter_ground_cover()
	_place_landmarks()
	_make_spawns_and_exits()
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.position = Layout.SPAWN
	player.world_bounds = Rect2(24, 44, 3152, 3132)
	_add(region, player)
	var ambience := Node2D.new()
	ambience.name = "ForestAmbience"
	ambience.z_index = 5
	ambience.set_script(load("res://scripts/world/forest_ambience.gd"))
	_add(region, ambience)
	preload("res://scripts/world/clearing_polish.gd").new().apply(region)
	preload("res://scripts/world/spring_builder.gd").new().apply(region)
	preload("res://scripts/world/composition_refinement.gd").new().apply(region)
	preload("res://scripts/world/rock_clarity.gd").new().apply(region)
	ResourceSaver.save(tiles, "res://assets/world/clearing_tileset.tres")
	var scene := PackedScene.new()
	var error := scene.pack(region)
	if error == OK:
		error = ResourceSaver.save(scene, "res://scenes/regions/ClareiraDoDespertar.tscn")
	print("CLEARING BAKE trees=", _tree_count, " props=", _prop_count, " ground=", ground.get_used_cells().size(), " low=", low.get_used_cells().size(), " rock_tiles=", obstacles.get_used_cells().size(), " result=", error)
	region.free()
	quit(error)

func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = region

func _group(label: String) -> Node2D:
	var group := Node2D.new()
	group.name = label
	_add(region, group)
	return group

func _layer(label: String, depth: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = label
	layer.tile_set = tiles
	layer.z_index = depth
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_add(region, layer)
	return layer

func _make_tileset() -> TileSet:
	var result := TileSet.new()
	result.tile_size = Vector2i(32, 32)
	result.add_physics_layer()
	result.set_physics_layer_collision_layer(0, 2)
	result.set_physics_layer_collision_mask(0, 1)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(GROUND_TEXTURE)
	atlas.texture_region_size = Vector2i(32, 32)
	for coordinate in [Vector2i(0, 0), Vector2i(7, 1), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)]:
		atlas.create_tile(coordinate)
	result.add_source(atlas, 0)
	var index := 1
	for path in LOW_TEXTURES:
		var source := _single_tile(path)
		result.add_source(source, index)
		if index == 2:
			for tint in [Color(1.12, 1.03, 0.69), Color(0.65, 0.85, 1.4)]:
				var alt := source.create_alternative_tile(Vector2i.ZERO)
				source.get_tile_data(Vector2i.ZERO, alt).modulate = tint
		index += 1
	var rock := _single_tile(ENV + "stone.png")
	result.add_source(rock, 4)
	var data := rock.get_tile_data(Vector2i.ZERO, 0)
	data.y_sort_origin = 10
	data.set_collision_polygons_count(0, 1)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-13, 0), Vector2(10, 0), Vector2(15, 7), Vector2(8, 12), Vector2(-11, 12), Vector2(-16, 7)]))
	index = 5
	for file in ["mushroom_red.png", "mushroom_brown.png", "mushroom_glow.png", "fern.png"]:
		if ResourceLoader.exists(FOREST + file):
			result.add_source(_single_tile(FOREST + file), index)
			_special_sources.append(index)
		index += 1
	return result

func _single_tile(path: String) -> TileSetAtlasSource:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(path)
	atlas.texture_region_size = atlas.texture.get_size()
	atlas.create_tile(Vector2i.ZERO)
	return atlas

func _fill_ground() -> void:
	for y in 100:
		for x in 100:
			var flip := TileSetAtlasSource.TRANSFORM_FLIP_H if rng.randf() < 0.5 else 0
			if rng.randf() < 0.5:
				flip |= TileSetAtlasSource.TRANSFORM_FLIP_V
			ground.set_cell(Vector2i(x, y), 0, Vector2i.ZERO, flip)
	var undergrowth := _group("ForestFloor")
	undergrowth.z_index = -19
	# Large coherent moss patches break the floor repetition beneath tree groups.
	for i in 95:
		var at := Vector2(rng.randf_range(0, 3200), rng.randf_range(0, 3200))
		if Layout.reserved(at, paths, 95):
			continue
		_surface(undergrowth, _blob(at, Vector2(rng.randf_range(90, 220), rng.randf_range(65, 150)), i), Color("728d45"), Vector2.ZERO, 0.48)
	var clearing := PackedVector2Array()
	for i in 96:
		var angle := TAU * i / 96.0
		clearing.append((Layout.SPAWN + Vector2.from_angle(angle) * Layout.clearing_radius(angle)).round())
	_surface(undergrowth, clearing, Color("a3bd62"), Vector2.ZERO, 0.37)
	for i in Layout.POCKETS.size():
		_surface(undergrowth, _blob(Layout.POCKETS[i], Vector2(130, 110), i), Color("9bac61"), Vector2.ZERO, 0.45)

func _make_paths() -> void:
	var paths_group := _group("NaturalTrails")
	paths_group.z_index = -17
	for label: String in paths:
		var curve: Curve2D = paths[label]
		var is_main := label in ["North", "East", "South"]
		var begin := 190.0 if is_main else 0.0
		var width := 38.0 if is_main else 26.0
		_surface(paths_group, _ribbon(curve, width + 10.0, begin), Color("a6a05c"), Vector2.ZERO, 0.25).name = label + "GrassEdge"
		_surface(paths_group, _ribbon(curve, width, begin), Color("b5a36a"), Vector2(224, 32), 0.4).name = label + "Dirt"
	# Light, worn patches in the clearing leave a recognisable grassy spawn centre.
	for data in [[Vector2(1445, 1590), Vector2(52, 25)], [Vector2(1670, 1770), Vector2(42, 19)], [Vector2(1750, 1420), Vector2(35, 20)]]:
		_surface(paths_group, _blob(data[0], data[1], 1), Color("aaa368"), Vector2(224, 32), 0.35)

func _blob(at: Vector2, radius: Vector2, phase: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for i in 32:
		var angle := TAU * i / 32.0
		var irregular := 1.0 + sin(angle * 5 + phase) * 0.1 + cos(angle * 3 + phase) * 0.07
		polygon.append((at + Vector2.from_angle(angle) * radius * irregular).round())
	return polygon

func _ribbon(curve: Curve2D, width: float, begin: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var length := curve.get_baked_length()
	var count := int((length - begin) / 10.0) + 1
	for i in count + 1:
		var offset := lerpf(begin, length, float(i) / count)
		var at := curve.sample_baked(offset)
		var tangent := (curve.sample_baked(minf(length, offset + 4)) - curve.sample_baked(maxf(0, offset - 4))).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var half_width := width * (1 + sin(offset * 0.018) * 0.11 + cos(offset * 0.047) * 0.045)
		if begin > 0:
			half_width *= lerpf(0.18, 1.0, clampf((offset - begin) / 90.0, 0, 1))
		left.append((at + normal * half_width).round())
		right.append((at - normal * half_width).round())
	right.reverse()
	left.append_array(right)
	return left

func _surface(parent: Node, polygon: PackedVector2Array, color: Color, origin: Vector2, strength: float) -> Polygon2D:
	var surface := Polygon2D.new()
	surface.polygon = polygon
	surface.color = color
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/menu/terrain_surface.gdshader")
	mat.set_shader_parameter("terrain_atlas", load(GROUND_TEXTURE))
	mat.set_shader_parameter("atlas_origin", origin)
	mat.set_shader_parameter("texture_strength", strength)
	surface.material = mat
	_add(parent, surface)
	return surface

func _plant_forest() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = Layout.SEED
	noise.frequency = 0.004
	for attempt in 17000:
		var at := Vector2(rng.randf_range(18, 3182), rng.randf_range(35, 3190)).round()
		# Reserve the canopy footprint, not only the trunk, around visible routes.
		if Layout.reserved(at, paths, 32) or Layout.reserved(at - Vector2(0, 95), paths, 13):
			continue
		if _near_tree(at, 62.0):
			continue
		var distance := at.distance_to(Layout.SPAWN)
		var density := remap(noise.get_noise_2dv(at), -0.6, 0.6, 0.3, 0.9)
		if distance < 600:
			density *= 0.6
		if rng.randf() > density:
			continue
		var species := rng.randi_range(0, TREE_TEXTURES.size() - 1)
		var scale_value := 2.0
		if rng.randf() < 0.22:
			scale_value = 1.0
		var prop := _prop(high, TREE_TEXTURES[species], at, scale_value, "Tree", Vector2(17, 10) if scale_value == 2 else Vector2(10, 7))
		prop.set_meta("tree", true)
		var sprite := prop.get_node("Sprite") as Sprite2D
		sprite.modulate = [Color.WHITE, Color(0.92, 1.03, 0.86), Color(0.83, 0.96, 0.90), Color(1.05, 1.03, 0.85)][rng.randi_range(0, 3)]
		var bucket := Vector2i(at / 64)
		if not _buckets.has(bucket):
			_buckets[bucket] = []
		_buckets[bucket].append(at)
		_tree_count += 1

func _near_tree(at: Vector2, distance: float) -> bool:
	var cell := Vector2i(at / 64)
	for y in range(-2, 3):
		for x in range(-2, 3):
			for other: Vector2 in _buckets.get(cell + Vector2i(x, y), []):
				if other.distance_to(at) < distance:
					return true
	return false

func _scatter_ground_cover() -> void:
	for i in 4000:
		var cell := Vector2i(rng.randi_range(1, 98), rng.randi_range(1, 98))
		var at := Vector2(cell * 32) + Vector2(16, 16)
		var trail_dist := Layout.trail_distance(at, paths)
		if at.distance_to(Layout.SPAWN) < 65 or trail_dist < 29:
			continue
		var beside_slime := false
		for slime_position in Layout.SLIME_POSITIONS:
			if at.distance_to(slime_position) < 38:
				beside_slime = true
		if beside_slime:
			continue
		var source := 1
		if rng.randf() < 0.24:
			source = 2
		elif rng.randf() < 0.15:
			source = 3
		var alt := rng.randi_range(0, 2) if source == 2 else 0
		low.set_cell(cell, source, Vector2i.ZERO, alt)
		if not _special_sources.is_empty() and rng.randf() < 0.14 and not Layout.inside_clearing(at, -100):
			low.set_cell(cell, _special_sources[rng.randi_range(0, _special_sources.size() - 1)], Vector2i.ZERO)
	for i in 2100:
		var cell := Vector2i(rng.randi_range(0, 99), rng.randi_range(0, 99))
		details.set_cell(cell, 0, Vector2i(rng.randi_range(0, 2), 3))
	for i in 280:
		var at := Vector2(rng.randf_range(45, 3155), rng.randf_range(45, 3155)).round()
		if Layout.trail_distance(at, paths) < 78 or at.distance_to(Layout.SPAWN) < 160:
			continue
		if i % 4 == 0 and not Layout.inside_clearing(at, 45):
			var cell := Vector2i(at / 32)
			obstacles.set_cell(cell, 4, Vector2i.ZERO)
			continue
		if _near_tree(at, 26):
			continue
		_prop(decorations, BUSH, at, 1, "Underbrush", Vector2.ZERO)
	# Small solid landmarks in woodland, never in the trail corridor or spawn.
	for i in 85:
		var at := Vector2(rng.randf_range(80, 3120), rng.randf_range(100, 3100)).round()
		if Layout.reserved(at, paths, 46) or _near_tree(at, 48):
			continue
		var textures := [LOG, ENV + "stump.png", FOREST + "mossy_rock.png", FOREST + "mossy_rock_tall.png"]
		var index := i % textures.size()
		_prop(decorations, textures[index], at, 1, ["FallenLog", "Stump", "MossyRock", "AncientRock"][index], Vector2(34, 12) if index == 0 else Vector2(22, 12))

func _place_landmarks() -> void:
	# Hand-authored accents create distinct groves and frame the three entrances.
	for data in [[Vector2(1280, 1460), LOG, "FallenLog", Vector2(35, 12)], [Vector2(1895, 1400), FOREST + "mossy_rock_tall.png", "MossyRock", Vector2(22, 13)], [Vector2(1740, 1910), ENV + "stump.png", "Stump", Vector2(24, 12)], [Vector2(850, 1150), FOREST + "mossy_rock.png", "MossyRock", Vector2(20, 10)], [Vector2(2390, 1100), LOG, "FallenLog", Vector2(35, 12)], [Vector2(2240, 2520), FOREST + "mossy_rock_tall.png", "MossyRock", Vector2(22, 13)]]:
		_prop(decorations, data[1], data[0], 1, data[2], data[3])
	for at in [Vector2(1320, 1540), Vector2(1380, 1340), Vector2(1770, 1350), Vector2(1850, 1730), Vector2(1660, 1855), Vector2(1360, 1760)]:
		_prop(decorations, BUSH, at, 1, "ClearingShrub", Vector2.ZERO)
		for j in 4:
			var cell := Vector2i((at + Vector2(rng.randf_range(-50, 50), rng.randf_range(15, 55))) / 32)
			low.set_cell(cell, 2, Vector2i.ZERO, j % 3)

func _prop(parent: Node, path: String, at: Vector2, size_scale: float, label: String, collider: Vector2) -> Node2D:
	if not _textures.has(path):
		_textures[path] = load(path)
		_used_rects[path] = (_textures[path] as Texture2D).get_image().get_used_rect()
	var texture: Texture2D = _textures[path]
	var used: Rect2i = _used_rects[path]
	var prop := Node2D.new()
	prop.name = label + "_%04d" % _prop_count
	prop.position = at
	_add(parent, prop)
	_prop_count += 1
	var shadow := Polygon2D.new()
	shadow.name = "ContactShadow"
	shadow.z_index = -1
	shadow.color = Color(0.08, 0.18, 0.10, 0.22)
	var radius := Vector2(maxf(10.0, used.size.x * size_scale * 0.26), maxf(4, used.size.x * size_scale * 0.07))
	shadow.polygon = _blob(Vector2(0, -2), radius, 0)
	_add(prop, shadow)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = texture
	sprite.centered = false
	sprite.position = -Vector2(used.position.x + used.size.x * 0.5, used.end.y - 2) * size_scale
	sprite.scale = Vector2.ONE * size_scale
	sprite.flip_h = rng.randf() < 0.5
	# A centred quad keeps feet stable when mirrored, including asymmetric alpha padding.
	if sprite.flip_h:
		sprite.position.x = -(texture.get_width() - used.position.x - used.size.x * 0.5) * size_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_add(prop, sprite)
	if collider != Vector2.ZERO:
		var body := StaticBody2D.new()
		body.name = "SolidBase"
		body.collision_layer = 2
		body.collision_mask = 1
		_add(prop, body)
		var shape := CollisionPolygon2D.new()
		shape.name = "TrunkCollision" if label == "Tree" else "BaseCollision"
		shape.polygon = PackedVector2Array([Vector2(-collider.x, -collider.y), Vector2(-collider.x * 0.7, -collider.y * 2), Vector2(collider.x * 0.7, -collider.y * 2), Vector2(collider.x, -collider.y), Vector2(collider.x * 0.7, 0), Vector2(-collider.x * 0.7, 0)])
		_add(body, shape)
	return prop

func _make_spawns_and_exits() -> void:
	var spawns := _group("SpawnPoints")
	var spawn := Marker2D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Layout.SPAWN
	_add(spawns, spawn)
	for i in Layout.SLIME_POSITIONS.size():
		var marker := Marker2D.new()
		marker.name = ["GelitoSpawn", "BrotinhoSpawn", "BrasinhaSpawn"][i]
		marker.position = Layout.SLIME_POSITIONS[i]
		_add(spawns, marker)
	var exits := _group("Exits")
	for entry in [["North", Vector2(1660, 76)], ["East", Vector2(3120, 1575)], ["South", Vector2(1610, 3120)]]:
		var area := Area2D.new()
		area.name = entry[0]
		area.position = entry[1]
		area.collision_layer = 0
		area.collision_mask = 1
		_add(exits, area)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(160, 110) if entry[0] != "East" else Vector2(110, 160)
		shape.shape = rectangle
		_add(area, shape)
		var marker := Marker2D.new()
		marker.name = entry[0] + "Exit"
		marker.position = entry[1]
		_add(spawns, marker)

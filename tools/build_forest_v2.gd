extends "res://tools/build_clearing.gd"
## Expand a snapshot of the effective edited scene; never rewrite the source map.
const Forest = preload("res://scripts/world/forest_layout.gd")
var flower_points: Array[Vector2] = []
var moved_core_props := 0
var extra_trees: Node2D
var extra_plants: Node2D
var pois: Node2D

func _build() -> void:
	rng.seed = Forest.SEED
	region = load("res://scenes/world.tscn").instantiate()
	region.scene_file_path = ""
	region.name = "FlorestaDoDespertarV2"
	region.set_script(load("res://scripts/world/forest_region.gd"))
	_own(region)
	paths = Forest.trails()
	for child in region.get_children():
		if child is TileMapLayer:
			var cells: Array[Vector3i] = []
			var alts: Array[int] = []
			var sources: Array[int] = []
			for cell: Vector2i in child.get_used_cells():
				var atlas: Vector2i = child.get_cell_atlas_coords(cell)
				cells.append(Vector3i(cell.x,cell.y,alts.size()))
				alts.append(child.get_cell_alternative_tile(cell))
				sources.append(child.get_cell_source_id(cell))
				# Retain each exact atlas coordinate; painted overrides are not regenerated.
				child.set_meta("atlas_%s" % (alts.size()-1),atlas)
			child.clear()
			for cell in cells:
				child.set_cell(Vector2i(cell.x+50,cell.y+50),sources[cell.z],child.get_meta("atlas_%s"%cell.z),alts[cell.z])
				child.remove_meta("atlas_%s"%cell.z)
		elif child is Node2D:
			child.position += Forest.OFFSET
	var old_ambience := region.get_node_or_null("ForestAmbience")
	if old_ambience: old_ambience.free()
	# Slightly widen safe walking space while retaining the familiar pond/stone composition.
	region.get_node("NaturalSpring").position += Vector2(120,-40)
	region.get_node("AwakeningLandmark").position += Vector2(-60,-20)
	ground = region.get_node("Ground")
	low = region.get_node("VegetationLow")
	details = region.get_node("GroundDetails")
	obstacles = region.get_node("Obstacles")
	tiles = ground.tile_set
	for y in 200:
		for x in 200:
			if ground.get_cell_source_id(Vector2i(x,y)) < 0:
				ground.set_cell(Vector2i(x,y),0,Vector2i.ZERO,TileSetAtlasSource.TRANSFORM_FLIP_H if (x+y)%2 else 0)
	var spawns := region.get_node("SpawnPoints")
	for child in spawns.get_children():
		if child.name != "PlayerSpawn": child.free()
	var arrival := Marker2D.new()
	arrival.name = "ArrivalFromSouth"
	arrival.position = Forest.SOUTH_ARRIVAL-spawns.position
	_add(spawns,arrival)
	for exit_node in region.get_node("Exits").get_children():
		exit_node.position = {"North":Vector2(3270,120),"East":Vector2(6280,3150),"South":Forest.SOUTH_EXIT}[str(exit_node.name)]-region.get_node("Exits").position
	var exclusion := Area2D.new()
	exclusion.name = "NoSlimeSpawnArea"
	exclusion.position = Forest.SPAWN
	exclusion.collision_layer = 0
	exclusion.collision_mask = 0
	exclusion.monitoring = false
	_add(region,exclusion)
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = CircleShape2D.new()
	shape.shape.radius = Forest.EXCLUSION
	_add(exclusion,shape)
	extra_trees = _group("ExpandedForest")
	extra_trees.y_sort_enabled = true
	extra_plants = _group("FlowerClusters")
	extra_plants.z_index = -3
	pois = _group("PointsOfInterest")
	_terrain_and_paths()
	_clear_new_corridors()
	_woods()
	_botany()
	_micro_places()
	_make_habitats()
	_southern_water()
	_northern_rocks()
	_boundary()
	region.set_meta("forest_v2",true)
	region.set_meta("core_offset",Forest.OFFSET)
	region.set_meta("flower_points",PackedVector2Array(flower_points))
	region.set_meta("water_points",PackedVector2Array([Vector2(3505,3025),Vector2(3460,5630)]))
	region.set_meta("relocated_core_props",moved_core_props)
	var packed := PackedScene.new()
	var result := packed.pack(region)
	if result == OK: result = ResourceSaver.save(packed,"res://scenes/regions/FlorestaDoDespertarV2.tscn")
	print("FOREST BAKE cells=",ground.get_used_cells().size()," extra_trees=",extra_trees.get_child_count()," flowers=",flower_points.size()," relocated=",moved_core_props," result=",result)
	region.free()
	quit(result)

func _own(node: Node) -> void:
	for child in node.get_children():
		child.owner = region
		# Keep PackedScene ownership inside player/other reusable scene instances.
		# Flattening those children creates duplicate inherited nodes on load.
		if child.scene_file_path.is_empty(): _own(child)

func _reserved(at: Vector2, margin: float=0) -> bool:
	return Forest.open_area(at,margin) or Layout.trail_distance(at,paths) < 80+margin

func _terrain_and_paths() -> void:
	var surfaces := _group("ExpandedFloor")
	surfaces.z_index = -19
	for i in 260:
		var at := Vector2(rng.randf_range(100,6300),rng.randf_range(100,6300))
		if Forest.CORE.has_point(at): continue
		_surface(surfaces,_blob(at,Vector2(rng.randf_range(100,230),rng.randf_range(70,150)),i),Color("6c894a"),Vector2.ZERO,0.42)
	for p in Forest.points_of_interest():
		_surface(surfaces,_blob(p.at,Vector2(200,150),rng.randf()*TAU),Color("9bb65b"),Vector2.ZERO,0.38)
	var trails_group := _group("ExpandedTrails")
	trails_group.z_index = -17
	for label in paths:
		if label in Layout.trails(): continue
		_surface(trails_group,_ribbon(paths[label],50,0),Color("a39e5a"),Vector2.ZERO,0.3).name = label+"Edge"
		_surface(trails_group,_ribbon(paths[label],39,0),Color("b5a36a"),Vector2(224,32),0.4).name = label+"Path"

func _clear_new_corridors() -> void:
	# Relocate only obstructing props in the COPY. All original source scenes stay byte-identical.
	for group_name in ["VegetationHigh","Decorations"]:
		var group: Node2D = region.get_node(group_name)
		for prop: Node2D in group.get_children():
			var at := group.position+prop.position
			if not _reserved(at,30): continue
			if at.distance_to(Forest.SPAWN) < 500: continue
			if not prop.has_node("SolidBase"): continue
			var placed := false
			for attempt in 200:
				var candidate := at+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(180,480)
				if _reserved(candidate,55) or candidate.x<200 or candidate.y<200 or candidate.x>6200 or candidate.y>6200: continue
				prop.position = candidate.round()-group.position
				if group_name == "VegetationHigh":
					for shadow in region.get_node("CanopyShade").get_children():
						if shadow.position.distance_to(at-Forest.OFFSET+Vector2(12,0))<1:
							shadow.position += candidate.round()-at
							break
				moved_core_props += 1
				placed = true
				break
			if not placed: push_warning("Unmoved corridor prop: "+str(prop.name))
	for cell in obstacles.get_used_cells():
		if _reserved(obstacles.map_to_local(cell),25) and obstacles.map_to_local(cell).distance_to(Forest.SPAWN)>500:
			obstacles.erase_cell(cell)
	# New trees own feet-aligned contact shadows.

func _woods() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = Forest.SEED
	noise.frequency = 0.0022
	for attempt in 43000:
		var at := Vector2(rng.randf_range(24,6376),rng.randf_range(50,6376)).round()
		if Forest.CORE.has_point(at): continue
		if _reserved(at,35) or _reserved(at-Vector2(0,80),8) or _near_tree(at,71): continue
		var density := remap(noise.get_noise_2dv(at),-0.7,0.7,0.25,0.95)
		if minf(minf(at.x,6400-at.x),minf(at.y,6400-at.y)) < 260: density = 1
		if rng.randf()>density: continue
		var species := rng.randi_range(0,3)
		if at.y<2400 and rng.randf()<0.5: species=2
		var size_scale := 1.0 if rng.randf()<0.16 else 2.0
		var prop := _prop(extra_trees,TREE_TEXTURES[species],at,size_scale,"ForestTree",Vector2(17,10) if size_scale==2 else Vector2(10,7))
		prop.set_meta("tree",true)
		prop.get_node("Sprite").modulate = [Color.WHITE,Color(0.92,1.03,0.86),Color(0.83,0.96,0.90)][rng.randi_range(0,2)]
		var bucket := Vector2i(at/64)
		if not _buckets.has(bucket): _buckets[bucket] = []
		_buckets[bucket].append(at)

func _botany() -> void:
	for i in 9000:
		var cell := Vector2i(rng.randi_range(2,197),rng.randi_range(2,197))
		var at := Vector2(cell*32)+Vector2(16,16)
		if Forest.CORE.has_point(at) or Layout.trail_distance(at,paths)<34: continue
		var source: int = [1,1,1,8,5,6,3][rng.randi_range(0,6)]
		low.set_cell(cell,source,Vector2i.ZERO)
		if i%4==0: details.set_cell(cell,0,Vector2i(i%3,3))
	var colors := [Color(1,1,0.98),Color(1.15,1.04,0.63),Color(0.7,0.87,1.3),Color(1.2,0.82,1.06)]
	# Broken drifts beside paths, not a uniform grid of independent flowers.
	for label in paths:
		var curve: Curve2D = paths[label]
		for distance in range(230,int(curve.get_baked_length())-60,190):
			var center := curve.sample_baked(distance)
			var tangent := (curve.sample_baked(distance+10)-curve.sample_baked(distance-10)).normalized()
			center += Vector2(-tangent.y,tangent.x)*rng.randf_range(75,115)*(1 if rng.randf()<0.5 else -1)
			if center.distance_to(Forest.SPAWN)<180: continue
			_flower_cluster(center,colors[rng.randi_range(0,3)],rng.randi_range(3,6))
	for p in Forest.points_of_interest():
		for i in 8:
			var at: Vector2 = p.at+Vector2.from_angle(i*TAU/8)*Vector2(145,115)
			_flower_cluster(at,colors[i%4],5)
			_prop(extra_plants,FOREST+"fern.png",at+Vector2(-30,15),1,"Fern",Vector2.ZERO)
			_prop(extra_plants,BUSH,at+Vector2(25,-20),1,"Shrub",Vector2.ZERO)

func _flower_cluster(at: Vector2, tint: Color, count: int) -> void:
	flower_points.append(at)
	for i in count:
		var pos := at+Vector2(rng.randf_range(-32,32),rng.randf_range(-22,22))
		var prop := _prop(extra_plants,ENV+"flowers.png",pos.round(),1,"Wildflowers",Vector2.ZERO)
		prop.get_node("Sprite").modulate = tint

func _micro_places() -> void:
	for p in Forest.points_of_interest():
		var marker := Marker2D.new()
		marker.name = p.id
		marker.position = p.at
		marker.set_meta("title",p.name)
		marker.set_meta("description",p.description)
		_add(pois,marker)
	for i in 28:
		var at := Vector2(2100,2860)+Vector2.from_angle(rng.randf()*TAU)*Vector2(rng.randf_range(65,165),rng.randf_range(65,145))
		_prop(extra_plants,FOREST+["mushroom_red.png","mushroom_brown.png","mushroom_glow.png"][i%3],at,1,"MushroomGrove",Vector2.ZERO)
	var ancient := _prop(extra_trees,ENV+"oak.png",Vector2(2860,1800),2,"AncientOak",Vector2(24,14))
	ancient.set_meta("tree",true)
	for shift in [Vector2(-85,-40),Vector2(100,-40)]:
		_prop(extra_trees,ENV+"oak_medium.png",ancient.position+shift,2,"AncientCompanions",Vector2(17,10))
	_prop(extra_trees,LOG,Vector2(2770,3590),1,"TroncoDoTempo",Vector2(34,12))
	for i in 7:
		var at := Vector2(1980,2120)+Vector2.from_angle(i*TAU/7)*Vector2(125,100)
		_prop(extra_trees,ENV+"stone.png",at,1,"MossCircleStone",Vector2.ZERO)
	# Root lines lie on the ground, with a clear southern approach to the century tree.
	var roots := _group("AncientRoots")
	roots.z_index = -4
	for i in 5:
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(2860,1800),Vector2(2800+i*30,1822),Vector2(2770+i*45,1832)])
		line.width = 4
		line.default_color = Color("6c6942")
		_add(roots,line)

func _make_habitats() -> void:
	var group := _group("SlimeHabitats")
	for h in Forest.habitats():
		var marker := Marker2D.new()
		marker.name = h.id
		marker.position = h.center
		marker.set_meta("radius",h.radius)
		marker.set_meta("population",h.population)
		_add(group,marker)

func _southern_water() -> void:
	var group := _group("SouthernBrook")
	group.z_index = -12
	var shape := _blob(Vector2(3460,5630),Vector2(150,95),1.5)
	_surface(group,_blob(Vector2(3460,5630),Vector2(169,108),1.5),Color("9eaa70"),Vector2.ZERO,0.3)
	var water := Polygon2D.new()
	water.name = "Water"
	water.position = Vector2(3460,5630)
	water.polygon = _blob(Vector2.ZERO,Vector2(150,95),1.5)
	water.color = Color("479aab")
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/world/spring_water.gdshader")
	mat.set_shader_parameter("pool_radius",Vector2(150,95))
	water.material = mat
	_add(group,water)
	var body := StaticBody2D.new()
	body.name = "DeepWater"
	body.collision_layer = 2
	body.collision_mask = 1
	_add(group,body)
	var collider := CollisionPolygon2D.new()
	collider.polygon = shape
	_add(body,collider)
	# Water is composed after woodland: move only local trunks, preserving the rest of the bake.
	for tree in extra_trees.get_children():
		if not Geometry2D.is_point_in_polygon(tree.position,shape): continue
		var placed := false
		for i in 320:
			var ring := i/40
			var candidate := Vector2(3460,5630)+Vector2.from_angle(i*0.53)*Vector2(240+ring*45,180+ring*35)
			if not _reserved(candidate,30) and not _near_tree(candidate,50):
				tree.position = candidate.round()
				var bucket := Vector2i(candidate/64)
				if not _buckets.has(bucket): _buckets[bucket]=[]
				_buckets[bucket].append(candidate)
				placed = true
				break
		if not placed: push_error("No dry forest space for pond tree "+str(tree.name))
	for cell in low.get_used_cells():
		if Geometry2D.is_point_in_polygon(low.map_to_local(cell),shape): low.erase_cell(cell)
	for plant in extra_plants.get_children():
		if Geometry2D.is_point_in_polygon(plant.position,shape): plant.free()
	for i in range(flower_points.size()-1,-1,-1):
		if Geometry2D.is_point_in_polygon(flower_points[i],shape): flower_points.remove_at(i)
	for i in 9:
		var at := Vector2(3460,5630)+Vector2.from_angle(i*TAU/9)*Vector2(177,118)
		_prop(extra_plants,"res://assets/world/valley/reeds.png",at,1,"WetReeds",Vector2.ZERO)
	for i in 4:
		_prop(extra_plants,"res://assets/world/valley/lily_pad.png",Vector2(3390+i*40,5620+(i%2)*30),1,"FloatingLily",Vector2.ZERO)

func _northern_rocks() -> void:
	# Short ledges face down; the southern centre is a real unobstructed stair passage.
	var ledges := _group("NorthernLedges")
	ledges.z_index = -14
	var wall := TileMapLayer.new()
	wall.name = "LowCliffs"
	wall.tile_set = load("res://assets/world/valley/cliffs_low.tres")
	wall.scale = Vector2(2,2)
	_add(ledges,wall)
	var cliff_material := ShaderMaterial.new()
	cliff_material.shader = load("res://scripts/world/valley_cliffs.gdshader")
	wall.material = cliff_material
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/valley/cliffs_low.json"))
	var aperture := Rect2(5050,1320,120,240)
	var aperture_polygon := _box(aperture)
	for y in range(16,24):
		for x in range(75,85):
			var cell := Vector2i(x,y)
			var values := [_hill(cell),_hill(cell+Vector2i.RIGHT),_hill(cell+Vector2i.DOWN),_hill(cell+Vector2i.ONE)]
			if values == [0,0,0,0]: continue
			var coord := _hill_tile(info.tileset_data.tiles,cell)
			if coord.x < 0:
				push_error("Missing hill terrain pattern: "+str(cell))
				continue
			wall.set_cell(cell,0,coord)
			if values != [1,1,1,1]:
				for polygon in Geometry2D.clip_polygons(_box(Rect2(Vector2(cell)*64,Vector2(64,64))),aperture_polygon):
					var body := StaticBody2D.new()
					body.collision_layer = 2
					_add(ledges,body)
					var shape := CollisionPolygon2D.new()
					shape.polygon = polygon
					_add(body,shape)
	for at in [Vector2(4900,1430),Vector2(5270,1430)]:
		_prop(extra_trees,ENV+"stone.png",at,2,"LookoutShoulder",Vector2(22,13))
	_prop(extra_plants,"res://assets/world/valley/stone_steps.png",Vector2(5110,1480),2,"LookoutSteps",Vector2.ZERO)

func _hill(cell: Vector2i) -> int:
	return 1 if ((Vector2(cell)*64-Vector2(5110,1240))/Vector2(235,155)).length()<1.0 else 0

func _hill_tile(entries: Array, cell: Vector2i) -> Vector2i:
	var best := -1
	var found := Vector2i(-1,-1)
	for tile: Dictionary in entries:
		var valid := true
		var specificity := 0
		for row in 4:
			var pattern: Array = tile.pattern_4x4["row_"+str(row)]
			for col in 4:
				if int(pattern[col]) == 255: continue
				if int(pattern[col]) != _hill(cell+Vector2i(col-1,row-1)): valid=false
				specificity += 1
		if valid and specificity>best:
			best = specificity
			found = Vector2i(int(tile.bounding_box.x)/32,int(tile.bounding_box.y)/32)
	return found

func _box(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

func _boundary() -> void:
	var group := _group("ForestBoundary")
	for rect in [Rect2(-32,-32,6464,32),Rect2(-32,6400,6464,32),Rect2(-32,0,32,6400),Rect2(6400,0,32,6400)]:
		var body := StaticBody2D.new()
		body.collision_layer = 2
		_add(group,body)
		var collider := CollisionShape2D.new()
		collider.shape = RectangleShape2D.new()
		collider.shape.size = rect.size
		collider.position = rect.get_center()
		_add(body,collider)

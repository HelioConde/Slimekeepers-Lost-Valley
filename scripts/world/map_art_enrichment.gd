extends Node2D
## Curated PixelLab exports layered onto existing maps; original scenes/art stay intact.
const RULES = preload("res://scripts/world/visual_rules.gd")
const SURFACES = preload("res://scripts/world/region_surfaces.gd")
var region_kind := "forest"
var stats := {"replaced":0,"added":0,"solids":0,"clusters":0}
var _assets: Dictionary = {}
var _routes: Dictionary = {}
var _cliffs: Array[PackedVector2Array] = []
var _occupied: Array[Vector2] = []
var _canopies: Array[Dictionary] = []
var _canopy_images: Dictionary = {}
var _region: Node2D

func _ready() -> void:
	name = "MapArt"
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_region = get_parent()
	call_deferred("_populate")

func _populate() -> void:
	await get_tree().physics_frame
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/curated_exports/manifest.json"))
	for key in manifest:
		var texture: Texture2D = load(manifest[key].texture)
		_assets[key] = {"texture":texture,"used":texture.get_image().get_used_rect()}
	_routes = preload("res://scripts/world/forest_layout.gd").trails() if region_kind=="forest" else preload("res://scripts/world/valley_layout.gd").routes()
	_cliffs = SURFACES.cliff_faces(_region)
	_replace_repeated_props()
	# Wilderness: human traces are limited to old ruins; no maintained furniture or lamps.
	if region_kind=="forest":
		_cluster(Vector2(3000,3070),"flowers")
		_cluster(Vector2(3400,3330),"flowers")
		_cluster(Vector2(2000,2790),"mushrooms")
		_cluster(Vector2(2220,2940),"mushrooms")
		_cluster(Vector2(2870,3620),"mushrooms")
		_cluster(Vector2(5100,4340),"flowers")
		_cluster(Vector2(3100,5630),"margin")
		_landmark("ruins_a",Vector2(2060,2010),48,Vector2(24,12))
		_landmark("ruins_b",Vector2(1880,2070),44,Vector2(18,12))
		_landmark("crystal",Vector2(2050,2190),30,Vector2.ZERO)
	else:
		_cluster(Vector2(1470,330),"flowers")
		_cluster(Vector2(1740,450),"flowers")
		_cluster(Vector2(1120,1330),"margin")
		_cluster(Vector2(2050,1360),"margin")
		_cluster(Vector2(950,2070),"margin")
		_cluster(Vector2(2190,2130),"margin")
		_cluster(Vector2(3050,1890),"margin")
		_cluster(Vector2(1830,2820),"margin")
		_landmark("ruins_b",Vector2(1920,2830),44,Vector2(18,12))
	set_meta("enrichment_stats",stats.duplicate())
	_region.set_meta("map_art_ready",true)

func _replace_repeated_props() -> void:
	var index := 0
	for group_name in RULES.PROP_GROUPS:
		var group := _region.get_node_or_null(group_name)
		if group==null: continue
		for prop in group.get_children():
			if not prop is Node2D or not prop.visible: continue
			_occupied.append(prop.global_position)
			var sprite := prop as Sprite2D if prop is Sprite2D else prop.get_node_or_null("Sprite") as Sprite2D
			if sprite==null or sprite.texture==null: continue
			var path := sprite.texture.resource_path.to_lower()
			if (prop.has_meta("tree") or "oak" in path or "pine" in path) and not "log" in path:
				if not _canopy_images.has(path): _canopy_images[path]=sprite.texture.get_image()
				_canopies.append({"sprite":sprite,"image":_canopy_images[path],"foot_y":prop.global_position.y,"bounds":sprite.global_transform*sprite.get_rect()})
			# Preserve the silhouette around all existing solid footprints.
			if not prop.find_children("*","StaticBody2D",true,false).is_empty(): continue
			index += 1
			var key := ""
			if "flower" in path and index%4==0: key="flowers_a" if index%8==0 else "flowers_b"
			elif "mushroom" in path and index%3==0: key="mushrooms_a" if index%2==0 else "mushrooms_b"
			elif ("bush" in path or "shrub" in path) and index%4==1: key="bush_a" if index%8==1 else "bush_b"
			elif path.ends_with("/stone.png"): key="rock_a" if index%2==0 else "rock_b"
			elif "fallen_log" in path and index%2==0: key="log"
			if key.is_empty(): continue
			var old: Rect2i = sprite.texture.get_image().get_used_rect()
			var size := Vector2(old.size)*sprite.scale
			var used: Rect2i = _assets[key].used
			var factor := clampf(minf(size.x/used.size.x,size.y/used.size.y),.5,1.5)
			factor = maxf(.5,floorf(factor*4)/4)
			# Re-check the new visible extent against cliff faces.
			if _over_cliff(prop.global_position,used.size.y*factor): continue
			sprite.set_meta("original_texture",sprite.texture.resource_path)
			sprite.set_meta("curated_asset",key)
			sprite.texture = _assets[key].texture
			sprite.centered = false
			sprite.offset = -Vector2(used.position.x+used.size.x*.5,used.end.y)
			sprite.scale = Vector2.ONE*factor
			if sprite!=prop: sprite.position=Vector2.ZERO
			if key.begins_with("flowers"): sprite.modulate=Color.WHITE
			stats.replaced += 1

func _cluster(center: Vector2, style: String) -> void:
	var keys := ["bush_a","flowers_a","flowers_b","rock_b"]
	if style=="mushrooms": keys=["log","mushrooms_a","mushrooms_b","flowers_b"]
	elif style=="margin": keys=["rock_a","rock_b","bush_b","flowers_a"]
	var offsets := [Vector2(-34,-24),Vector2(12,4),Vector2(43,28),Vector2(-20,36)]
	var built := 0
	for i in keys.size():
		var height: float = [38,25,21,17][i]
		if style=="margin": height=[27,18,35,22][i]
		if style=="mushrooms": height=[30,26,20,18][i]
		var at := _find_spot(center+offsets[i],height,Vector2.ZERO,28)
		if at!=Vector2.INF:
			_add_item(keys[i],at,height,Vector2.ZERO)
			built += 1
	if built: stats.clusters += 1

func _landmark(key: String, desired: Vector2, height: float, solid: Vector2) -> void:
	var at := _find_spot(desired,height,solid,64,key)
	if at!=Vector2.INF:
		var prop := _add_item(key,at,height,solid)
		prop.set_meta("landmark",true)

func _find_spot(desired: Vector2, height: float, solid: Vector2, search: float, landmark_key: String="") -> Vector2:
	var offsets: Array[Vector2] = [Vector2.ZERO]
	for ring in range(1,4 if not landmark_key.is_empty() else 2):
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2(1,-1),Vector2(-1,-1),Vector2(1,1),Vector2(-1,1)]:
			offsets.append(direction*search*ring)
	for offset in offsets:
		var point: Vector2 = (desired+offset).round()
		if not can_place(point,height,solid): continue
		if not landmark_key.is_empty() and landmark_visibility(landmark_key,point,height)<.8: continue
		return point
	return Vector2.INF

func landmark_visibility(key: String, point: Vector2, height: float) -> float:
	var used: Rect2i = _assets[key].used
	var texture: Texture2D = _assets[key].texture
	var image := texture.get_image()
	var factor := clampf(roundf(height/used.size.y*4)/4,.5,1.5)
	var anchor := Vector2(used.position.x+used.size.x*.5,used.end.y)
	var candidates: Array[Dictionary] = []
	var bounds := Rect2(point+(Vector2(used.position)-anchor)*factor,Vector2(used.size)*factor)
	for canopy in _canopies:
		if canopy.foot_y>point.y and bounds.intersects(canopy.bounds): candidates.append(canopy)
	if candidates.is_empty(): return 1.0
	var total := 0
	var visible := 0
	for y in range(used.position.y,used.end.y,3):
		for x in range(used.position.x,used.end.x,3):
			if image.get_pixel(x,y).a<.5: continue
			total+=1
			var world := point+(Vector2(x,y)-anchor)*factor
			var hidden := false
			for canopy in candidates:
				var sprite: Sprite2D=canopy.sprite
				var pixel := sprite.to_local(world)-sprite.offset
				if sprite.centered: pixel+=sprite.texture.get_size()*.5
				var pixels: Image=canopy.image
				if pixel.x>=0 and pixel.y>=0 and pixel.x<pixels.get_width() and pixel.y<pixels.get_height() and pixels.get_pixelv(Vector2i(pixel)).a>.5:
					hidden=true
					break
			if not hidden: visible+=1
	return float(visible)/maxi(1,total)

func can_place(point: Vector2, height: float, solid: Vector2) -> bool:
	if not _region.player.world_bounds.grow(-40).has_point(point): return false
	var spawn: Vector2 = preload("res://scripts/world/forest_layout.gd").SPAWN if region_kind=="forest" else preload("res://scripts/world/valley_layout.gd").SPAWN
	if point.distance_to(spawn)<135: return false
	if region_kind=="forest" and point.distance_to(preload("res://scripts/world/forest_layout.gd").SOUTH_ARRIVAL)<100: return false
	if trail_distance(point)<(70.0 if solid!=Vector2.ZERO else 46.0): return false
	if _over_cliff(point,height): return false
	for occupied in _occupied:
		if point.distance_squared_to(occupied)<30*30: return false
	if region_kind=="valley":
		for bridge in preload("res://scripts/world/valley_layout.gd").BRIDGES:
			if bridge.grow(38).has_point(point): return false
	var shape := CircleShape2D.new()
	shape.radius = maxf(18,solid.x*.5+10)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0,point+Vector2(0,-5))
	query.collision_mask = 2
	return get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _over_cliff(point: Vector2, height: float) -> bool:
	for polygon in _cliffs:
		for offset in range(0,ceili(height)+1,4):
			if Geometry2D.is_point_in_polygon(point-Vector2(0,offset),polygon): return true
	return false

func trail_distance(point: Vector2) -> float:
	var distance := INF
	for curve: Curve2D in _routes.values(): distance=minf(distance,point.distance_to(curve.get_closest_point(point)))
	return distance

func _add_item(key: String, point: Vector2, height: float, solid: Vector2) -> Node2D:
	var prop := Node2D.new()
	prop.name = "%s_%02d" % [key,stats.added]
	prop.position = point
	prop.set_meta("curated_asset",key)
	var used: Rect2i = _assets[key].used
	var factor := clampf(roundf(height/used.size.y*4)/4,.5,1.5)
	var sprite := Sprite2D.new()
	sprite.name="Sprite"
	sprite.texture=_assets[key].texture
	sprite.centered=false
	sprite.offset=-Vector2(used.position.x+used.size.x*.5,used.end.y)
	sprite.scale=Vector2.ONE*factor
	if key.begins_with("flowers") or key.begins_with("bush"):
		sprite.material=_region.ecosystem.get_wind_material("plant")
	prop.add_child(sprite)
	if solid!=Vector2.ZERO:
		var body:=StaticBody2D.new()
		body.name="SolidBase"
		body.collision_layer=2
		body.collision_mask=0
		var shape:=CollisionShape2D.new()
		shape.name="Footprint"
		var rectangle:=RectangleShape2D.new()
		rectangle.size=solid
		shape.shape=rectangle
		shape.position.y=-solid.y*.5
		body.add_child(shape)
		prop.add_child(body)
		stats.solids+=1
	add_child(prop)
	_occupied.append(point)
	stats.added+=1
	return prop

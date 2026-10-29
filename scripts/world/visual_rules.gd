extends RefCounted
## One load-time pass for both maps. Three visual classes, shared foot sorting,
## deterministic plant spacing; no physics, player, quest or original PNG changes.
const PROP_GROUPS := ["VegetationHigh","ExpandedForest","Decorations","FlowerClusters","WoodlandDetails","HiddenGroveDetails","TreesBack","TreesFront","LowVegetation","HabitatFlora"]
var _routes: Dictionary = {}
var _plants: Dictionary = {}
var _cliffs: Array[PackedVector2Array] = []
var _stats := {"sorted_props":0,"ground_cover":0,"thinned_plants":0,"root_lines":0}

func apply(region: Node2D, paths: Dictionary) -> Dictionary:
	if region.has_meta("visual_rules_applied"):return region.get_meta("visual_rules_applied")
	region.y_sort_enabled=true
	_cliffs = preload("res://scripts/world/region_surfaces.gd").cliff_faces(region)
	_stats["cliff_plants_removed"] = 0
	_sort_painted_plants(region)
	for curve: Curve2D in paths.values():
		for offset in range(0,int(curve.get_baked_length())+24,24):
			var at:=curve.sample_baked(minf(offset,curve.get_baked_length()))
			var key:=Vector2i(floori(at.x/128),floori(at.y/128))
			if not _routes.has(key):_routes[key]=[]
			_routes[key].append(at)
	for label in PROP_GROUPS:
		var group:=region.get_node_or_null(label) as Node2D
		if group==null:continue
		group.z_index=0
		group.y_sort_enabled=true
		for prop in group.get_children():
			var sprite:=prop as Sprite2D if prop is Sprite2D else prop.get_node_or_null("Sprite") as Sprite2D
			if sprite==null:
				# Hand-authored log containers have auto-generated sprite names.
				for child in prop.get_children():
					if child is Sprite2D:sprite=child;break
			if sprite==null or sprite.texture==null or not prop.visible:continue
			var path:=sprite.texture.resource_path.to_lower()
			var plant:=is_plant(path)
			var plant_height := sprite.texture.get_image().get_used_rect().size.y * sprite.scale.y if plant else 0.0
			if (plant and _plant_on_cliff(prop.global_position,plant_height)) or (prop.has_meta("tree") and _on_cliff(prop.global_position)):
				prop.hide()
				_stats.cliff_plants_removed += 1
				# The wall already occupies this footprint; don't leave a hidden tree collider.
				for body in prop.find_children("*","StaticBody2D",true,false): body.collision_layer = 0
				continue
			var flat := is_ground_cover(path)
			prop.z_index=-2 if flat else 0
			prop.y_sort_enabled=false
			sprite.z_index=0 if sprite!=prop else prop.z_index
			if flat:_stats.ground_cover+=1
			else:_stats.sorted_props+=1
			if plant and not prop.has_node("SolidBase"):
				var at:Vector2=prop.global_position
				var spacing:=52.0 if ("bush" in path or "shrub" in path) else (30.0 if "mushroom" in path else 34.0)
				var key:=Vector2i(floori(at.x/64),floori(at.y/64))
				var crowded:=_trail_distance(at)<36.0
				for y in range(-1,2):
					for x in range(-1,2):
						for other:Vector2 in _plants.get(key+Vector2i(x,y),[]):
							if at.distance_squared_to(other)<spacing*spacing:crowded=true
				if crowded:
					prop.hide()
					_stats.thinned_plants+=1
				else:
					if not _plants.has(key):_plants[key]=[]
					_plants[key].append(at)
	_fix_roots(region)
	region.set_meta("visual_rules_applied",_stats.duplicate())
	return _stats

static func is_plant(path: String) -> bool:
	return "flower" in path or "mushroom" in path or "fern" in path or "bush" in path or "shrub" in path or "grass.png" in path

static func is_ground_cover(path: String) -> bool:
	# Walkable surfaces belong below feet even when stored among decorative props.
	return ("grass" in path and not "tall" in path) or "steps" in path or "ramp" in path or "bridge" in path

func _sort_painted_plants(region: Node2D) -> void:
	var layer := region.get_node_or_null("VegetationLow") as TileMapLayer
	if layer == null: return
	# This layer also contains upright flowers/mushrooms. Keep the painted cells
	# and colours, but sort each tile at its visible foot instead of below actors.
	layer.tile_set = layer.tile_set.duplicate(true)
	layer.z_index = 0
	layer.y_sort_enabled = true
	for index in layer.tile_set.get_source_count():
		var atlas := layer.tile_set.get_source(layer.tile_set.get_source_id(index)) as TileSetAtlasSource
		if atlas == null: continue
		var flat := is_ground_cover(atlas.texture.resource_path)
		var used := atlas.texture.get_image().get_used_rect()
		for tile_index in atlas.get_tiles_count():
			var coords := atlas.get_tile_id(tile_index)
			for alt_index in atlas.get_alternative_tiles_count(coords):
				var data := atlas.get_tile_data(coords,atlas.get_alternative_tile_id(coords,alt_index))
				data.z_index = -2 if flat else 0
				data.y_sort_origin = roundi(used.end.y - atlas.texture_region_size.y * .5 - data.texture_origin.y)
	for cell in layer.get_used_cells():
		var data := layer.get_cell_tile_data(cell)
		var atlas := layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
		var height: float = atlas.texture.get_image().get_used_rect().size.y
		if _plant_on_cliff(layer.to_global(layer.map_to_local(cell)+Vector2(0,data.y_sort_origin)),height):
			layer.erase_cell(cell)
			_stats.cliff_plants_removed += 1

func _plant_on_cliff(foot: Vector2, height: float) -> bool:
	# A plant rooted just below a wall can still visually grow out of its face.
	for offset in range(0,ceili(height)+1,4):
		if _on_cliff(foot-Vector2(0,offset)): return true
	return false

func _on_cliff(at: Vector2) -> bool:
	for polygon in _cliffs:
		if Geometry2D.is_point_in_polygon(at,polygon): return true
	return false

func _trail_distance(at: Vector2) -> float:
	var key:=Vector2i(floori(at.x/128),floori(at.y/128))
	var nearest:=INF
	for y in range(-1,2):
		for x in range(-1,2):
			for point: Vector2 in _routes.get(key+Vector2i(x,y),[]):nearest=minf(nearest,at.distance_squared_to(point))
	return sqrt(nearest)

func _fix_roots(region: Node2D) -> void:
	var roots:=region.get_node_or_null("AncientRoots")
	if roots==null:return
	# The old five long straight fans looked like diagonal shadow stripes.
	# Rebuild them as short, angular roots physically attached to the oak's foot.
	var index:=0
	for line in roots.get_children():
		if not line is Line2D:continue
		var side:float=float(index-2)
		line.points=PackedVector2Array([Vector2(2860+side*4,1797),Vector2(2860+side*8,1805),Vector2(2860+side*12,1809),Vector2(2860+side*15,1815)])
		line.width=2
		line.default_color=Color("716b42")
		index+=1
		_stats.root_lines+=1

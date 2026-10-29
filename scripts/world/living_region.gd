extends RefCounted
## Shared setup only: existing maps and painted props stay unchanged on disk.
const STATE = preload("res://scripts/world/environment_state.gd")

static func connect_environment(region: Node2D, life: Node2D, tree_groups: Array, plant_groups: Array, water: Array[Vector2], bounds: Rect2, zone: Callable) -> Node2D:
	var leaves: Array[Vector2] = []
	var wildlife: Array[Vector2] = []
	for group: Node in tree_groups:
		for prop in group.get_children():
			var sprite := prop.get_node_or_null("Sprite") as Sprite2D
			if sprite == null or not prop.visible: continue
			var path := sprite.texture.resource_path.to_lower() if sprite.texture else ""
			# Rocks and logs in ExpandedForest stay still; only foliage receives wind.
			if not ("oak" in path or "pine" in path or "tree" in path): continue
			sprite.material = life.get_wind_material("pine" if "pine" in path else "oak")
			leaves.append(prop.global_position+Vector2(0,-70))
			wildlife.append(prop.global_position+Vector2(28,12))
	for group: Node in plant_groups:
		for prop in group.get_children():
			var sprite := prop as Sprite2D if prop is Sprite2D else prop.get_node_or_null("Sprite") as Sprite2D
			if sprite == null: continue
			var path := sprite.texture.resource_path.to_lower() if sprite.texture else ""
			if "flower" in path or "fern" in path or "shrub" in path or "grass" in path or "bush" in path or "reeds" in path:
				sprite.material = life.get_wind_material("plant")
	life.configure_leaf_sources(leaves)
	var shape := CircleShape2D.new()
	shape.radius = 7
	var forbidden: Array[PackedVector2Array] = []
	if region.has_node("Water"):
		for polygon in region.get_node("Water").get_children():
			if polygon is Polygon2D:forbidden.append(polygon.polygon)
	life.configure_wildlife(wildlife, func(at: Vector2) -> bool:
		if not is_instance_valid(region) or not bounds.has_point(at): return false
		for polygon in forbidden:
			if Geometry2D.is_point_in_polygon(at,polygon):return false
		if region.has_node("Bridges"):
			for bridge in preload("res://scripts/world/valley_layout.gd").BRIDGES:
				if bridge.grow(16).has_point(at):return false
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = Transform2D(0,at)
		query.collision_mask = 2
		return region.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty())
	for species in ["squirrel","bird"]:
		var path := "res://assets/wildlife/living_v3/%s/frames.tres" % species
		if ResourceLoader.exists(path): life.configure_wildlife_frames(species,load(path))
	var state = STATE.new()
	var saved: Dictionary = region.get_tree().get_meta("environment_conditions",{})
	state.set_conditions(saved.get("period","morning"),saved.get("rain",0.0),saved.get("wind",1.0),saved.get("fog",0.0))
	life.set_environment_state(state)
	region.add_child(life)
	var audio = preload("res://scripts/world/forest_audio.gd").new()
	audio.name = "EnvironmentalAudio"
	audio.configure(region.player,water,zone)
	audio.set_environment_state(state)
	region.add_child(audio)
	return audio

static func conditions(region: Node2D, period: String, rain: float, wind: float, fog: float) -> void:
	var state = STATE.new()
	state.set_conditions(period,rain,wind,fog)
	region.ecosystem.set_environment_state(state)
	region.environmental_audio.set_environment_state(state)
	region.habitat_manager.set_environment_state(state.snapshot())
	region.get_tree().set_meta("environment_conditions",state.snapshot())

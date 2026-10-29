extends RefCounted
## Classify existing baked geometry without changing player collision layers.
const VALLEY = preload("res://scripts/world/valley_layout.gd")

static func water_parts() -> Array[PackedVector2Array]:
	var parts: Array[PackedVector2Array] = []
	for basin in VALLEY.basins(): parts.append(VALLEY.blob(basin[0],basin[1],parts.size()))
	for stream in VALLEY.streams(): parts.append(VALLEY.ribbon(stream[0],stream[1]))
	for at in [Vector2(640,420),Vector2(2470,410),Vector2(1600,1010)]: parts.append(VALLEY.blob(at,Vector2(72,46),at.x))
	for i in 7:
		if i%2 == 0:
			var at := Vector2(450+(i%3)*150,2420+(i/3)*160)
			parts.append(VALLEY.blob(at+Vector2(15,0),Vector2(78,50),i))
	var result: Array[PackedVector2Array] = []
	for part in parts:
		var fragments: Array[PackedVector2Array] = [part]
		for bridge: Rect2 in VALLEY.BRIDGES:
			var box := PackedVector2Array([bridge.position,bridge.position+Vector2(bridge.size.x,0),bridge.end,bridge.position+Vector2(0,bridge.size.y)])
			var clipped: Array[PackedVector2Array] = []
			for fragment in fragments: clipped.append_array(Geometry2D.clip_polygons(fragment,box))
			fragments = clipped
		for fragment in fragments:
			if fragment.size()>2: result.append(fragment)
	return result

static func classify_water(region: Node2D) -> Array[PhysicsBody2D]:
	var result: Array[PhysicsBody2D] = []
	if not region.has_node("Water"): return result
	var expected := water_parts()
	for body in region.get_node("Obstacles").get_children():
		if body.has_meta("swimmable_water"):
			result.append(body)
			continue
		for shape in body.get_children():
			if not shape is CollisionPolygon2D: continue
			for polygon in expected:
				if polygon.size()!=shape.polygon.size(): continue
				var same := true
				for index in polygon.size():
					var nearest := INF
					for vertex in shape.polygon: nearest=minf(nearest,polygon[index].distance_to(shape.to_global(vertex)))
					if nearest>.05:
						same = false
						break
				if same:
					body.set_meta("swimmable_water",true)
					result.append(body)
					break
			# Older bakes contain one reshaped spring. Accept its existing irregular
			# water contour only when every vertex belongs to the rendered water.
			if not body.has_meta("swimmable_water") and shape.polygon.size()>8:
				var contained := true
				for vertex in shape.polygon:
					var point: Vector2 = shape.to_global(vertex)
					var wet := false
					for surface in region.get_node("Water").get_children():
						if not surface is Polygon2D: continue
						var local: Vector2 = surface.to_local(point)
						if Geometry2D.is_point_in_polygon(local,surface.polygon): wet=true;break
						for i in surface.polygon.size():
							if local.distance_to(Geometry2D.get_closest_point_to_segment(local,surface.polygon[i],surface.polygon[(i+1)%surface.polygon.size()]))<.2: wet=true;break
						if wet: break
					if not wet: contained=false;break
				if contained:
					body.set_meta("swimmable_water",true)
					result.append(body)
	return result

static func cliff_faces(region: Node2D) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var group := region.get_node_or_null("NorthernLedges")
	if group == null and region.has_node("Water"):
		classify_water(region)
		group = region.get_node("Obstacles")
	if group == null: return result
	for body in group.get_children():
		if not body is StaticBody2D or body.has_meta("swimmable_water"): continue
		for shape in body.get_children():
			if shape is CollisionPolygon2D:
				var world := PackedVector2Array()
				for point in shape.polygon: world.append(shape.to_global(point))
				result.append(world)
	return result

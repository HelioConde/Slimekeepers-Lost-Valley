extends SceneTree
func _initialize() -> void:
	var scene: Node2D = load("res://scenes/regions/ValeDasNascentes.tscn").instantiate()
	var surfaces = preload("res://scripts/world/region_surfaces.gd")
	var expected = surfaces.water_parts()
	var actual = surfaces.classify_water(scene)
	print("EXPECTED ",expected.size()," ACTUAL ",actual.size())
	for poly in expected:
		var nearest := INF
		var label := ""
		for body in scene.get_node("Obstacles").get_children():
			for shape in body.get_children():
				if shape is CollisionPolygon2D and shape.polygon.size()==poly.size():
					var delta := 0.0
					for i in poly.size(): delta=maxf(delta,shape.polygon[i].distance_to(poly[i]))
					if delta<nearest:nearest=delta;label=str(body.name)
		if nearest>.05:
			var vertices: PackedVector2Array=scene.get_node("Obstacles/"+label).get_child(0).polygon
			var error := 0.0
			for point in poly:
				var edge_error := INF
				for i in vertices.size():edge_error=minf(edge_error,point.distance_to(Geometry2D.get_closest_point_to_segment(point,vertices[i],vertices[(i+1)%vertices.size()])))
				error=maxf(error,edge_error)
			print("UNMATCHED vertices=",poly.size()," first=",poly[0]," nearest=",nearest," body=",label," edge_error=",error)
	scene.free()
	quit()

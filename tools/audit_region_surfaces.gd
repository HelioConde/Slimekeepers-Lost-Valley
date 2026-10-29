extends SceneTree
func _initialize() -> void:
	for map in ["FlorestaDoDespertarV2","ValeDasNascentes"]:
		var scene: Node2D = load("res://scenes/regions/%s.tscn" % map).instantiate()
		var counts := {}
		var group := scene.get_node_or_null("Obstacles")
		if group and not group is TileMapLayer:
			for body in group.get_children():
				for shape in body.get_children():
					if shape is CollisionPolygon2D:
						var size: int = shape.polygon.size()
						counts[size] = counts.get(size,0)+1
		print(map," obstacles=",counts)
		scene.free()
	quit()

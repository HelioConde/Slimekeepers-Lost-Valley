extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(scene)
	for i in 6: await physics_frame
	var shape := CapsuleShape2D.new()
	shape.radius=12
	shape.height=34
	var result := []
	for center: Vector2 in [Vector2(4920,3170),Vector2(3240,4870),Vector2(4880,3160),Vector2(3220,4860)]:
		var free := []
		for y in range(-96,97,32):
			for x in range(-96,97,32):
				var at := center+Vector2(x,y)
				var query := PhysicsShapeQueryParameters2D.new()
				query.shape=shape
				query.transform=Transform2D(0,at+Vector2(0,-17))
				query.collision_mask=2
				if scene.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():free.append([at.x,at.y])
		result.append({"center":[center.x,center.y],"free_points":free})
	FileAccess.open("res://docs/world/living_v3/habitat_survey.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result))
	scene.queue_free()
	await process_frame
	quit()

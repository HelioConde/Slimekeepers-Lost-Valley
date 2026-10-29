extends "res://tools/explore_forest_v2.gd"
## Same physical route planner; separate discovery measurements, not human play claims.
func run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(960,540)
	scene=load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	for i in 8:await physics_frame
	build_navigation()
	var routes: Array = []
	var shortest := PackedVector2Array()
	var destination := ""
	var shortest_length := INF
	for habitat in Layout.habitats():
		var route := route_to(habitat.center)
		var length := 0.0
		for i in range(1,route.size()): length += route[i-1].distance_to(route[i])
		routes.append({"id":habitat.id,"straight_distance":Layout.SPAWN.distance_to(habitat.center),"navigable_distance":length,"waypoints":route.size()})
		if not route.is_empty() and length<shortest_length:
			shortest=route
			shortest_length=length
			destination=habitat.id
	start_time=Time.get_ticks_msec()
	var index := 0
	var seen := -1.0
	var seen_id := ""
	var reachable := -1.0
	while elapsed()<60 and index<shortest.size():
		await physics_frame
		for slime in scene.slimes:
			var half_view: Vector2 = Vector2(960,540)/scene.player.get_node("Camera2D").zoom/2
			var view := Rect2(scene.player.get_node("Camera2D").get_screen_center_position()-half_view,half_view*2)
			if seen<0 and view.has_point(slime.global_position+Vector2(0,-18)):
				seen=elapsed()
				seen_id=slime.persistent_id
			if reachable<0 and slime.position.distance_to(scene.player.position)<90: reachable=elapsed()
		if scene.player.position.distance_to(shortest[index])<7:
			index+=1
			continue
		input_direction(scene.player.position.direction_to(shortest[index]))
	input_direction(Vector2.ZERO)
	var result := {"routes":routes,"chosen_habitat":destination,"first_camera_entry_seconds":seen,"first_visible_id":seen_id,"first_interaction_range_seconds":reachable,"habitat_arrival_seconds":elapsed(),"arrived":index>=shortest.size(),"walk_speed":145,"method":"Native rendering, actual Input actions, capsule-validated AStarGrid. Camera entry measures framing, not perceptual recognition or canopy occlusion. No initial pause; no human exploration time claimed."}
	FileAccess.open("res://docs/world/living_v3/discovery.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("DISCOVERY ",JSON.stringify(result))
	scene.queue_free()
	await process_frame
	quit(0 if index>=shortest.size() and seen>=0 else 1)

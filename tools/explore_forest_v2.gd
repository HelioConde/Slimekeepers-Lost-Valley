extends SceneTree
## Five real minutes of native rendered exploration using the actual input/controller.
## Physics-sampled AStarGrid plans routes; no teleporting between locations.
const Layout = preload("res://scripts/world/forest_layout.gd")
var scene: Node2D
var grid := AStarGrid2D.new()
var stats: Array[Dictionary] = []
var reached: Array[String] = []
var first_seen := -1.0
var stalls := 0
var failures: Array[String] = []
var nav_shape := CapsuleShape2D.new()
var start_time: int
var load_ms: int

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(960,540)
	var load_start := Time.get_ticks_msec()
	scene = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 8: await physics_frame
	load_ms = Time.get_ticks_msec()-load_start
	build_navigation()
	var goals: Array = [
		["Jardim das Folhas",Vector2(4480,3270)], ["Jardim Escondido",Vector2(5100,4250)],
		["Campo dos Brotos",Vector2(3350,4580)], ["Passagem Úmida",Vector2(3220,5680)],
		["Chegada sul",Layout.SOUTH_ARRIVAL], ["Tronco do Tempo",Vector2(2800,3660)],
		["Cogumelos",Vector2(2100,2860)], ["Círculo Musgoso",Vector2(1980,2120)],
		["Árvore Centenária",Vector2(2860,1880)], ["Mirante",Vector2(5110,1260)],
		["Bosque Silencioso",Vector2(4880,1700)], ["Saída norte",Vector2(3270,120)],
		["Saída leste",Vector2(6280,3150)], ["Clareira",Layout.SPAWN]]
	start_time = Time.get_ticks_msec()
	var second := -1
	var waypoint_index := 0
	var goal_index := 0
	var waypoints := route_to(goals[0][1])
	var last_position: Vector2 = scene.player.position
	var last_motion := 0.0
	var pause_until := 2.0
	while elapsed()<300:
		await physics_frame
		var time := elapsed()
		if int(time) != second:
			second = int(time)
			sample_metrics(time)
			if second%30==0: print("EXPLORE t=",second," position=",scene.player.position," reached=",reached.size())
		if first_seen < 0:
			for slime in scene.slimes:
				var d: Vector2 = slime.position-scene.player.position
				if absf(d.x)<420 and absf(d.y)<235:
					first_seen=time
					print("FIRST_VISIBLE_SLIME seconds=",time," id=",slime.persistent_id)
		if scene.player.position.distance_to(last_position)>4:
			last_motion=time
			last_position=scene.player.position
		if time<pause_until or goal_index>=goals.size():
			input_direction(Vector2.ZERO)
			continue
		if waypoints.is_empty():
			failures.append("No route to "+str(goals[goal_index][0]))
			break
		if waypoint_index>=waypoints.size():
			reached.append(goals[goal_index][0])
			print("REACHED ",goals[goal_index][0]," t=",time)
			goal_index+=1
			input_direction(Vector2.ZERO)
			pause_until=time+2.0
			last_motion=pause_until
			if goal_index<goals.size():
				waypoints=route_to(goals[goal_index][1])
				waypoint_index=0
			continue
		var target: Vector2 = waypoints[waypoint_index]
		if scene.player.position.distance_to(target)<7:
			waypoint_index+=1
			continue
		input_direction(scene.player.position.direction_to(target))
		if time-last_motion>3:
			stalls+=1
			failures.append("Movement stalled at "+str(scene.player.position)+" toward "+str(target))
			break
	input_direction(Vector2.ZERO)
	var effects := await compare_effects()
	var report := {"duration_seconds":elapsed(),"load_ms":load_ms,"first_visible_slime_seconds":first_seen,"controller":"real Input actions, WALK_SPEED 145; AStarGrid with physics; no teleports", "reached":reached,"stalls":stalls,"failures":failures,"samples":stats,"effects_comparison":effects}
	FileAccess.open("res://docs/world/forest_v2/performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("EXPLORATION_DONE ",JSON.stringify({"seconds":elapsed(),"load_ms":load_ms,"reached":reached.size(),"stalls":stalls,"failures":failures}))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func elapsed() -> float:
	return (Time.get_ticks_msec()-start_time)/1000.0

func input_direction(direction: Vector2) -> void:
	for pair in [["move_left",maxf(-direction.x,0)],["move_right",maxf(direction.x,0)],["move_up",maxf(-direction.y,0)],["move_down",maxf(direction.y,0)]]:
		if pair[1]>0: Input.action_press(pair[0],pair[1])
		else: Input.action_release(pair[0])

func build_navigation() -> void:
	grid.region=Rect2i(0,0,200,200)
	grid.cell_size=Vector2(32,32)
	grid.offset=Vector2(16,16)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	nav_shape.radius=17
	nav_shape.height=38
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape=nav_shape
	query.collision_mask=2
	for y in 200:
		for x in 200:
			var cell := Vector2i(x,y)
			var at := Vector2(cell*32)+Vector2(16,16)
			query.transform=Transform2D(0,at+Vector2(0,-17))
			var blocked := x<1 or y<2 or x>198 or y>198 or not scene.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
			grid.set_point_solid(cell,blocked)
			grid.set_point_weight_scale(cell,4.0)
	# Route preference encourages intentional trails, while respecting actual obstacles.
	for curve: Curve2D in Layout.trails().values():
		for p in curve.get_baked_points():
			var cell := Vector2i(p/32)
			for offset in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				if grid.is_in_boundsv(cell+offset): grid.set_point_weight_scale(cell+offset,1.0)

func route_to(target: Vector2) -> PackedVector2Array:
	var end := Vector2i(target/32)
	if grid.is_point_solid(end):
		for offset in [Vector2i.DOWN,Vector2i.UP,Vector2i.RIGHT,Vector2i.LEFT]:
			if not grid.is_point_solid(end+offset):
				end+=offset
				break
	return grid.get_point_path(Vector2i(scene.player.position/32),end)

func sample_metrics(time: float) -> void:
	var ecology: Dictionary = scene.ecosystem.debug_snapshot()
	stats.append({"second":int(time),"fps":Engine.get_frames_per_second(),"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"static_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"zone":Layout.zone(scene.player.position),"ecology":ecology})

func compare_effects() -> Dictionary:
	var result := {}
	for enabled in [true,false]:
		scene.ecosystem.set_reduced_motion(not enabled)
		scene.ecosystem.set_process(enabled)
		await create_timer(1).timeout
		var total := 0.0
		var frames := 0
		var began := Time.get_ticks_usec()
		while Time.get_ticks_usec()-began<5000000:
			await process_frame
			total+=Performance.get_monitor(Performance.TIME_PROCESS)*1000
			frames+=1
		result["enabled" if enabled else "disabled"]={"frames":frames,"mean_process_ms":total/maxi(frames,1),"wall_seconds":5.0}
	scene.ecosystem.set_process(true)
	return result

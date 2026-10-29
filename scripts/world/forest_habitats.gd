extends Node2D
## Bounded, deterministic habitat slots. Coordinates are in world space.
signal slime_spawned(slime: Node2D)
const SLIME_SCRIPT := preload("res://scripts/world/forest_slime.gd")
const EXCLUSION_RADIUS := 960.0
const BODY_RADIUS := 12.0
const MIN_SEPARATION := 50.0
const RESPAWN_COOLDOWN := 20.0
const MAX_POPULATION := 10
const WORLD_BOUNDS := Rect2(32, 32, 6336, 6336)

var world_bounds := WORLD_BOUNDS
var exclusion_radius := EXCLUSION_RADIUS
var max_population := MAX_POPULATION
var session_key := "forest_slime_friends"
var protect_initial_view := true
var environmental_state: Dictionary = {"period": "day", "rain": 0.0}
var water_bodies: Array[PhysicsBody2D] = []
var water_outlines: Array[PackedVector2Array] = []
var _water_targets_ready := false
var _swim_grids: Dictionary = {}

var spawned: Array[Node2D] = []
var habitats: Array[Dictionary] = []
var region: Node2D
var player: Node2D
var player_spawn := Vector2(3200, 3200)
var _slots: Dictionary = {}
var _retry_at: Dictionary = {}
var _elapsed := 0.0
var _check_timer := 0.0
var _body_shape := CapsuleShape2D.new()
var _configured := false
var _initial_camera_rect := Rect2()
var _physics_warmup := 2

func configure(owner_region: Node2D, owner_player: Node2D, spawn: Vector2, habitat_data: Array[Dictionary], options: Dictionary = {}) -> void:
	if _configured:
		return
	_configured = true
	region = owner_region
	player = owner_player
	player_spawn = spawn
	habitats = habitat_data.duplicate(true)
	world_bounds = options.get("world_bounds", WORLD_BOUNDS)
	exclusion_radius = maxf(0.0, float(options.get("exclusion_radius", EXCLUSION_RADIUS)))
	max_population = clampi(int(options.get("max_population", MAX_POPULATION)), 0, 32)
	session_key = str(options.get("session_key", "forest_slime_friends"))
	protect_initial_view = bool(options.get("protect_initial_view", true))
	water_bodies.assign(options.get("water_bodies",[]))
	water_outlines.assign(options.get("water_outlines",[]))
	_body_shape.radius = BODY_RADIUS
	_body_shape.height = 28.0
	var half_view := Vector2(640, 360)
	if is_instance_valid(player):
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			half_view = get_viewport_rect().size / camera.zoom / 2.0
	_initial_camera_rect = Rect2(player_spawn - half_view, half_view * 2.0).grow(64.0)
	set_physics_process(true)

func set_environment_state(state: Dictionary) -> void:
	environmental_state.merge(state, true)

func _physics_process(_delta: float) -> void:
	# Region props are built synchronously; wait until physics has registered them.
	if not _configured:
		return
	_physics_warmup -= 1
	if _physics_warmup <= 0:
		set_physics_process(false)
		call_deferred("populate")

func _process(delta: float) -> void:
	_elapsed += delta
	_check_timer -= delta
	if _check_timer <= 0.0 and _configured:
		_check_timer = 1.0
		# Only attempt missing slots after the initial population has run.
		if _elapsed >= RESPAWN_COOLDOWN:
			populate()

func populate() -> void:
	if not _configured or not is_instance_valid(region) or not region.is_inside_tree():
		return
	if not _water_targets_ready:
		_water_targets_ready = true
		_prepare_swimming_targets()
	for index in range(spawned.size() - 1, -1, -1):
		if not is_instance_valid(spawned[index]) or spawned[index].is_queued_for_deletion():
			spawned.remove_at(index)
	for habitat: Dictionary in habitats:
		var habitat_id := str(habitat.get("id", ""))
		if habitat_id.is_empty():
			continue
		var species_slots: Array = habitat.get("species_slots", [])
		var population := species_slots.size() if not species_slots.is_empty() else int(habitat.get("population", 2))
		for index in clampi(population, 0, max_population):
			var species := str(species_slots[index]) if not species_slots.is_empty() else "brotinho"
			if not SLIME_SCRIPT.SPECIES.available(species):
				continue
			var persistent_id := "%s/%s/%d" % [species, habitat_id, index]
			if is_instance_valid(_slots.get(persistent_id)):
				continue
			if spawned.size() >= max_population or _elapsed < float(_retry_at.get(persistent_id, -1.0)):
				continue
			_retry_at[persistent_id] = _elapsed + RESPAWN_COOLDOWN
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(persistent_id)
			var spawn_points: Array = habitat.get("spawn_points", [])
			for attempt in 48:
				var center: Vector2 = habitat.get("center", Vector2.ZERO)
				var radius := maxf(0.0, float(habitat.get("radius", 200.0)) - BODY_RADIUS - 16.0)
				var candidate := center + Vector2.from_angle(rng.randf_range(0.0, TAU)) * sqrt(rng.randf()) * radius
				if not spawn_points.is_empty():
					candidate = spawn_points[(index + attempt) % spawn_points.size()]
				if not is_position_allowed(candidate, habitat) or _in_current_view(candidate):
					continue
				var slime: Node2D = SLIME_SCRIPT.new()
				slime.configure(self, player, habitat, persistent_id)
				region.add_child(slime)
				slime.global_position = candidate
				_slots[persistent_id] = slime
				spawned.append(slime)
				slime.tree_exiting.connect(_on_slime_exiting.bind(persistent_id))
				slime_spawned.emit(slime)
				break

func _on_slime_exiting(persistent_id: String) -> void:
	_slots.erase(persistent_id)
	_retry_at[persistent_id] = _elapsed + RESPAWN_COOLDOWN

func is_position_allowed(point: Vector2, habitat: Dictionary, ignore: Node2D = null) -> bool:
	if not world_bounds.has_point(point) or point.distance_to(player_spawn) < exclusion_radius + BODY_RADIUS:
		return false
	if protect_initial_view and _initial_camera_rect.has_point(point):
		return false
	var center: Vector2 = habitat.get("center", Vector2.ZERO)
	if point.distance_to(center) > maxf(0.0, float(habitat.get("radius", 200.0)) - BODY_RADIUS):
		return false
	for slime: Node2D in spawned:
		if is_instance_valid(slime) and slime != ignore and point.distance_to(slime.global_position) < MIN_SEPARATION:
			return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _body_shape
	query.transform = Transform2D(0.0, point + Vector2(0, -10))
	query.collision_mask = 2
	if ignore != null and ignore.get("slime_type") == "bolhinha": query.exclude = water_exclusions()
	query.collide_with_areas = false
	return region.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func water_exclusions() -> Array[RID]:
	var result: Array[RID] = []
	for body in water_bodies:
		if is_instance_valid(body): result.append(body.get_rid())
	return result

func is_water(point: Vector2) -> bool:
	for polygon in water_outlines:
		if Geometry2D.is_point_in_polygon(point,polygon): return true
	return false

func swimming_route(from: Vector2, to: Vector2, habitat: Dictionary, actor: Node2D) -> PackedVector2Array:
	var key: String = habitat.id
	var grid: AStarGrid2D
	if _swim_grids.has(key): grid = _swim_grids[key]
	else:
		grid = AStarGrid2D.new()
		var center: Vector2 = habitat.center
		var radius: float = habitat.radius
		grid.region = Rect2i(Vector2i((center-Vector2.ONE*radius)/16)-Vector2i.ONE,Vector2i.ONE*(ceili(radius*2/16)+3))
		grid.cell_size = Vector2(16,16)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		grid.update()
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = _body_shape
		query.collision_mask = 2
		query.exclude = water_exclusions()
		for y in range(grid.region.position.y,grid.region.end.y):
			for x in range(grid.region.position.x,grid.region.end.x):
				var cell := Vector2i(x,y)
				var point := Vector2(cell)*16
				query.transform = Transform2D(0,point+Vector2(0,-10))
				grid.set_point_solid(cell,point.distance_to(center)>radius-BODY_RADIUS or not world_bounds.has_point(point) or not region.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty())
		_swim_grids[key] = grid
	var occupied: Array[Vector2i] = []
	for other in spawned:
		if not is_instance_valid(other) or other==actor: continue
		var center := Vector2i((other.global_position/16).round())
		for y in range(-4,5):
			for x in range(-4,5):
				var cell := center+Vector2i(x,y)
				if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell) and (Vector2(cell)*16).distance_to(other.global_position)<MIN_SEPARATION+8:
					grid.set_point_solid(cell,true)
					occupied.append(cell)
	var start := _nearest_swim_cell(grid,from)
	var end := _nearest_swim_cell(grid,to)
	var result := PackedVector2Array()
	if start!=Vector2i(-1,-1) and end!=Vector2i(-1,-1): result=grid.get_point_path(start,end)
	for cell in occupied: grid.set_point_solid(cell,false)
	if not result.is_empty(): result.append(to)
	return result

func _nearest_swim_cell(grid: AStarGrid2D, at: Vector2) -> Vector2i:
	var center := Vector2i((at/16).round())
	var best := Vector2i(-1,-1)
	var distance := INF
	for y in range(-2,3):
		for x in range(-2,3):
			var cell := center+Vector2i(x,y)
			if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell): continue
			var d := (Vector2(cell)*16).distance_squared_to(at)
			if d<distance: distance=d;best=cell
	return best

func _prepare_swimming_targets() -> void:
	if water_bodies.is_empty(): return
	for habitat in habitats:
		var center: Vector2 = habitat.center
		var points: Array[Vector2] = []
		for radius in range(40,301,32):
			for angle in 24:
				var point := center + Vector2.from_angle(TAU*angle/24.0)*radius
				var submerged := is_water(point)
				for offset in [Vector2(16,0),Vector2(-16,0),Vector2(0,16),Vector2(0,-16)]:
					submerged = submerged and is_water(point+offset)
				if not submerged: continue
				var query := PhysicsShapeQueryParameters2D.new()
				query.shape = _body_shape
				query.collision_mask = 2
				query.exclude = water_exclusions()
				query.transform = Transform2D(0,center+Vector2(0,-10))
				query.motion = point-center
				var travel := region.get_world_2d().direct_space_state.cast_motion(query)
				if travel[0] < .999: continue
				query.transform.origin = point+Vector2(0,-10)
				query.motion = Vector2.ZERO
				if not region.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty(): continue
				points.append(point)
				if points.size() >= 4: break
			if points.size() >= 4: break
		if not points.is_empty():
			habitat.water_points = points
			habitat.radius = maxf(float(habitat.radius),330.0)

func _in_current_view(point: Vector2) -> bool:
	if not is_instance_valid(player):
		return false
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return point.distance_to(player.global_position) < 360.0
	var half_view := get_viewport_rect().size / camera.zoom / 2.0
	return Rect2(camera.get_screen_center_position() - half_view, half_view * 2.0).grow(96.0).has_point(point)

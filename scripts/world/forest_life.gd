extends Node2D
## Camera-local forest decoration. All points are global coordinates.
## configure() before add_child(); share shared_wind_material with Sprite2D plants.
## Provide open_area_test(global_point) for ground bird shadows; absent = no birds.
const WIND = preload("res://scripts/world/forest_wind.gdshader")
const STEP := 0.125
const BUCKET_SIZE := 256.0
const MAX_BUTTERFLIES := 4
const MAX_LEAVES := 8
const MAX_WILDLIFE := 1
const WILDLIFE_SCALE := {"squirrel": 1.0, "bird": 0.70}
const WILDLIFE_CLEARANCE := 180.0
const COLORS := [Color("f6e799"), Color("eef1cd"), Color("add9e8"), Color("e9b8ce")]

var shared_wind_material := ShaderMaterial.new()
var open_area_test: Callable
var _player: Node2D
var _flower_buckets: Dictionary = {}
var _leaf_buckets: Dictionary = {}
var _local_flowers: Array[Vector2] = []
var _local_leaf_sources: Array[Vector2] = []
var _butterflies: Array[Dictionary] = []
var _leaves: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _reduced_motion := false
var _age := 0.0
var _accumulator := 0.0
var _refresh := 0.0
var _view := Rect2()
var _bird_timer := 0.0
var _bird_remaining := 0.0
var _bird_start := Vector2.ZERO
var _bird_end := Vector2.ZERO
var _bird_events := 0
var _last_bird_interval := 0.0
var _updates := 0
var _ground_shadows: Node2D
var _materials: Dictionary = {}
var _environment = preload("res://scripts/world/environment_state.gd").new()
var _reactors: Array[Node2D] = []
var _reactor_history: Dictionary = {}
var _actor_data := PackedVector4Array()
var _butterfly_flees := 0
var _wildlife_buckets: Dictionary = {}
var _local_wildlife_points: Array[Vector2] = []
var _wildlife: Array[Dictionary] = []
var _wildlife_frames: Dictionary = {}
var _walkable_test: Callable
var _wildlife_respawn := 0.0
var _wildlife_species_index := 0
var _wildlife_anchors: Dictionary = {}
var _cloud_timer := 18.0
var _cloud_remaining := 0.0
var _cloud_origin := Vector2.ZERO

func _init() -> void:
	shared_wind_material.shader = WIND
	_materials["oak"] = shared_wind_material
	_rng.seed = 271026
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_environment_state(state: RefCounted) -> void:
	if state != null and state.has_method("snapshot"):
		_environment = state

func get_wind_material(kind: String = "oak") -> ShaderMaterial:
	if kind not in ["oak", "pine", "plant"]:
		kind = "oak"
	if not _materials.has(kind):
		var material := ShaderMaterial.new()
		material.shader = WIND
		material.set_shader_parameter("sway_rate", 1.9 if kind == "pine" else 1.6)
		material.set_shader_parameter("flexibility", 0.8 if kind == "pine" else 1.2)
		material.set_shader_parameter("plant_reaction", 1.0 if kind == "plant" else 0.0)
		_materials[kind] = material
		_update_wind()
	return _materials[kind]

func register_reactor(actor: Node2D) -> void:
	if is_instance_valid(actor) and actor != _player and actor not in _reactors:
		_reactors.append(actor)

func configure_wildlife(points: Array[Vector2], walkable_test: Callable) -> void:
	_walkable_test = walkable_test
	_wildlife_buckets.clear()
	for point in points:
		var key := Vector2i(floori(point.x / BUCKET_SIZE), floori(point.y / BUCKET_SIZE))
		if not _wildlife_buckets.has(key):
			_wildlife_buckets[key] = []
		_wildlife_buckets[key].append(point)
	_refresh = 0.0

func configure_wildlife_frames(species: String, frames: SpriteFrames) -> void:
	if species in ["squirrel", "bird"] and frames != null:
		_wildlife_frames[species] = frames
		var animation: StringName = &"idle" if frames.has_animation("idle") else frames.get_animation_names()[0]
		if frames.get_frame_count(animation)>0:
			var texture:=frames.get_frame_texture(animation,0)
			if texture!=null:
				var used:=texture.get_image().get_used_rect()
				_wildlife_anchors[species]=Vector2(used.position.x+used.size.x*.5,used.end.y)
		_refresh = 0.0

func configure(player: Node2D, flower_points: Array[Vector2], _water_points: Array[Vector2] = []) -> void:
	_player = player
	_flower_buckets.clear()
	for point in flower_points:
		var key := Vector2i(floori(point.x / BUCKET_SIZE), floori(point.y / BUCKET_SIZE))
		if not _flower_buckets.has(key):
			_flower_buckets[key] = []
		_flower_buckets[key].append(point)
	_butterflies.clear()
	_leaves.clear()
	_refresh = 0.0

func configure_leaf_sources(points: Array[Vector2]) -> void:
	_leaf_buckets.clear()
	for point in points:
		var key := Vector2i(floori(point.x / BUCKET_SIZE), floori(point.y / BUCKET_SIZE))
		if not _leaf_buckets.has(key):
			_leaf_buckets[key] = []
		_leaf_buckets[key].append(point)
	_refresh = 0.0

func _ready() -> void:
	z_index = 5
	_ground_shadows = Node2D.new()
	_ground_shadows.name = "BirdGroundShadow"
	_ground_shadows.z_as_relative = false
	_ground_shadows.z_index = -1
	_ground_shadows.draw.connect(_draw_bird_shadow)
	add_child(_ground_shadows)
	var settings := ConfigFile.new()
	if settings.load("user://presentation.cfg") == OK:
		_reduced_motion = bool(settings.get_value("accessibility", "reduce_motion", false))
	_refresh_local_effects()
	_schedule_bird()
	_update_wind()
	queue_redraw()
	_ground_shadows.queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if enabled:
		_bird_remaining = 0.0
		_cloud_remaining = 0.0
		_actor_data.clear()
		_leaves.clear()
	_refresh = 0.0
	_update_wind()
	queue_redraw()
	if is_instance_valid(_ground_shadows):
		_ground_shadows.queue_redraw()

func _process(delta: float) -> void:
	_accumulator += delta
	if _accumulator < STEP:
		return
	# Advance only once after a stall: avoid bursts of ambient events during catch-up.
	var elapsed := minf(_accumulator, 0.25)
	_accumulator = fmod(_accumulator, STEP)
	_updates += 1
	_refresh -= elapsed
	if _refresh <= 0.0:
		_refresh_local_effects()
		_refresh = 0.5
	if not _reduced_motion:
		_age += elapsed
		_update_reactors(elapsed)
		_step_butterflies(elapsed)
		_step_leaves(elapsed)
		_step_bird(elapsed)
		_step_wildlife(elapsed)
		_step_cloud(elapsed)
	_update_wind()
	queue_redraw()
	_ground_shadows.queue_redraw()

func _camera_rect() -> Rect2:
	var center := _player.global_position if is_instance_valid(_player) else global_position
	var size := get_viewport_rect().size
	var camera := get_viewport().get_camera_2d()
	if is_instance_valid(camera):
		center = camera.get_screen_center_position()
		size /= camera.zoom
	if size.x < 16.0 or size.y < 16.0:
		size = Vector2(960, 540)
	return Rect2(center - size * 0.5, size)

func _refresh_local_effects() -> void:
	_view = _camera_rect()
	var area := _view.grow(80.0)
	_local_flowers.clear()
	_local_leaf_sources.clear()
	_local_wildlife_points.clear()
	var first := Vector2i(floori(area.position.x / BUCKET_SIZE), floori(area.position.y / BUCKET_SIZE))
	var last := Vector2i(floori(area.end.x / BUCKET_SIZE), floori(area.end.y / BUCKET_SIZE))
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			for point: Vector2 in _flower_buckets.get(Vector2i(x, y), []):
				if area.has_point(point):
					_local_flowers.append(point)
			for point: Vector2 in _leaf_buckets.get(Vector2i(x, y), []):
				if area.has_point(point):
					_local_leaf_sources.append(point)
			for point: Vector2 in _wildlife_buckets.get(Vector2i(x, y), []):
				if area.has_point(point):
					_local_wildlife_points.append(point)
	for index in range(_butterflies.size() - 1, -1, -1):
		if not area.has_point(_butterflies[index].position) or _local_flowers.is_empty():
			_butterflies.remove_at(index)
	var desired := mini(MAX_BUTTERFLIES, _local_flowers.size() + 1) if not _local_flowers.is_empty() else 0
	while _butterflies.size() < desired:
		var target: Vector2 = _local_flowers[_rng.randi_range(0, _local_flowers.size() - 1)]
		_butterflies.append({"position": target, "start": target, "target": target, "time": 0.0,
			"duration": _rng.randf_range(1.5, 4.0), "landed": true, "phase": _rng.randf_range(0, TAU), "fade": 0.0,
			"flee_cooldown": 0.0, "size": _rng.randi_range(2, 3)})
	for index in range(_leaves.size() - 1, -1, -1):
		if not area.has_point(_leaves[index].start):
			_leaves.remove_at(index)
	for index in range(_wildlife.size() - 1, -1, -1):
		if not area.has_point(_wildlife[index].position):
			_remove_wildlife(index)
	if not _reduced_motion and _updates > 0:
		_populate_wildlife()

func _step_butterflies(delta: float) -> void:
	for butterfly in _butterflies:
		butterfly.flee_cooldown = maxf(0.0, float(butterfly.flee_cooldown) - delta)
		var threat := _nearest_threat(butterfly.position, 43.0)
		if threat != Vector2.INF and butterfly.flee_cooldown <= 0.0:
			var away := (butterfly.position as Vector2) - threat
			if away.length_squared() < 1.0:
				away = Vector2.RIGHT
			butterfly.start = butterfly.position
			butterfly.target = butterfly.position + away.normalized() * 82.0 + Vector2(0, -20)
			butterfly.time = 0.0
			butterfly.duration = 1.6
			butterfly.landed = false
			butterfly.flee_cooldown = 6.0
			_butterfly_flees += 1
		butterfly.fade = minf(1.0, float(butterfly.fade) + delta * 0.5)
		butterfly.time += delta
		if butterfly.time >= butterfly.duration:
			butterfly.time = 0.0
			# An escape destination is open air; route back to a flower before resting.
			butterfly.landed = not butterfly.landed and butterfly.target in _local_flowers
			butterfly.start = butterfly.position
			if butterfly.landed:
				butterfly.position = butterfly.target
				butterfly.duration = _rng.randf_range(2.0, 4.0)
			else:
				var nearby: Array[Vector2] = []
				for point in _local_flowers:
					if point.distance_squared_to(butterfly.position) < 240.0 * 240.0:
						nearby.append(point)
				if not nearby.is_empty():
					butterfly.target = nearby[_rng.randi_range(0, nearby.size() - 1)]
				elif not _local_flowers.is_empty():
					butterfly.target = _local_flowers[_rng.randi_range(0, _local_flowers.size() - 1)]
				butterfly.duration = _rng.randf_range(3.5, 6.0)
		if not butterfly.landed:
			var progress := clampf(float(butterfly.time) / float(butterfly.duration), 0.0, 1.0)
			var arc := Vector2(sin(progress * TAU + float(butterfly.phase)) * 15.0, -sin(progress * PI) * 24.0)
			butterfly.position = (butterfly.start as Vector2).lerp(butterfly.target, smoothstep(0.0, 1.0, progress)) + arc * sin(progress * PI)

func _step_leaves(delta: float) -> void:
	for index in range(_leaves.size() - 1, -1, -1):
		_leaves[index].age += delta
		if _leaves[index].age >= _leaves[index].duration:
			_leaves.remove_at(index)
	# On average one isolated leaf every two seconds, with an absolute pool cap.
	var wind := float(_environment.snapshot().wind)
	if not _local_leaf_sources.is_empty() and _leaves.size() < MAX_LEAVES and _rng.randf() < delta * (0.25 + wind * 0.25):
		var origin: Vector2 = _local_leaf_sources[_rng.randi_range(0, _local_leaf_sources.size() - 1)]
		_leaves.append({"start": origin, "age": 0.0, "duration": _rng.randf_range(4.0, 7.0), "phase": _rng.randf_range(0, TAU)})

func _schedule_bird() -> void:
	_last_bird_interval = _rng.randf_range(25.0, 60.0)
	_bird_timer = _last_bird_interval

func _step_bird(delta: float) -> void:
	_bird_remaining = maxf(0.0, _bird_remaining - delta)
	_bird_timer -= delta
	if _bird_timer > 0.0:
		return
	_schedule_bird()
	if not open_area_test.is_valid() or not bool(open_area_test.call(_view.get_center())):
		return
	_bird_start = _view.position + Vector2(-24, _view.size.y * _rng.randf_range(0.15, 0.65))
	_bird_end = _bird_start + Vector2(_view.size.x + 48.0, _view.size.y * 0.3)
	_bird_remaining = 3.5
	_bird_events += 1

func _update_wind() -> void:
	var conditions: Dictionary = _environment.snapshot()
	var gust := (0.85 + sin(_age * 0.11) * 0.3 + maxf(0.0, sin(_age * 0.37)) * 0.12) * float(conditions.wind)
	var uniforms := _actor_data.duplicate()
	uniforms.resize(8)
	for material: ShaderMaterial in _materials.values():
		material.set_shader_parameter("wind_time", _age)
		material.set_shader_parameter("wind_strength", 0.0 if _reduced_motion else gust)
		material.set_shader_parameter("wind_direction", Vector2(1.0, sin(_age * 0.07) * 0.3))
		material.set_shader_parameter("active_center", _view.get_center())
		material.set_shader_parameter("active_half_size", _view.size * 0.5)
		material.set_shader_parameter("reactor_count", 0 if _reduced_motion else _actor_data.size())
		material.set_shader_parameter("reactors", uniforms)

func debug_snapshot() -> Dictionary:
	var landed := 0
	for butterfly in _butterflies:
		if butterfly.landed:
			landed += 1
	var squirrels := 0
	for creature in _wildlife:
		squirrels += int(creature.species == "squirrel")
	return {"butterflies": _butterflies.size(), "landed": landed, "leaves": _leaves.size(),
		"reactors": _actor_data.size(), "butterfly_flees": _butterfly_flees,
		"wildlife": _wildlife.size(), "squirrels": squirrels, "wild_birds": _wildlife.size() - squirrels,
		"cloud_shadows": int(_cloud_remaining > 0.0), "environment": _environment.snapshot(),
		"birds": int(_bird_remaining > 0.0), "bird_events": _bird_events,
		"last_bird_interval": _last_bird_interval, "animation_time": _age,
		"updates": _updates, "local_flowers": _local_flowers.size(), "reduced_motion": _reduced_motion}

func _draw_bird_shadow() -> void:
	if _cloud_remaining > 0.0:
		var progress := 1.0 - _cloud_remaining / 18.0
		var center := to_local(_cloud_origin + Vector2(progress * 420.0, progress * 80.0)).round()
		var opacity := sin(progress * PI) * 0.035
		# Broad, stepped silhouette, subtle enough to retain ground readability.
		for band in 5:
			var width := 220.0 - absf(float(band) - 2.0) * 35.0
			_ground_shadows.draw_rect(Rect2(center + Vector2(-width * 0.5, band * 20.0), Vector2(width, 20)), Color(0.08, 0.15, 0.20, opacity))
	if _bird_remaining > 0.0:
		var progress := 1.0 - _bird_remaining / 3.5
		var global_point := _bird_start.lerp(_bird_end, progress)
		if not open_area_test.is_valid() or not bool(open_area_test.call(global_point)):
			return
		var point := to_local(global_point).round()
		var shade := Color(0.10, 0.16, 0.19, sin(progress * PI) * 0.16)
		_ground_shadows.draw_rect(Rect2(point + Vector2(-2, -4), Vector2(4, 11)), shade)
		var lift := roundf(sin(_age * 6.0) * 3.0)
		for side in [-1.0, 1.0]:
			_ground_shadows.draw_rect(Rect2(point + Vector2(side * 5.0 - 3.0, lift), Vector2(6, 3)), shade)
			_ground_shadows.draw_rect(Rect2(point + Vector2(side * 10.0 - 2.0, lift - 2.0), Vector2(4, 2)), shade)

func _draw() -> void:
	for leaf in _leaves:
		var progress := float(leaf.age) / float(leaf.duration)
		var at := to_local(leaf.start + Vector2(progress * 40.0 + sin(progress * TAU + float(leaf.phase)) * 9.0, progress * 60.0)).round()
		var tint := Color(0.69, 0.71, 0.32, sin(progress * PI) * 0.65)
		draw_rect(Rect2(at, Vector2(3, 2)), tint)
		draw_rect(Rect2(at + Vector2(1, -1), Vector2(2, 3)), tint)
	for index in _butterflies.size():
		var butterfly: Dictionary = _butterflies[index]
		var point := to_local(butterfly.position).round()
		var wings := 1.0 if _reduced_motion else (float(butterfly.size) if sin(_age * (2.0 if butterfly.landed else 15.0) + float(butterfly.phase)) > 0.0 else 1.0)
		var tint: Color = COLORS[index % COLORS.size()]
		tint.a = 1.0 if _reduced_motion else float(butterfly.fade)
		draw_rect(Rect2(point + Vector2(-wings - 1, -1), Vector2(wings, 3)), tint)
		draw_rect(Rect2(point + Vector2(1, -1), Vector2(wings, 3)), tint)
		draw_rect(Rect2(point, Vector2(1, 3)), Color(0.25, 0.27, 0.19, tint.a))

func _update_reactors(delta: float) -> void:
	_actor_data.clear()
	var active: Array[Node2D] = []
	if is_instance_valid(_player):
		active.append(_player)
	for index in range(_reactors.size() - 1, -1, -1):
		if not is_instance_valid(_reactors[index]) or _reactors[index].is_queued_for_deletion():
			_reactors.remove_at(index)
	for actor in _reactors:
		if _view.grow(80).has_point(actor.global_position):
			active.append(actor)
	var current: Dictionary = {}
	for actor in active:
		if _actor_data.size() >= 8:
			break
		var id := actor.get_instance_id()
		var point := actor.global_position
		var previous: Dictionary = _reactor_history.get(id, {"position": point, "impulse": 0.0})
		var speed := point.distance_to(previous.position) / maxf(delta, 0.001)
		var impulse := maxf(move_toward(float(previous.impulse), 0.0, delta * 1.6), clampf(speed / 70.0, 0.0, 1.0))
		current[id] = {"position": point, "impulse": impulse}
		_actor_data.append(Vector4(point.x, point.y - 6.0, impulse, 0.0))
	_reactor_history = current

func _nearest_threat(point: Vector2, radius: float) -> Vector2:
	var nearest := Vector2.INF
	var distance := radius * radius
	for actor in _actor_data:
		var at := Vector2(actor.x, actor.y)
		var candidate := at.distance_squared_to(point)
		if candidate < distance:
			nearest = at
			distance = candidate
	return nearest

func _step_cloud(delta: float) -> void:
	_cloud_remaining = maxf(0.0, _cloud_remaining - delta)
	_cloud_timer -= delta
	if _cloud_timer > 0.0:
		return
	_cloud_timer = _rng.randf_range(45.0, 90.0)
	if _environment.snapshot().period == "night":
		return
	_cloud_origin = _view.position + Vector2(_view.size.x * 0.18, _view.size.y * _rng.randf_range(0.15, 0.6))
	_cloud_remaining = 18.0

func _valid_ground(point: Vector2) -> bool:
	return _walkable_test.is_valid() and bool(_walkable_test.call(point))

func _populate_wildlife() -> void:
	if _wildlife.size()>=MAX_WILDLIFE or _wildlife_respawn > 0.0 or _local_wildlife_points.is_empty() or not _walkable_test.is_valid():
		return
	_wildlife_respawn = _rng.randf_range(22.0,38.0)
	var order: Array=["squirrel","bird"] if _wildlife_species_index%2==0 else ["bird","squirrel"]
	for species: String in order:
		if _wildlife.size()>=MAX_WILDLIFE:break
		if not _wildlife_frames.has(species):
			continue
		var existing := 0
		for creature in _wildlife:
			existing += int(creature.species == species)
		for slot in range(existing, 1):
			for attempt in 12:
				var anchor: Vector2 = _local_wildlife_points[_rng.randi_range(0, _local_wildlife_points.size() - 1)]
				var at := anchor + Vector2.from_angle(_rng.randf_range(0, TAU)) * _rng.randf_range(12.0, 50.0)
				if not _valid_ground(at) or _nearest_threat(at, WILDLIFE_CLEARANCE) != Vector2.INF:
					continue
				var sprite := Sprite2D.new()
				sprite.name = "Ambient_" + species
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.scale=Vector2.ONE*float(WILDLIFE_SCALE[species])
				# Ground creatures sort with props even though their shared manager draws overhead effects.
				get_parent().add_child(sprite)
				sprite.set_process(false)
				var record := {"species": species, "position": at, "anchor": anchor, "target": at,
					"state": "rest", "remaining": _rng.randf_range(1.5, 4.0), "age": _rng.randf_range(0, 10),
					"sprite": sprite, "direction": Vector2.RIGHT}
				_wildlife.append(record)
				_wildlife_species_index+=1
				_render_wildlife(record)
				break

func _step_wildlife(delta: float) -> void:
	_wildlife_respawn = maxf(0.0, _wildlife_respawn - delta)
	for index in range(_wildlife.size() - 1, -1, -1):
		var creature := _wildlife[index]
		creature.age += delta
		creature.remaining -= delta
		var threat := _nearest_threat(creature.position, 76.0)
		if threat != Vector2.INF and creature.state not in ["flee", "fly"]:
			var away := (creature.position as Vector2) - threat
			creature.direction = away.normalized() if away.length_squared() > 1 else Vector2.RIGHT
			creature.state = "fly" if creature.species == "bird" else "flee"
			creature.remaining = 2.8 if creature.species == "bird" else 1.5
		if creature.state == "fly":
			creature.position += (creature.direction as Vector2) * delta * 125.0 + Vector2(0, -24.0) * delta
			if creature.remaining <= 0.0:
				_remove_wildlife(index)
				continue
		elif creature.state == "flee":
			_move_wildlife(creature, (creature.direction as Vector2) * delta * 65.0)
			if creature.remaining <= 0.0:
				creature.state = "rest"
				creature.remaining = _rng.randf_range(3.0, 6.0)
		elif creature.state == "forage":
			var offset := (creature.target as Vector2) - (creature.position as Vector2)
			var speed := 24.0 if creature.species == "squirrel" else 32.0
			if offset.length() <= 3.0 or creature.remaining <= 0.0:
				creature.state = "rest"
				creature.remaining = _rng.randf_range(1.5, 4.0)
			else:
				creature.direction = offset.normalized()
				_move_wildlife(creature, offset.limit_length(speed * delta))
		elif creature.remaining <= 0.0:
			creature.target = creature.anchor + Vector2.from_angle(_rng.randf_range(0, TAU)) * _rng.randf_range(12.0, 75.0)
			creature.state = "forage"
			creature.remaining = _rng.randf_range(2.0, 4.0)
		_render_wildlife(creature)

func _move_wildlife(creature: Dictionary, movement: Vector2) -> void:
	var at: Vector2 = creature.position
	# Short subdivisions protect narrow colliders even during a capped slow frame.
	var steps := maxi(1, ceili(movement.length() / 3.0))
	for step in steps:
		var candidate := at + movement / float(steps)
		if not _valid_ground(candidate):
			creature.state = "rest"
			creature.remaining = 2.0
			break
		at = candidate
	creature.position = at

func _render_wildlife(creature: Dictionary) -> void:
	var sprite: Sprite2D = creature.sprite
	var frames: SpriteFrames = _wildlife_frames[creature.species]
	var desired := "idle" if creature.state == "rest" else "walk"
	if creature.state == "fly" and frames.has_animation("fly"):
		desired = "fly"
	if not frames.has_animation(desired):
		desired = "default" if frames.has_animation("default") and frames.get_frame_count("default") > 0 else str(frames.get_animation_names()[0])
	var count := frames.get_frame_count(desired)
	if count > 0:
		var frame := int(float(creature.age) * frames.get_animation_speed(desired)) % count
		sprite.texture = frames.get_frame_texture(desired, frame)
		if sprite.texture != null:
			var anchor:Vector2=_wildlife_anchors.get(creature.species,Vector2(sprite.texture.get_width()*.5,sprite.texture.get_height()))
			if (creature.direction as Vector2).x<0:anchor.x=sprite.texture.get_width()-anchor.x
			sprite.offset = sprite.texture.get_size()*.5-anchor
	sprite.global_position = (creature.position as Vector2).round()
	sprite.flip_h = (creature.direction as Vector2).x < 0
	if creature.species == "bird" and creature.state == "forage":
		sprite.offset.y -= maxf(0.0, sin(float(creature.age) * 13.0)) * 3.0

func _remove_wildlife(index: int) -> void:
	if is_instance_valid(_wildlife[index].sprite):
		_wildlife[index].sprite.queue_free()
	_wildlife.remove_at(index)

func wildlife_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for creature in _wildlife:
		result.append({"species": creature.species, "position": creature.position, "state": creature.state})
	return result

func _exit_tree() -> void:
	# Sprites are siblings for Y-sort; the manager still owns their lifecycle.
	for creature in _wildlife:
		if is_instance_valid(creature.sprite):
			creature.sprite.queue_free()
	_wildlife.clear()

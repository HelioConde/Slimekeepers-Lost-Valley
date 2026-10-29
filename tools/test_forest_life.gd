extends SceneTree
## Real-node checks: budgets, landing, camera locality, bird gating and reduced motion.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists("res://scripts/world/forest_life.gd"):
		_check(false, "Forest life controller exists")
		_finish()
		return
	var script = load("res://scripts/world/forest_life.gd")
	var life = script.new()
	var player := Node2D.new()
	root.add_child(player)
	player.position = Vector2(1000, 1000)
	var flowers: Array[Vector2] = [Vector2(980, 970), Vector2(1040, 1010), Vector2(1100, 1050), Vector2(3100, 3020)]
	life.configure(player, flowers)
	var leaf_sources: Array[Vector2] = [Vector2(1020, 1020)]
	life.configure_leaf_sources(leaf_sources)
	life.open_area_test = func(_point: Vector2) -> bool: return true
	root.add_child(life)
	var settings := ConfigFile.new()
	var expected_reduced := false
	if settings.load("user://presentation.cfg") == OK:
		expected_reduced = bool(settings.get_value("accessibility", "reduce_motion", false))
	_check(life.debug_snapshot().reduced_motion == expected_reduced, "Controller reads the existing accessibility preference")
	life.set_reduced_motion(false)
	life.set_process(false)
	var initial_updates: int = life.debug_snapshot().updates
	for i in 5:
		life._process(0.02)
	_check(life.debug_snapshot().updates == initial_updates, "Ambient simulation does not update before 125ms")
	life._process(0.03)
	_check(life.debug_snapshot().updates == initial_updates + 1, "Ambient simulation advances after its 8Hz interval")
	var snapshot: Dictionary = life.debug_snapshot()
	_check(snapshot.butterflies >= 2 and snapshot.butterflies <= 5, "Flower patch receives a bounded local population")
	var landed := false
	var saw_leaves := false
	var budgets_respected := true
	for i in 4800:
		life._process(0.125)
		snapshot = life.debug_snapshot()
		landed = landed or snapshot.landed > 0
		saw_leaves = saw_leaves or snapshot.leaves > 0
		if snapshot.butterflies > 5 or snapshot.leaves > 10 or snapshot.birds > 1:
			budgets_respected = false
			break
	_check(budgets_respected, "Effect budgets remain bounded for ten simulated minutes")
	_check(saw_leaves, "Trees emit occasional leaves")
	_check(landed, "Butterflies land during a flight cycle")
	_check(snapshot.bird_events >= 8 and snapshot.bird_events <= 24, "Bird events obey 25–60 second cadence")
	_check(snapshot.last_bird_interval >= 25.0 and snapshot.last_bird_interval <= 60.0, "Random bird interval remains in range")
	var before_events: int = snapshot.bird_events
	life.open_area_test = func(_point: Vector2) -> bool: return false
	for i in 640:
		life._process(0.125)
	_check(life.debug_snapshot().bird_events == before_events, "Dense forest suppresses bird shadows")
	player.position = Vector2(6000, 6000)
	for i in 16:
		life._process(0.125)
	_check(life.debug_snapshot().butterflies == 0, "No butterflies remain in a flowerless active region")
	_check(life.debug_snapshot().leaves == 0, "Leaves do not follow the camera into a region without source trees")
	player.position = Vector2(1000, 1000)
	for i in 16:
		life._process(0.125)
	_check(life.debug_snapshot().butterflies >= 2, "Re-entering flowers reuses local population")
	life.set_reduced_motion(true)
	var frozen_time: float = life.debug_snapshot().animation_time
	for i in 64:
		life._process(0.125)
	snapshot = life.debug_snapshot()
	_check(snapshot.animation_time == frozen_time and snapshot.birds == 0 and snapshot.leaves == 0, "Reduced motion freezes animation and disables moving particles")
	_check(is_zero_approx(float(life.shared_wind_material.get_shader_parameter("wind_strength"))), "Reduced motion disables shared vegetation wind")
	var processing_children := 0
	for child in life.get_children():
		processing_children += int(child.is_processing())
	_check(processing_children == 0, "Effects require no processing child nodes")
	if DisplayServer.get_name() != "headless":
		await _check_native_shader(life.shared_wind_material, life.get_wind_material("plant"))
	life.free()
	player.free()
	_finish()

func _check_native_shader(wind: ShaderMaterial, plant: ShaderMaterial) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(64, 64)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var source := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	source.fill(Color(0.5, 0.75, 0.3, 1.0))
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(source)
	sprite.centered = false
	sprite.position = Vector2(16, 16)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material = wind
	viewport.add_child(sprite)
	wind.set_shader_parameter("active_center", Vector2(32, 32))
	wind.set_shader_parameter("wind_strength", 0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var still := viewport.get_texture().get_image()
	_check(absf(still.get_pixel(25, 25).r - 0.5) < 0.03, "Wind shader preserves original sprite colors")
	wind.set_shader_parameter("wind_strength", 1.5)
	wind.set_shader_parameter("wind_time", 0.6)
	await process_frame
	await RenderingServer.frame_post_draw
	var moved := viewport.get_texture().get_image()
	var trunk_unchanged := true
	for y in range(40, 48):
		for x in range(16, 48):
			trunk_unchanged = trunk_unchanged and still.get_pixel(x, y).is_equal_approx(moved.get_pixel(x, y))
	_check(trunk_unchanged, "Native rendered lower trunk remains pixel-identical under wind")
	_check(still.get_pixel(16, 17).a > 0.9 and moved.get_pixel(16, 17).a < 0.1, "Native rendered canopy shifts by a crisp pixel")
	sprite.material = plant
	plant.set_shader_parameter("active_center", Vector2(32, 32))
	plant.set_shader_parameter("wind_strength", 0.0)
	var actors := PackedVector4Array([Vector4(10, 16, 1, 0)])
	actors.resize(8)
	plant.set_shader_parameter("reactor_count", 1)
	plant.set_shader_parameter("reactors", actors)
	await process_frame
	await RenderingServer.frame_post_draw
	var brushed := viewport.get_texture().get_image()
	_check(brushed.get_pixel(16, 17).a < 0.1, "Nearby creature bends plant tips even when wind is calm")
	_check(brushed.get_pixel(16, 46).is_equal_approx(still.get_pixel(16, 46)), "Plant interaction retains fixed ground contact")
	plant.set_shader_parameter("reactor_count", 0)
	await process_frame
	await RenderingServer.frame_post_draw
	var relaxed := viewport.get_texture().get_image()
	_check(relaxed.get_pixel(16, 17).a > 0.9, "Disabling impulses restores the plant silhouette")
	viewport.free()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _finish() -> void:
	print("FOREST_LIFE: %d checks; %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)

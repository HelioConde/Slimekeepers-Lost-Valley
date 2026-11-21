extends GdUnitTestSuite

## Cachoeira viva: névoa e respingos no impacto, cintilação mágica só à noite,
## brilho do véu na cor da luz do horário e respeito a "reduzir movimento".

const Life := preload("res://scripts/world/waterfall_life.gd")


func _fall() -> Array:
	var fall: Node2D = auto_free(Node2D.new())
	fall.position = Vector2(640, 650)
	add_child(fall)
	var cascade := Sprite2D.new()
	cascade.name = "Cascade"
	cascade.texture = load("res://assets/world/valley/waterfall_medium.png")
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/world/valley_cascade.gdshader")
	cascade.material = material
	fall.add_child(cascade)
	var life: Node2D = Life.new()
	life.name = "LivingFoam"
	var shores: Array[PackedVector2Array] = [PackedVector2Array([Vector2(500, 500), Vector2(780, 500), Vector2(780, 900), Vector2(500, 900)])]
	life.shores = shores
	fall.add_child(life)
	return [fall, life, material]


func test_impact_has_mist_and_spray_in_pixel_art() -> void:
	var parts := _fall()
	await await_idle_frame()
	var life: Node2D = parts[1]
	for particles: CPUParticles2D in [life.impact_mist(), life.impact_spray()]:
		assert_object(particles).is_not_null()
		assert_int(particles.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)
		assert_bool(particles.emitting).is_true()
		# Na base da queda, onde a água bate.
		assert_float(particles.position.y).is_greater(80.0)
	assert_int(life.impact_mist().amount).is_less_equal(16)


func test_magic_sparkles_only_at_night() -> void:
	var parts := _fall()
	await await_idle_frame()
	var life: Node2D = parts[1]
	life.apply_time(12 * 60)
	assert_bool(life.night_sparkles().emitting).is_false()
	life.apply_time(22 * 60)
	assert_bool(life.night_sparkles().emitting).is_true()
	var color: Color = life.night_sparkles().color_ramp.sample(0.4)
	assert_float(color.b).is_greater(color.r)


func test_cascade_glint_follows_time_of_day() -> void:
	var parts := _fall()
	await await_idle_frame()
	var life: Node2D = parts[1]
	var material: ShaderMaterial = parts[2]
	life.apply_time(12 * 60)
	var noon: Color = material.get_shader_parameter("glint_color")
	life.apply_time(22 * 60)
	var night: Color = material.get_shader_parameter("glint_color")
	assert_float(night.b - night.r).is_greater(noon.b - noon.r)
	assert_float(material.get_shader_parameter("glint_strength")).is_greater(0.0)


func test_reduced_motion_stops_particles() -> void:
	var parts := _fall()
	await await_idle_frame()
	var life: Node2D = parts[1]
	life.set_reduced_motion(true)
	assert_bool(life.impact_mist().emitting).is_false()
	assert_bool(life.impact_spray().emitting).is_false()

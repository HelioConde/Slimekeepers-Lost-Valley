extends GdUnitTestSuite

## Lago encantado (V9): plantas mágicas, reflexos, luz e névoa só à noite;
## margem sem o anel escuro; a luz do lago não ilumina a própria água.

const Magic := preload("res://scripts/world/pond_magic.gd")
const WATER_SHADER := preload("res://scripts/world/spring_water.gdshader")


func _spring() -> Array:
	var root: Node2D = auto_free(Node2D.new())
	add_child(root)
	var spring := Node2D.new()
	root.add_child(spring)
	var pool := Node2D.new()
	pool.name = "Pool"
	spring.add_child(pool)
	for ring in ["BankShadow", "StoneBank", "WetBank"]:
		var polygon := Polygon2D.new()
		polygon.name = ring
		pool.add_child(polygon)
	var water := Polygon2D.new()
	water.name = "Water"
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	water.material = material
	pool.add_child(water)
	var decorations := Node2D.new()
	root.add_child(decorations)
	var magic: Node2D = Magic.new()
	magic.setup(spring, decorations)
	spring.add_child(magic)
	return [magic, pool, water, decorations]


func test_magic_only_at_night_and_moon_follows_time() -> void:
	var rig := _spring()
	var magic: Node2D = rig[0]
	var water: Polygon2D = rig[2]
	magic.apply_time(12 * 60, 0.1)
	assert_float(magic.light.energy).is_equal(0.0)
	for item in magic.glows: assert_float(item.modulate.a).is_equal(0.0)
	for p in magic.emitters: assert_bool(p.emitting).is_false()
	assert_float(water.material.get_shader_parameter("moon_strength")).is_equal(0.0)
	assert_float(magic.moon.modulate.a).is_equal(0.0)
	magic.apply_time(23 * 60, 0.1)
	assert_float(magic.light.energy).is_greater(0.0)
	for p in magic.emitters: assert_bool(p.emitting).is_true()
	assert_float(water.material.get_shader_parameter("moon_strength")).is_equal(1.0)
	assert_float(magic.moon.modulate.a).is_greater(0.4)


func test_few_particles_per_plant_with_varied_behaviour() -> void:
	var magic: Node2D = _spring()[0]
	var lifetimes := {}
	for p in magic.emitters:
		assert_int(p.amount).is_less_equal(4)
		lifetimes[p.lifetime] = true
	assert_int(lifetimes.size()).is_equal(3)


func test_bank_ring_hidden_and_water_not_lit_by_pond_light() -> void:
	var rig := _spring()
	var pool: Node2D = rig[1]
	assert_bool(pool.get_node("BankShadow").visible).is_false()
	assert_bool(pool.get_node("StoneBank").visible).is_false()
	assert_int((rig[2] as Polygon2D).light_mask & rig[0].light.range_item_cull_mask).is_equal(0)
	assert_int((rig[3] as Node2D).get_child_count()).is_equal(Magic.REED_SPOTS.size())

extends GdUnitTestSuite

## AmbientLights: fontes de luz locais (fogueira, cogumelos luminosos, visibilidade
## do jogador) que acompanham o GameClock sem saltos e com quantidade limitada.

const Lights := preload("res://scripts/world/ambient_lights.gd")
const Station := preload("res://scripts/world/valley_cooking_station.gd")
const GLOW := "res://assets/world/forest/mushroom_glow.png"


func _rig_in_region(with_station: bool, glow_count: int) -> Array:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	var player := Node2D.new()
	player.name = "Player"
	region.add_child(player)
	if with_station:
		region.add_child(Station.new())
	for i in glow_count:
		var glow := Sprite2D.new()
		glow.texture = load(GLOW)
		glow.position = Vector2(40 * i, 0)
		region.add_child(glow)
	var holder := Node2D.new()
	region.add_child(holder)
	var rig: Node2D = Lights.new()
	holder.add_child(rig)
	return [region, rig]


func test_night_factor_is_zero_by_day_full_at_night_and_continuous() -> void:
	assert_float(Lights.night_factor(12 * 60)).is_equal(0.0)
	assert_float(Lights.night_factor(9 * 60)).is_equal(0.0)
	assert_float(Lights.night_factor(23 * 60)).is_equal(1.0)
	assert_float(Lights.night_factor(2 * 60)).is_equal(1.0)
	var dusk := Lights.night_factor(18 * 60 + 30)
	assert_float(dusk).is_greater(0.0)
	assert_float(dusk).is_less(1.0)
	for minute in range(0, 1441):
		var step := absf(Lights.night_factor(minute) - Lights.night_factor(minute + 1))
		assert_float(step).override_failure_message("salto em %d" % minute).is_less(0.02)


func test_campfire_gets_warm_light_and_fire_only_after_dusk() -> void:
	var rig: Node2D = _rig_in_region(true, 0)[1]
	await await_idle_frame()
	var light: PointLight2D = rig.campfire_lights()[0]
	assert_object(light).is_not_null()
	assert_float(light.color.r).is_greater(light.color.b)
	rig.apply_time(12 * 60, 0.0)
	assert_float(light.energy).is_equal(0.0)
	assert_bool(rig.campfire_fire()[0].emitting).is_false()
	rig.apply_time(22 * 60, 0.0)
	assert_float(light.energy).is_greater(0.5)
	assert_bool(rig.campfire_fire()[0].emitting).is_true()


func test_flicker_is_gentle() -> void:
	var rig: Node2D = _rig_in_region(true, 0)[1]
	await await_idle_frame()
	var light: PointLight2D = rig.campfire_lights()[0]
	var low := 99.0
	var high := 0.0
	for i in 120:
		rig.apply_time(22 * 60, 1.0 / 30.0)
		low = minf(low, light.energy)
		high = maxf(high, light.energy)
	assert_float(high - low).is_less(0.35)
	assert_float(low).is_greater(0.5)


func test_glow_lights_are_capped() -> void:
	var rig: Node2D = _rig_in_region(false, 40)[1]
	await await_idle_frame()
	assert_int(rig.glow_lights().size()).is_less_equal(Lights.MAX_GLOW_LIGHTS)
	assert_int(rig.glow_lights().size()).is_greater(0)


func test_player_visibility_light_only_at_night_and_casts_no_shadow() -> void:
	var rig: Node2D = _rig_in_region(false, 0)[1]
	await await_idle_frame()
	var light: PointLight2D = rig.player_light()
	rig.apply_time(12 * 60, 0.0)
	assert_float(light.energy).is_equal(0.0)
	rig.apply_time(1 * 60, 0.0)
	assert_float(light.energy).is_greater(0.0)
	assert_bool(light.shadow_enabled).is_false()


func test_light_texture_is_banded_for_pixel_art() -> void:
	var texture := Lights.banded_light_texture(64)
	var gradient: Gradient = texture.gradient
	assert_int(gradient.interpolation_mode).is_equal(Gradient.GRADIENT_INTERPOLATE_CONSTANT)
	assert_int(gradient.get_point_count()).is_greater_equal(4)


func test_fireflies_follow_player_glow_unshaded_and_only_at_night() -> void:
	var rig: Node2D = _rig_in_region(false, 0)[1]
	await await_idle_frame()
	var fireflies: CPUParticles2D = rig.fireflies()
	assert_object(fireflies).is_not_null()
	assert_bool(fireflies.local_coords).is_false()
	var material := fireflies.material as CanvasItemMaterial
	assert_int(material.light_mode).is_equal(CanvasItemMaterial.LIGHT_MODE_UNSHADED)
	assert_int(material.blend_mode).is_equal(CanvasItemMaterial.BLEND_MODE_ADD)
	rig.apply_time(12 * 60, 0.0)
	assert_bool(fireflies.emitting).is_false()
	rig.apply_time(23 * 60, 0.0)
	assert_bool(fireflies.emitting).is_true()


func test_firefly_density_depends_on_region_identity() -> void:
	assert_int(Lights.firefly_amount("FlorestaDoDespertarV2")).is_greater(Lights.firefly_amount("ClareiraDoDespertar"))
	assert_int(Lights.firefly_amount("ValeDasNascentes")).is_greater(Lights.firefly_amount("ClareiraDoDespertar"))
	assert_int(Lights.firefly_amount("ClareiraDoDespertar")).is_greater(0)

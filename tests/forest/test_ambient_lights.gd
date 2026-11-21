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


func test_sun_dapples_light_the_ground_by_day_only_and_follow_sun_direction() -> void:
	var rig: Node2D = _rig_in_region(false, 0)[1]
	await await_idle_frame()
	var dapples: Array = rig.dapples()
	assert_int(dapples.size()).is_equal(Lights.MAX_DAPPLES)
	rig.apply_time(9 * 60, 0.0)
	assert_bool(dapples[0].visible).is_true()
	var morning_texture: Texture2D = dapples[0].texture
	assert_float(rig.dapple_strength(0)).is_greater(0.05)
	rig.apply_time(16 * 60, 0.0)
	# A direção do sol é desenhada nos pixels (sem girar o sprite e quebrar a grade).
	assert_object(dapples[0].texture).is_not_same(morning_texture)
	assert_float(dapples[0].rotation).is_equal(0.0)
	rig.apply_time(23 * 60, 0.0)
	assert_float(rig.dapple_strength(0)).is_equal(0.0)
	assert_bool(dapples[0].visible).is_false()


func test_sun_dapples_are_crisp_additive_ground_sprites() -> void:
	var rig: Node2D = _rig_in_region(false, 0)[1]
	await await_idle_frame()
	rig.apply_time(9 * 60, 0.0)
	for dapple in rig.dapples():
		assert_object(dapple).is_instanceof(Sprite2D)
		assert_bool(dapple.top_level).is_true()
		assert_bool(dapple.z_as_relative).is_false()
		assert_int(dapple.z_index).is_equal(-1)
		assert_int(dapple.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)
		assert_int((dapple.material as CanvasItemMaterial).blend_mode).is_equal(CanvasItemMaterial.BLEND_MODE_ADD)
		# Escala inteira: 1 pixel da textura = 2 px do mundo, como a arte do jogo.
		assert_vector(dapple.scale).is_equal(Vector2(Lights.DAPPLE_PIXEL, Lights.DAPPLE_PIXEL))
		assert_object(dapple.get_node_or_null("SunbeamDust")).is_not_null()


func test_dapple_pattern_is_small_leaf_gaps_with_hard_bands() -> void:
	var image := Lights.dapple_image(1, Vector2(-1.0, 0.5))
	var lit := 0
	for y in image.get_height():
		for x in image.get_width():
			var a := image.get_pixel(x, y).a
			assert_bool(is_zero_approx(a) or is_equal_approx(a, 1.0) or absf(a - 0.5) < 0.01) 				.override_failure_message("alfa intermediário %f" % a).is_true()
			if a > 0.0: lit += 1
	var coverage := float(lit) / float(image.get_width() * image.get_height())
	assert_float(coverage).is_between(0.03, 0.3)


func test_dapple_gaps_stretch_along_low_sun() -> void:
	var low := Lights.dapple_image(2, Vector2(1.2, 0.0)).get_used_rect()
	var high := Lights.dapple_image(2, Vector2(0.05, 0.0)).get_used_rect()
	assert_int(low.size.x).is_greater(high.size.x)


func test_dapples_sway_one_or_two_pixels_around_world_home() -> void:
	var rig: Node2D = _rig_in_region(false, 0)[1]
	await await_idle_frame()
	rig.apply_time(10 * 60, 0.0)
	var dapple: Sprite2D = rig.dapples()[0]
	var home: Vector2 = dapple.get_meta("home")
	for i in 60:
		rig.apply_time(10 * 60, 0.1)
		assert_float(dapple.global_position.distance_to(home)).is_less_equal(2.9)
		assert_vector(dapple.global_position).is_equal(dapple.global_position.round())


func test_motes_change_color_with_period_and_rest_at_deep_night() -> void:
	var rig: Node2D = _rig_in_region(false, 0)[1]
	await await_idle_frame()
	var motes: CPUParticles2D = rig.motes()
	rig.apply_time(9 * 60, 0.0)
	var morning: Color = motes.color
	assert_bool(motes.emitting).is_true()
	rig.apply_time(18 * 60 + 40, 0.0)
	assert_float(motes.color.b).is_greater(morning.b)
	rig.apply_time(1 * 60, 0.0)
	assert_bool(motes.emitting).is_false()


func test_fireflies_start_at_dusk() -> void:
	var rig: Node2D = _rig_in_region(false, 0)[1]
	await await_idle_frame()
	rig.apply_time(18 * 60 + 40, 0.0)
	assert_bool(rig.fireflies().emitting).is_true()


func test_fire_and_ice_slimes_emit_real_light() -> void:
	var parts := _rig_in_region(false, 0)
	var region: Node2D = parts[0]
	var rig: Node2D = parts[1]
	for id in ["brasinha", "gelito", "brotinho"]:
		var slime := AnimatedSprite2D.new()
		slime.sprite_frames = load("res://assets/slimes/bestiary/%s/%s_frames.tres" % [id, id])
		region.add_child(slime)
	await await_idle_frame()
	await await_idle_frame()
	var lights: Array = rig.slime_lights()
	assert_int(lights.size()).is_equal(2)
	rig.apply_time(22 * 60, 0.0)
	var warm: PointLight2D = lights.filter(func(l): return l.color.r > l.color.b)[0]
	var cold: PointLight2D = lights.filter(func(l): return l.color.b > l.color.r)[0]
	assert_float(warm.energy).is_greater(0.3)
	assert_float(cold.energy).is_greater(0.3)


func test_dapples_are_anchored_to_world_cells_not_the_camera() -> void:
	var a := Lights.dapple_homes(Vector2(1000, 800), Lights.MAX_DAPPLES)
	var b := Lights.dapple_homes(Vector2(1040, 830), Lights.MAX_DAPPLES)
	assert_array(a).is_equal(b)
	var far := Lights.dapple_homes(Vector2(1300, 800), Lights.MAX_DAPPLES)
	var shared := a.filter(func(p): return far.has(p))
	assert_int(shared.size()).is_greater(0)


func test_slime_halos_are_continuous_not_ringed() -> void:
	var parts := _rig_in_region(false, 0)
	var slime := AnimatedSprite2D.new()
	slime.sprite_frames = load("res://assets/slimes/bestiary/brasinha/brasinha_frames.tres")
	parts[0].add_child(slime)
	await await_idle_frame()
	await await_idle_frame()
	var gradient: Gradient = parts[1].slime_lights()[0].texture.gradient
	assert_int(gradient.interpolation_mode).is_not_equal(Gradient.GRADIENT_INTERPOLATE_CONSTANT)


func test_spots_are_classified_by_texture() -> void:
	assert_str(Lights.classify_spot("res://assets/world/valley/reeds.png")).is_equal("water")
	assert_str(Lights.classify_spot("res://assets/world/valley/lily_pad.png")).is_equal("water")
	assert_str(Lights.classify_spot("res://assets/sprites/objects/bush_small_compact_leafy_for/rotations/bush_small_compact_leafy_for.png")).is_equal("vegetation")
	assert_str(Lights.classify_spot("res://assets/world/forest/fern.png")).is_equal("vegetation")
	assert_str(Lights.classify_spot("res://assets/menu/environment/flowers.png")).is_equal("bloom")
	assert_str(Lights.classify_spot("res://assets/world/forest/mushroom_red.png")).is_equal("bloom")
	assert_str(Lights.classify_spot("res://assets/world/forest/pine_crisp.png")).is_equal("")


func test_special_blooms_are_rare_and_stable() -> void:
	var special := 0
	for x in 40:
		for y in 25:
			var at := Vector2(x * 37, y * 53)
			if Lights.is_special_bloom(at): special += 1
			assert_bool(Lights.is_special_bloom(at)).is_equal(Lights.is_special_bloom(at))
	assert_float(special / 1000.0).is_between(0.03, 0.2)


func _spot_rig() -> Array:
	var parts := _rig_in_region(false, 0)
	var region: Node2D = parts[0]
	for at in [Vector2(120, 0), Vector2(-260, 60), Vector2(0, 220)]:
		var bush := Sprite2D.new()
		bush.texture = load("res://assets/sprites/objects/bush_small_compact_leafy_for/rotations/bush_small_compact_leafy_for.png")
		bush.position = at
		region.add_child(bush)
	var reeds := Sprite2D.new()
	reeds.texture = load("res://assets/world/valley/reeds.png")
	reeds.position = Vector2(300, -150)
	region.add_child(reeds)
	for i in 120:
		var flower := Sprite2D.new()
		flower.texture = load("res://assets/menu/environment/flowers.png")
		flower.position = Vector2((i % 12) * 41 - 240, (i / 12) * 37 - 180)
		region.add_child(flower)
	return parts


func test_firefly_swarms_gather_at_vegetation_and_water_at_night_only() -> void:
	var rig: Node2D = _spot_rig()[1]
	await await_idle_frame()
	rig.apply_time(23 * 60, 0.0)
	var swarms: Array = rig.firefly_swarms()
	assert_int(swarms.size()).is_greater(0)
	var spots: Array = rig.spots("water") + rig.spots("vegetation")
	var placed := 0
	for swarm in swarms:
		if not swarm.visible: continue
		placed += 1
		assert_bool(swarm.emitting).is_true()
		var nearest := 9999.0
		for spot in spots: nearest = minf(nearest, swarm.global_position.distance_to(spot))
		assert_float(nearest).is_less(1.0)
	assert_int(placed).is_equal(4)
	# A margem d'água entra antes da vegetação comum.
	assert_bool(swarms.any(func(s): return s.visible and s.global_position == Vector2(300, -150))).is_true()
	rig.apply_time(12 * 60, 0.0)
	for swarm in swarms: assert_bool(swarm.emitting).is_false()


func test_magic_glints_sit_on_special_blooms_and_twinkle_rarely() -> void:
	var rig: Node2D = _spot_rig()[1]
	await await_idle_frame()
	var glints: Array = rig.magic_glints()
	assert_int(glints.size()).is_between(1, Lights.MAX_GLINTS)
	var blooms: Array = rig.spots("bloom")
	assert_int(blooms.size()).is_greater(0)
	assert_int(blooms.size()).is_less(60)
	var on_frames := 0
	var frames := 0
	for i in 200:
		rig.apply_time(21 * 60, 0.25)
		for glint in glints:
			if not glint.visible: continue
			frames += 1
			assert_bool(blooms.has(glint.global_position + Vector2(0, 8))).is_true()
			if glint.emitting: on_frames += 1
	assert_int(frames).is_greater(0)
	# Raros: piscam parte do tempo, nunca o tempo todo.
	assert_float(float(on_frames) / frames).is_between(0.1, 0.6)


func test_dapples_never_pop_inside_the_view_while_walking() -> void:
	var view := Vector2(600 + 60, 338 + 60)  # meia vista com zoom 0,8 + tamanho da mancha
	for step in 60:
		var c1 := Vector2(37 + step * 17, 900 + step * 9)
		var c2 := c1 + Vector2(17, 9)
		var h1 := Lights.dapple_homes(c1, Lights.MAX_DAPPLES, 0.7)
		var h2 := Lights.dapple_homes(c2, Lights.MAX_DAPPLES, 0.7)
		for home in h1 + h2:
			var d1 := (home - c1).abs()
			var d2 := (home - c2).abs()
			if d1.x < view.x and d1.y < view.y and d2.x < view.x and d2.y < view.y:
				assert_bool(h1.has(home) and h2.has(home)) 					.override_failure_message("mancha %s pisca ao andar de %s" % [home, c1]).is_true()


func test_valley_is_less_dappled_than_forest() -> void:
	assert_float(Lights.dapple_density("ValeDasNascentes")).is_less(Lights.dapple_density("FlorestaDoDespertarV2"))
	var forest := Lights.dapple_homes(Vector2(5000, 5000), 99, Lights.dapple_density("FlorestaDoDespertarV2")).size()
	var valley := Lights.dapple_homes(Vector2(5000, 5000), 99, Lights.dapple_density("ValeDasNascentes")).size()
	assert_int(valley).is_less(forest)


func test_player_gets_faint_light_only_inside_a_sun_dapple() -> void:
	var parts := _rig_in_region(false, 0)
	var rig: Node2D = parts[1]
	await await_idle_frame()
	rig.apply_time(10 * 60, 0.0)
	var player: Node2D = parts[0].get_node("Player")
	var light: PointLight2D = player.get_node("DappleLight")
	var home: Vector2 = rig.dapples()[0].get_meta("home")
	player.global_position = home
	rig.apply_time(10 * 60, 0.0)
	assert_float(light.energy).is_greater(0.05)
	player.global_position = home + Vector2(0, 9000)
	rig.apply_time(10 * 60, 0.0)
	player.global_position = home + Vector2(57, 41)
	rig.apply_time(10 * 60, 0.0)
	rig.apply_time(10 * 60, 0.0)
	var far_from_all := true
	for d in rig.dapples():
		if d.visible and (d.get_meta("home") as Vector2).distance_to(player.global_position) < Lights.DAPPLE_PLAYER_REACH: far_from_all = false
	if far_from_all:
		assert_float(light.energy).is_equal(0.0)


func test_campfire_light_is_smooth_local_and_without_rings() -> void:
	var rig: Node2D = _rig_in_region(true, 0)[1]
	await await_idle_frame()
	var light: PointLight2D = rig.campfire_lights()[0]
	var texture := light.texture as GradientTexture2D
	assert_int(texture.gradient.interpolation_mode).is_not_equal(Gradient.GRADIENT_INTERPOLATE_CONSTANT)
	# Raio em px do mundo: restrito ao entorno da fogueira.
	assert_float(texture.width * light.texture_scale * 0.5).is_less_equal(Lights.CAMPFIRE_RADIUS + 0.01)
	# Queda monotônica e rápida: metade do raio já bem mais fraca que o centro.
	var g := texture.gradient
	assert_float(g.sample(0.5).a).is_less(g.sample(0.0).a * 0.45)
	for i in 20:
		assert_float(g.sample(i / 20.0).a).is_greater_equal(g.sample((i + 1) / 20.0).a)


func test_campfire_grows_after_sunset_and_throws_embers() -> void:
	var rig: Node2D = _rig_in_region(true, 0)[1]
	await await_idle_frame()
	var light: PointLight2D = rig.campfire_lights()[0]
	rig.apply_time(18 * 60 + 30, 0.0)
	var dusk := light.energy
	rig.apply_time(22 * 60, 0.0)
	assert_float(dusk).is_less(light.energy * 0.7)
	var embers: CPUParticles2D = rig.campfire_embers()[0]
	assert_bool(embers.emitting).is_true()
	assert_int((embers.material as CanvasItemMaterial).blend_mode).is_equal(CanvasItemMaterial.BLEND_MODE_ADD)
	rig.apply_time(12 * 60, 0.0)
	assert_bool(embers.emitting).is_false()


func test_dapple_cutouts_vary_between_neighbours() -> void:
	var seen := {}
	for v in Lights.DAPPLE_VARIANTS:
		seen[hash(Lights.dapple_image(v, Vector2(-0.8, 0.45)).get_data())] = true
	assert_int(seen.size()).is_equal(Lights.DAPPLE_VARIANTS)
	var rig: Node2D = _rig_in_region(false, 0)[1]
	await await_idle_frame()
	rig.apply_time(9 * 60, 0.0)
	var textures := {}
	var visible := 0
	for dapple in rig.dapples():
		if dapple.visible:
			visible += 1
			textures[dapple.texture.get_instance_id()] = true
	assert_int(textures.size()).is_greater_equal(mini(visible, 6))


func test_glow_mushrooms_release_blue_green_spores_after_dusk() -> void:
	var rig: Node2D = _rig_in_region(false, 3)[1]
	await await_idle_frame()
	var spores: Array = rig.glow_spores()
	assert_int(spores.size()).is_equal(3)
	var first: CPUParticles2D = spores[0]
	var color: Color = first.color_ramp.sample(0.4)
	assert_float(color.g).is_greater(color.r)
	assert_float(color.b).is_greater(color.r)
	assert_int((first.material as CanvasItemMaterial).light_mode).is_equal(CanvasItemMaterial.LIGHT_MODE_UNSHADED)
	rig.apply_time(12 * 60, 0.0)
	assert_bool(first.emitting).is_false()
	rig.apply_time(22 * 60, 0.0)
	assert_bool(first.emitting).is_true()


func test_fireflies_wander_organically() -> void:
	var rig: Node2D = _spot_rig()[1]
	await await_idle_frame()
	var swarm: CPUParticles2D = rig.firefly_swarms()[0]
	assert_float(absf(swarm.orbit_velocity_min) + absf(swarm.orbit_velocity_max)).is_greater(0.0)
	assert_float(swarm.hue_variation_max).is_greater(0.0)

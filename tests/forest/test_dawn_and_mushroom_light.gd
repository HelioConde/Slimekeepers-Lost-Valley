extends GdUnitTestSuite

## Playtest 25 e 27: amanhecer/anoitecer contínuos (sem saltos de cor) e cogumelos
## que brilham só à noite, sem estourar quando estão agrupados.

const Lights := preload("res://scripts/world/ambient_lights.gd")
const Glows := preload("res://scripts/world/mushroom_glows.gd")
const Astronomy := preload("res://scripts/systems/astronomy.gd")
const Grade := preload("res://scripts/world/world_grade.gd")
const GLOW := "res://assets/world/forest/mushroom_glow.png"


func _luma(c: Color) -> float:
	return c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722


func test_six_am_is_halfway_between_night_and_day() -> void:
	var clock: Node = auto_free(load("res://scripts/systems/game_clock.gd").new())
	var night := _luma(clock.lighting_at(4 * 60))
	var dawn := _luma(clock.lighting_at(6 * 60))
	var day := _luma(clock.lighting_at(9 * 60))
	assert_float(dawn).is_greater(night + (day - night) * 0.2)
	assert_float(dawn).is_less(day - (day - night) * 0.2)
	assert_float(Lights.night_factor(6 * 60)).is_between(0.3, 0.7)
	assert_float(Lights.night_factor(5 * 60)).is_equal(1.0)
	assert_float(Lights.night_factor(7 * 60)).is_equal(0.0)


func test_dawn_and_dusk_change_a_little_every_minute() -> void:
	var clock: Node = auto_free(load("res://scripts/systems/game_clock.gd").new())
	for window in [[4 * 60, 8 * 60 + 30], [16 * 60, 21 * 60]]:
		for m in range(window[0], window[1]):
			var why := "salto às %02d:%02d" % [m / 60, m % 60]
			var a: Dictionary = Lights.foliage_profile(m)
			var b: Dictionary = Lights.foliage_profile(m + 1)
			assert_float(absf(_luma(clock.lighting_at(m)) - _luma(clock.lighting_at(m + 1)))).override_failure_message(why).is_less(0.01)
			assert_float(absf(Lights.night_factor(m) - Lights.night_factor(m + 1))).override_failure_message(why).is_less(0.0135)
			assert_float(absf(float(a.golden) - float(b.golden))).override_failure_message(why).is_less(0.02)
			assert_float(absf(float(a.light_strength) - float(b.light_strength))).override_failure_message(why).is_less(0.015)
			assert_float(absf(float(Astronomy.sky(1, m).daylight) - float(Astronomy.sky(1, m + 1).daylight))).override_failure_message(why).is_less(0.015)
			assert_float(absf(float(Grade.profile_at(m).vibrance) - float(Grade.profile_at(m + 1).vibrance))).override_failure_message(why).is_less(0.01)


func test_no_color_snaps_at_midnight_or_noon() -> void:
	# Cor das motas e do sol mudavam de uma vez (meia-noite / 12h30).
	for m in [0.0, 750.0, 1440.0 - 1.0]:
		var mote_step := absf(_luma(Lights.mote_color(m)) - _luma(Lights.mote_color(m + 1.0)))
		assert_float(mote_step).override_failure_message("mota em %d" % m).is_less(0.02)
	for m in range(0, 1440):
		var a: Dictionary = Astronomy.sky(1, m)
		var b: Dictionary = Astronomy.sky(1, m + 1)
		assert_float(absf(float(a.sun_reflection) - float(b.sun_reflection))).override_failure_message("reflexo em %d" % m).is_less(0.02)
		assert_float(absf((a.sun_color as Color).g - (b.sun_color as Color).g)).override_failure_message("sol em %d" % m).is_less(0.02)


func _region_with_glows(positions: Array) -> Array:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	var player := Node2D.new()
	player.name = "Player"
	region.add_child(player)
	for at: Vector2 in positions:
		var glow := Sprite2D.new()
		glow.texture = load(GLOW)
		glow.position = at
		region.add_child(glow)
	var holder := Node2D.new()
	region.add_child(holder)
	var rig: Node2D = Lights.new()
	holder.add_child(rig)
	return [region, rig]


func test_mushrooms_glow_at_night_and_are_dark_at_noon() -> void:
	var rig: Node2D = _region_with_glows([Vector2(0, 0), Vector2(200, 0)])[1]
	await await_idle_frame()
	rig.apply_time(12 * 60, 0.0)
	for light in rig.glow_lights(): assert_float(light.energy).is_equal(0.0)
	for halo in rig.glow_halos(): assert_float(halo.modulate.a).is_equal(0.0)
	rig.apply_time(23 * 60, 0.0)
	for light in rig.glow_lights(): assert_float(light.energy).is_greater(0.2)
	for halo in rig.glow_halos(): assert_float(halo.modulate.a).is_greater(0.2)


func _pool_alphas(positions: Array) -> Array:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	for at: Vector2 in positions:
		var glow := Sprite2D.new()
		glow.texture = load(GLOW)
		glow.position = at
		region.add_child(glow)
	var glows: Node2D = Glows.new()
	glows.setup(region)
	region.add_child(glows)
	glows.apply_time(23 * 60, Vector2.ZERO, 0.0)
	return glows.pools.filter(func(p): return p.visible).map(func(p): return p.modulate.a)


func test_grouped_mushrooms_do_not_add_up_to_a_white_blot() -> void:
	var lone: float = _pool_alphas([Vector2.ZERO])[0]
	var cluster: Array = []
	for i in 8: cluster.append(Vector2(i % 4 * 14, i / 4 * 12))
	var grouped := _pool_alphas(cluster)
	assert_int(grouped.size()).is_equal(8)
	var total := 0.0
	for a: float in grouped:
		assert_float(a).is_less(lone * 0.6)
		total += a
	# Oito juntos somam bem menos que oito isolados: a mancha não satura.
	assert_float(total).is_less(lone * 3.5)
	# Mas o grupo ainda se destaca mais que um cogumelo sozinho.
	assert_float(total).is_greater(lone)

extends GdUnitTestSuite

## Céu V10 (Astronomy): Sol e Lua só do GameClock, determinísticos e contínuos.

const Astro := preload("res://scripts/systems/astronomy.gd")
const Reflections := preload("res://scripts/world/water_reflections.gd")


func test_deterministic() -> void:
	assert_dict(Astro.sky(5, 1234.0)).is_equal(Astro.sky(5, 1234.0))


func test_sun_cycle_morning_noon_dusk_night() -> void:
	var morning: Dictionary = Astro.sky(1, 7 * 60)
	var noon: Dictionary = Astro.sky(1, 12 * 60 + 30)
	var dusk: Dictionary = Astro.sky(1, 18 * 60 + 30)
	var night: Dictionary = Astro.sky(1, 23 * 60)
	assert_float(morning.sun_altitude).is_between(0.0, 0.5)
	assert_float(morning.sun_azimuth).is_greater(0.0)        # nasce a leste
	assert_float(noon.sun_altitude).is_greater(0.95)
	assert_float(dusk.sun_azimuth).is_less(0.0)              # põe-se a oeste
	assert_float(dusk.sun_altitude).is_less(morning.sun_altitude + 0.2)
	assert_float(night.sun_altitude).is_less(0.0)
	assert_float(night.sun_reflection).is_equal(0.0)          # sem reflexo solar à noite
	assert_float(noon.sun_reflection).is_greater(morning.sun_reflection)


func test_continuous_across_midnight_and_days() -> void:
	var previous: Dictionary = Astro.sky(1, 0.0)
	for step in range(1, 3 * 1440):  # o relógio avança minuto a minuto
		var day := 1 + step / 1440
		var now: Dictionary = Astro.sky(day, float(step % 1440))
		assert_float(absf(now.sun_altitude - previous.sun_altitude)).is_less(0.03)
		assert_float(absf(now.moon_altitude - previous.moon_altitude)).is_less(0.03)
		assert_float(absf(now.moon_reflection - previous.moon_reflection)).is_less(0.05)
		previous = now


func test_moon_rises_about_50_minutes_later_each_day() -> void:
	var rises: Array[float] = []
	for day in [3, 4, 5, 6]:
		var last: float = Astro.sky(day, 0.0).moon_altitude
		var found := -1.0
		for m in range(1, 1440):
			var alt: float = Astro.sky(day, float(m)).moon_altitude
			if last < 0.0 and alt >= 0.0: found = float(m)
			last = alt
		rises.append(found)
	for i in range(1, rises.size()):
		if rises[i] < 0.0 or rises[i - 1] < 0.0: continue
		var delay := fposmod(rises[i] - rises[i - 1], 1440.0)
		assert_float(delay).is_between(40.0, 60.0)


func test_moon_position_differs_each_day_at_same_hour() -> void:
	var seen := {}
	for day in [1, 2, 3, 7, 14, 21, 29, 30]:
		var s: Dictionary = Astro.sky(day, 20 * 60)
		var key := "%.2f" % s.moon_altitude
		assert_bool(seen.has(key)).is_false()
		seen[key] = true


func test_phases_follow_synodic_month_through_all_eight() -> void:
	var names := {}
	var previous_phase := Astro.moon_phase(1, 0.0)
	for day in range(1, 32):
		var s: Dictionary = Astro.sky(day, 0.0)
		names[s.moon_phase_name] = true
		assert_float(s.moon_fraction).is_between(0.0, 1.0)
	assert_int(names.size()).is_equal(8)
	# Um mês sinódico depois a fase volta (±0,01).
	assert_float(absf(Astro.moon_phase(31, 12 * 60.0) - Astro.moon_phase(1, 12 * 60.0 - 0.53 * 1440.0 + 1440.0) )).is_less(0.02)
	# Sem saltos de intensidade entre dias.
	for day in range(1, 60):
		assert_float(absf(Astro.illuminated_fraction(Astro.moon_phase(day + 1, 0.0)) - Astro.illuminated_fraction(Astro.moon_phase(day, 0.0)))).is_less(0.11)


func test_new_moon_gives_no_moonlight_full_moon_maximum() -> void:
	# Procura o dia de lua nova e o de lua cheia no primeiro mês.
	var newest := 1
	var fullest := 1
	for day in range(1, 31):
		if Astro.illuminated_fraction(Astro.moon_phase(day, 0.0)) < Astro.illuminated_fraction(Astro.moon_phase(newest, 0.0)): newest = day
		if Astro.illuminated_fraction(Astro.moon_phase(day, 0.0)) > Astro.illuminated_fraction(Astro.moon_phase(fullest, 0.0)): fullest = day
	var best_new := 0.0
	var best_full := 0.0
	for m in range(0, 1440, 10):
		best_new = maxf(best_new, Astro.sky(newest, m).moonlight)
		best_full = maxf(best_full, Astro.sky(fullest, m).moonlight)
	assert_float(best_new).is_less(0.08)
	assert_float(best_full).is_greater(0.9)


func test_moon_can_be_seen_by_day_but_only_when_up_and_lit() -> void:
	var day_sightings := 0
	var night_full_sightings := 0
	for day in range(1, 31):
		for m in [8 * 60, 10 * 60, 15 * 60, 17 * 60]:
			var s: Dictionary = Astro.sky(day, m)
			if s.moon_visible:
				day_sightings += 1
				assert_float(s.moon_altitude).is_greater(0.0)
				assert_float(s.moon_fraction).is_greater(0.04)
				# De dia o reflexo é sutil.
				assert_float(s.moon_reflection).is_less(0.15)
	assert_int(day_sightings).is_greater(10)


func test_save_load_keeps_sky() -> void:
	var clock: Node = auto_free(load("res://scripts/systems/game_clock.gd").new())
	assert_bool(clock.load_save_data({"version": 1, "day": 17, "minutes": 1290.0})).is_true()
	var saved: Dictionary = clock.get_save_data()
	var restored: Node = auto_free(load("res://scripts/systems/game_clock.gd").new())
	restored.load_save_data(saved)
	var a: Dictionary = Astro.sky(int(saved.day), float(saved.minutes))
	var data: Dictionary = restored.get_save_data()
	assert_dict(Astro.sky(int(data.day), float(data.minutes))).is_equal(a)


func test_reflection_anchors_depend_only_on_water_and_sky() -> void:
	var water := Polygon2D.new()
	water.polygon = PackedVector2Array([Vector2(0, 0), Vector2(1600, 0), Vector2(1600, 300), Vector2(0, 300)])
	auto_free(water)
	var cells := Reflections.sample_cells(water)
	var offset: Vector2 = Astro.reflection_offset(0.4, 0.6)
	var a := Reflections.pick_anchors(cells, offset)
	assert_array(a).is_equal(Reflections.pick_anchors(cells, offset))
	for point in a:
		assert_bool(Geometry2D.is_point_in_polygon(point, water.polygon)).is_true()
	# Lua mais a leste → âncoras mais à direita (o reflexo acompanha o astro).
	var east := Reflections.pick_anchors(cells, Astro.reflection_offset(0.4, 1.0))
	var west := Reflections.pick_anchors(cells, Astro.reflection_offset(0.4, -1.0))
	assert_float(east[0].x).is_greater(west[0].x)
	# Pontes bloqueiam: nenhuma âncora embaixo delas.
	var blocked := Reflections.pick_anchors(Reflections.sample_cells(water, [Rect2(0, 0, 1600, 150)]), offset)
	for point in blocked: assert_float(point.y).is_greater(150.0 + 20.0)


func test_never_two_reflections_of_the_same_body_in_one_view() -> void:
	var water := Polygon2D.new()
	water.polygon = PackedVector2Array([Vector2(0, 0), Vector2(5000, 0), Vector2(5000, 4000), Vector2(0, 4000)])
	auto_free(water)
	var anchors := Reflections.pick_anchors(Reflections.sample_cells(water), Astro.reflection_offset(0.5, -0.7))
	assert_int(anchors.size()).is_greater(1)
	for i in anchors.size():
		for j in range(i + 1, anchors.size()):
			assert_float(anchors[i].distance_to(anchors[j])).is_greater_equal(Reflections.MIN_SPACING)

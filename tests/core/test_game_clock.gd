extends GdUnitTestSuite

## Testa uma instância isolada do relógio; nunca toca no autoload GameClock.

const GameClockScript := preload("res://scripts/systems/game_clock.gd")


func _new_clock() -> Node:
	return auto_free(GameClockScript.new())


func test_new_clock_starts_on_day_one_at_seven_in_the_morning() -> void:
	var clock := _new_clock()
	assert_int(clock.day_number).is_equal(1)
	assert_str(clock.get_time_text()).is_equal("07:00")
	assert_str(String(clock.get_period())).is_equal("manha")


func test_period_boundaries_match_documented_ranges() -> void:
	var clock := _new_clock()
	var cases := {
		0.0: "madrugada", 299.0: "madrugada",
		300.0: "manha", 539.0: "manha",
		540.0: "dia", 899.0: "dia",
		900.0: "tarde", 1079.0: "tarde",
		1080.0: "anoitecendo", 1199.0: "anoitecendo",
		1200.0: "noite", 1439.0: "noite",
	}
	for minute in cases:
		assert_str(String(clock.period_at(minute))).override_failure_message("minuto %s" % minute).is_equal(cases[minute])


func test_period_at_wraps_and_rejects_non_finite_values() -> void:
	var clock := _new_clock()
	assert_str(String(clock.period_at(1440.0 + 600.0))).is_equal("dia")
	assert_str(String(clock.period_at(-60.0))).is_equal("noite")
	assert_str(String(clock.period_at(NAN))).is_equal("manha")


func test_advance_across_midnight_increments_day_and_emits_once() -> void:
	var clock := _new_clock()
	clock.set_time(23, 30)
	var days: Array = []
	var advances: Array = []
	clock.day_changed.connect(func(day: int) -> void: days.append(day))
	clock.time_advanced.connect(func(minutes: float, passed: int) -> void: advances.append([minutes, passed]))
	clock.advance_minutes(60.0)
	assert_int(clock.day_number).is_equal(2)
	assert_str(clock.get_time_text()).is_equal("00:30")
	assert_array(days).is_equal([2])
	assert_array(advances).is_equal([[60.0, 1]])


func test_long_sleep_reports_every_day_passed_in_one_notification() -> void:
	var clock := _new_clock()
	var advances: Array = []
	clock.time_advanced.connect(func(minutes: float, passed: int) -> void: advances.append(passed))
	clock.advance_minutes(1440.0 * 3.0)
	assert_int(clock.day_number).is_equal(4)
	assert_str(clock.get_time_text()).is_equal("07:00")
	assert_array(advances).is_equal([3])


func test_invalid_advances_are_ignored_without_signals() -> void:
	var clock := _new_clock()
	var emitted: Array = []
	clock.time_advanced.connect(func(m: float, d: int) -> void: emitted.append(m))
	for bad in [0.0, -5.0, NAN, INF, 1440.0 * 1000001.0]:
		clock.advance_minutes(bad)
	assert_array(emitted).is_empty()
	assert_str(clock.get_time_text()).is_equal("07:00")
	assert_int(clock.day_number).is_equal(1)


func test_set_time_clamps_and_emits_period_change_only_when_it_changes() -> void:
	var clock := _new_clock()
	var periods: Array = []
	clock.period_changed.connect(func(p: StringName) -> void: periods.append(String(p)))
	clock.set_time(99, 99)
	assert_str(clock.get_time_text()).is_equal("23:59")
	clock.set_time(22, 0)
	assert_array(periods).is_equal(["noite"])


func test_lighting_is_continuous_at_midnight_and_white_at_noon() -> void:
	var clock := _new_clock()
	assert_bool(clock.lighting_at(0.0).is_equal_approx(clock.lighting_at(1440.0))).is_true()
	assert_bool(clock.lighting_at(720.0).is_equal_approx(Color(1, 1, 1))).is_true()


func test_save_round_trip_restores_day_and_minutes() -> void:
	var source := _new_clock()
	source.advance_minutes(1440.0 + 125.0)
	var target := _new_clock()
	assert_bool(target.load_save_data(source.get_save_data())).is_true()
	assert_int(target.day_number).is_equal(source.day_number)
	assert_str(target.get_time_text()).is_equal(source.get_time_text())


func test_malformed_saves_leave_clock_untouched() -> void:
	var clock := _new_clock()
	clock.set_time(12, 15)
	var bad_saves := [
		{"version": 2, "day": 3, "minutes": 10.0},
		{"version": 1, "day": 0, "minutes": 10.0},
		{"version": 1, "day": 2.5, "minutes": 10.0},
		{"version": 1, "day": 3, "minutes": 1440.0},
		{"version": 1, "day": "3", "minutes": 10.0},
		{"version": 1, "day": 3, "minutes": NAN},
	]
	for save in bad_saves:
		assert_bool(clock.load_save_data(save)).override_failure_message(str(save)).is_false()
	assert_int(clock.day_number).is_equal(1)
	assert_str(clock.get_time_text()).is_equal("12:15")


func test_reset_new_game_stops_and_returns_to_start() -> void:
	var clock := _new_clock()
	clock.advance_minutes(5000.0)
	clock.reset_new_game()
	assert_bool(clock.is_running()).is_false()
	assert_int(clock.day_number).is_equal(1)
	assert_str(clock.get_time_text()).is_equal("07:00")


func test_invalid_day_length_falls_back_to_default() -> void:
	var clock := _new_clock()
	clock.seconds_per_game_day = 0.0
	assert_float(clock.seconds_per_game_day).is_equal(1440.0)
	clock.seconds_per_game_day = NAN
	assert_float(clock.seconds_per_game_day).is_equal(1440.0)

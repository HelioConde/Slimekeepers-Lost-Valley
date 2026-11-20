extends GdUnitTestSuite

const CALCULATOR := preload("res://scripts/systems/crop_stage_calculator.gd")


func _assert_result(planted_at: float, now: float, duration: float, phase: String, remaining: float) -> void:
	var result: Dictionary = CALCULATOR.calculate(planted_at, now, duration)
	assert_dict(result).is_equal({"phase": phase, "remaining_minutes": remaining})


func test_fractional_duration_across_midnight() -> void:
	# Plantio às 23:59 do dia 1; maturação às 00:01:30 do dia 2.
	_assert_result(1439.0, 1439.0, 2.5, "growing", 2.5)
	_assert_result(1439.0, 1440.0, 2.5, "growing", 1.5)
	_assert_result(1439.0, 1441.25, 2.5, "growing", 0.25)
	_assert_result(1439.0, 1441.5, 2.5, "ready", 0.0)
	_assert_result(1439.0, 4320.0, 2.5, "ready", 0.0)


func test_remaining_never_increases_and_ready_persists() -> void:
	var previous := 120.0
	var was_ready := false
	for offset in range(181):
		var result: Dictionary = CALCULATOR.calculate(420.0, 420.0 + offset, 120.0)
		var remaining: float = result["remaining_minutes"]
		assert_bool(remaining >= 0.0 and remaining <= previous).is_true()
		if was_ready:
			assert_str(result["phase"]).is_equal("ready")
		was_ready = result["phase"] == "ready"
		previous = remaining
	assert_bool(was_ready).is_true()


func test_invalid_time_or_duration() -> void:
	_assert_result(-1.0, 0.0, 1.0, "invalid", 0.0)
	_assert_result(10.0, 9.0, 1.0, "invalid", 0.0)
	_assert_result(0.0, 0.0, 0.0, "invalid", 0.0)
	_assert_result(0.0, 0.0, -1.0, "invalid", 0.0)
	for value: float in [NAN, INF, -INF]:
		_assert_result(value, 0.0, 1.0, "invalid", 0.0)
		_assert_result(0.0, value, 1.0, "invalid", 0.0)
		_assert_result(0.0, 0.0, value, "invalid", 0.0)

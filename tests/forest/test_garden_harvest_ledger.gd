extends GdUnitTestSuite

const LEDGER := preload("res://scripts/systems/garden_harvest_ledger.gd")


func test_unique_per_bed_and_cycle() -> void:
	var ledger := LEDGER.new()
	assert_bool(ledger.record_harvest("norte", 0, {"folhas": 2})).is_true()
	assert_bool(ledger.record_harvest("norte", 0, {"sementes": 1})).is_false()
	assert_bool(ledger.record_harvest("sul", 0, {"folhas": 0})).is_true()
	assert_bool(ledger.record_harvest("norte", 1, {"folhas": 1})).is_true()
	assert_dict(ledger.get_save_data()["cycles"][0]["norte"]).is_equal({"folhas": 2})


func test_invalid_input_does_not_reserve_bed() -> void:
	var ledger := LEDGER.new()
	assert_bool(ledger.record_harvest(" ", 0, {"folhas": 1})).is_false()
	assert_bool(ledger.record_harvest("norte", -1, {"folhas": 1})).is_false()
	for invalid in [{}, {"": 1}, {"folhas": -1}, {"folhas": 1.5}, {3: 1}]:
		assert_bool(ledger.record_harvest("norte", 0, invalid)).is_false()
	assert_dict(ledger.get_save_data()["cycles"]).is_empty()
	assert_bool(ledger.record_harvest("norte", 0, {"folhas": 1})).is_true()


func test_round_trip_keeps_independent_copies_and_duplicate_guard() -> void:
	var original := LEDGER.new()
	var resources := {"folhas": 2}
	assert_bool(original.record_harvest("sul", 3, resources)).is_true()
	resources["folhas"] = 8
	var saved := original.get_save_data()
	var restored := LEDGER.new()
	assert_bool(restored.load_save_data(saved)).is_true()
	saved["cycles"][3]["sul"]["folhas"] = 9
	assert_dict(original.get_save_data()["cycles"][3]["sul"]).is_equal({"folhas": 2})
	assert_dict(restored.get_save_data()["cycles"][3]["sul"]).is_equal({"folhas": 2})
	assert_bool(restored.record_harvest("sul", 3, resources)).is_false()
	assert_bool(restored.load_save_data({"cycles": {}})).is_true()
	assert_dict(restored.get_save_data()["cycles"]).is_empty()
	assert_bool(original.record_harvest("sul", 3, resources)).is_false()


func test_invalid_restore_preserves_entire_previous_state() -> void:
	var ledger := LEDGER.new()
	assert_bool(ledger.record_harvest("sul", 1, {"folhas": 2})).is_true()
	var before := ledger.get_save_data()
	for invalid in [null, {}, {"cycles": []}, {"cycles": {"1": {}}}, {"cycles": {1: {" ": {"folhas": 2}}}}, {"cycles": {2: {"norte": {"folhas": 1}, "sul": {"folhas": -1}}}}]:
		assert_bool(ledger.load_save_data(invalid)).is_false()
		assert_dict(ledger.get_save_data()).is_equal(before)

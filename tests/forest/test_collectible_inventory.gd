extends GdUnitTestSuite

const INVENTORY := preload("res://scripts/systems/collectible_inventory.gd")


func test_collect_and_consume_independent_items() -> void:
	var bag := INVENTORY.new()
	assert_int(bag.count("semente")).is_equal(0)
	assert_bool(bag.add("semente", 2)).is_true()
	assert_bool(bag.add("folha")).is_true()
	assert_bool(bag.add("semente")).is_true()
	assert_int(bag.count("semente")).is_equal(3)
	assert_bool(bag.remove("semente")).is_true()
	assert_int(bag.count("semente")).is_equal(2)
	assert_bool(bag.remove("semente", 2)).is_true()
	assert_bool(bag.serialize().has("semente")).is_false()
	assert_int(bag.count("folha")).is_equal(1)


func test_invalid_operations_leave_balances_unchanged() -> void:
	var bag := INVENTORY.new()
	assert_bool(bag.add("folha", 3)).is_true()
	var before := bag.serialize()
	for bad_id in ["", "  ", 7, null]:
		assert_bool(bag.add(bad_id)).is_false()
		assert_bool(bag.remove(bad_id)).is_false()
	for bad_quantity in [-1, 0, 1.5, "1", true]:
		assert_bool(bag.add("folha", bad_quantity)).is_false()
		assert_bool(bag.remove("folha", bad_quantity)).is_false()
	assert_bool(bag.remove("folha", 4)).is_false()
	assert_bool(bag.remove("semente")).is_false()
	assert_dict(bag.serialize()).is_equal(before)


func test_overflow_keeps_previous_quantity() -> void:
	var bag := INVENTORY.new()
	assert_bool(bag.add("folha", INVENTORY.MAX_QUANTITY)).is_true()
	assert_bool(bag.add("folha")).is_false()
	assert_int(bag.count("folha")).is_equal(INVENTORY.MAX_QUANTITY)


func test_save_round_trip_replaces_contents_without_aliasing() -> void:
	var source := INVENTORY.new()
	assert_bool(source.add("semente", 4)).is_true()
	var saved := source.serialize()
	var restored := INVENTORY.new()
	assert_bool(restored.add("folha")).is_true()
	assert_bool(restored.deserialize(saved)).is_true()
	saved["semente"] = 9
	assert_int(source.count("semente")).is_equal(4)
	assert_int(restored.count("semente")).is_equal(4)
	assert_int(restored.count("folha")).is_equal(0)
	assert_bool(restored.deserialize({})).is_true()
	assert_bool(restored.serialize().is_empty()).is_true()


func test_invalid_save_does_not_apply_even_valid_entries() -> void:
	var bag := INVENTORY.new()
	assert_bool(bag.add("semente", 2)).is_true()
	var before := bag.serialize()
	for invalid in [null, [], {"folha": 1, "semente": -1}, {"folha": 0}, {"folha": 2.0}, {" ": 3}, {7: 1}]:
		assert_bool(bag.deserialize(invalid)).is_false()
		assert_dict(bag.serialize()).is_equal(before)

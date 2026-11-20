extends GdUnitTestSuite

const Ledger := preload("res://scripts/systems/cooking_serving_ledger.gd")


func test_accumulates_by_id_and_by_instance() -> void:
	var ledger := Ledger.new()
	assert_bool(ledger.record_preparation("teste_a")).is_true()
	assert_bool(ledger.record_preparation(&"teste_a", 2)).is_true()
	assert_bool(ledger.record_preparation("teste_b2", 4)).is_true()
	assert_int(ledger.count_for("teste_a")).is_equal(3)
	assert_int(ledger.count_for("teste_b2")).is_equal(4)
	assert_bool(Ledger.new().snapshot().is_empty()).is_true()


func test_invalid_input_preserves_snapshot() -> void:
	var ledger := Ledger.new()
	assert_bool(ledger.record_preparation("teste", 2)).is_true()
	var before := ledger.snapshot()
	for invalid_id in [null, 7, {}, "", " ", " teste", "teste ", "1teste", "Teste", "a/b"]:
		assert_bool(ledger.record_preparation(invalid_id)).is_false()
		assert_int(ledger.count_for(invalid_id)).is_equal(0)
	for quantity in [null, false, 0, -1, 2.0, "3", []]:
		assert_bool(ledger.record_preparation("teste", quantity)).is_false()
	assert_dict(ledger.snapshot()).is_equal(before)


func test_overflow_does_not_wrap_count() -> void:
	var ledger := Ledger.new()
	assert_bool(ledger.record_preparation("teste", Ledger.MAX_COUNT)).is_true()
	assert_bool(ledger.record_preparation("teste")).is_false()
	assert_int(ledger.count_for("teste")).is_equal(Ledger.MAX_COUNT)


func test_queries_are_idempotent_and_snapshots_are_detached() -> void:
	var ledger := Ledger.new()
	assert_bool(ledger.record_preparation("teste", 2)).is_true()
	var before := ledger.snapshot()
	for _i in range(2):
		assert_int(ledger.count_for("ausente")).is_equal(0)
		assert_int(ledger.count_for("teste")).is_equal(2)
		assert_dict(ledger.snapshot()).is_equal(before)
	var edited := ledger.snapshot()
	edited.clear()
	edited["outra"] = 9
	assert_dict(ledger.snapshot()).is_equal({"teste": 2})
	assert_bool(ledger.record_preparation("teste")).is_true()
	assert_dict(before).is_equal({"teste": 2})

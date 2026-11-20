extends GdUnitTestSuite

const Flags := preload("res://scripts/systems/session_progress_flags.gd")


func test_mark_counts_each_id_once_until_clear() -> void:
	var flags := Flags.new()
	assert_bool(flags.is_marked("a")).is_false()
	assert_bool(flags.mark("")).is_false()
	assert_bool(flags.mark(" a")).is_false()
	assert_bool(flags.mark("a")).is_true()
	assert_bool(flags.mark("a")).is_false()
	assert_bool(flags.is_marked("a")).is_true()
	assert_int(flags.count()).is_equal(1)
	flags.clear()
	assert_int(flags.count()).is_equal(0)
	assert_bool(flags.is_marked("a")).is_false()
	assert_bool(flags.mark("a")).is_true()


func test_ordered_snapshot_round_trip_is_independent() -> void:
	var first := Flags.new()
	first.mark("z")
	first.mark("a")
	var snapshot := first.export_state()
	assert_array(snapshot.keys()).is_equal(["a", "z"])
	var second := Flags.new()
	second.mark("old")
	assert_bool(second.import_state(snapshot)).is_true()
	snapshot.clear()
	assert_bool(second.is_marked("old")).is_false()
	assert_int(second.count()).is_equal(2)
	assert_bool(second.is_marked("a")).is_true()
	assert_bool(second.is_marked("z")).is_true()
	assert_bool(second.import_state({})).is_true()
	assert_int(second.count()).is_equal(0)
	assert_int(first.count()).is_equal(2)


func test_invalid_import_never_partially_replaces_state() -> void:
	var flags := Flags.new()
	flags.mark("original")
	for invalid in [null, [], {1: true}, {"": true}, {" ": true}, {"new": true, "bad": false}, {"bad": 1}, {"bad": {}}]:
		assert_bool(flags.import_state(invalid)).is_false()
		assert_int(flags.count()).is_equal(1)
		assert_bool(flags.is_marked("original")).is_true()

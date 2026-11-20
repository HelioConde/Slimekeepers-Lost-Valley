extends GdUnitTestSuite
## Testa fluxo real do vale: GameClock + bolsa + canteiros + ledger sem criar assets.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const GARDEN := preload("res://scripts/systems/valley_starter_garden.gd")
var clock: Node

func before_test() -> void:
	clock = get_tree().root.get_node("GameClock")
	clock.reset_new_game()
	for key in [BAG.INVENTORY_KEY, GARDEN.KEY, GARDEN.LEDGER_KEY]:
		if get_tree().has_meta(key):
			get_tree().remove_meta(key)

func after_test() -> void:
	for key in [BAG.INVENTORY_KEY, GARDEN.KEY, GARDEN.LEDGER_KEY]:
		if get_tree().has_meta(key):
			get_tree().remove_meta(key)
	clock.reset_new_game()

func test_harvest_once_records_bed_cycle_and_one_leaf() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, BAG.ITEM_ID, 1)).is_true()
	assert_bool(GARDEN.plant(tree, clock, "norte")).is_true()
	clock.advance_minutes(121.0)
	assert_str(GARDEN.phase(tree, clock, "norte")).is_equal("ready")
	assert_bool(GARDEN.harvest(tree, clock, "norte")).is_true()
	assert_int(BAG.leaves(tree)).is_equal(1)
	assert_bool(GARDEN.harvest(tree, clock, "norte")).is_false()
	assert_int(BAG.leaves(tree)).is_equal(1)
	var saved: Dictionary = GARDEN.harvest_record(tree)
	assert_dict(saved["cycles"][0]["norte"]).is_equal({BAG.LEAVES_ID: 1})

func test_corrupt_bag_prevents_harvest_and_does_not_reserve_ledger() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, BAG.ITEM_ID, 1)).is_true()
	assert_bool(GARDEN.plant(tree, clock, "sul")).is_true()
	clock.advance_minutes(122.0)
	tree.set_meta(BAG.INVENTORY_KEY, {BAG.LEAVES_ID: -1})
	assert_bool(GARDEN.harvest(tree, clock, "sul")).is_false()
	assert_str(GARDEN.phase(tree, clock, "sul")).is_equal("ready")
	assert_dict(GARDEN.harvest_record(tree)["cycles"]).is_empty()
	assert_dict(tree.get_meta(BAG.INVENTORY_KEY)).is_equal({BAG.LEAVES_ID: -1})

func test_stage_calculator_handles_time_rollback_and_midnight() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, BAG.ITEM_ID, 1)).is_true()
	clock.set_time(23, 59)
	assert_bool(GARDEN.plant(tree, clock, "norte")).is_true()
	clock.advance_minutes(60.0)
	assert_str(GARDEN.phase(tree, clock, "norte")).is_equal("growing")
	assert_int(GARDEN.minutes_remaining(tree, clock, "norte")).is_equal(60)
	clock.advance_minutes(60.0)
	assert_str(GARDEN.phase(tree, clock, "norte")).is_equal("ready")
	assert_int(GARDEN.minutes_remaining(tree, clock, "norte")).is_equal(0)

func test_both_beds_have_independent_records_and_guard_duplicate() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, BAG.ITEM_ID, 2)).is_true()
	assert_bool(GARDEN.plant(tree, clock, "norte")).is_true()
	assert_bool(GARDEN.plant(tree, clock, "sul")).is_true()
	clock.advance_minutes(121.0)
	assert_bool(GARDEN.harvest(tree, clock, "norte")).is_true()
	assert_bool(GARDEN.harvest(tree, clock, "sul")).is_true()
	assert_bool(GARDEN.harvest(tree, clock, "norte")).is_false()
	assert_int(BAG.leaves(tree)).is_equal(2)
	var saved: Dictionary = GARDEN.harvest_record(tree)
	assert_int(saved["cycles"][0].size()).is_equal(2)
	assert_dict(saved["cycles"][0]["sul"]).is_equal({BAG.LEAVES_ID: 1})

extends GdUnitTestSuite
## Valida o vínculo de marcos com ações reais, sem confundir tentativa com sucesso.
const PROGRESS := preload("res://scripts/systems/session_progress_session.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const GARDEN := preload("res://scripts/systems/valley_starter_garden.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
var clock: Node

func before_test() -> void:
	clock = get_tree().root.get_node("GameClock")
	clock.reset_new_game()
	_clear_fixture()

func after_test() -> void:
	_clear_fixture()
	clock.reset_new_game()

func _clear_fixture() -> void:
	var tree := get_tree()
	for key in [PROGRESS.KEY, BAG.INVENTORY_KEY, BAG.PATCHES_KEY, BAG.FRIENDS_KEY, GARDEN.KEY, GARDEN.LEDGER_KEY, COOKING.LEDGER_KEY]:
		if tree.has_meta(key):
			tree.remove_meta(key)

func test_marks_only_one_time_for_valid_events() -> void:
	var tree := get_tree()
	assert_int(PROGRESS.count(tree)).is_equal(0)
	assert_bool(PROGRESS.mark_event(tree, "bad.id")).is_false()
	assert_bool(PROGRESS.mark_event(tree, PROGRESS.GARDEN_PLANTED)).is_true()
	assert_bool(PROGRESS.mark_event(tree, PROGRESS.GARDEN_PLANTED)).is_false()
	assert_bool(PROGRESS.is_marked(tree, PROGRESS.GARDEN_PLANTED)).is_true()
	assert_int(PROGRESS.count(tree)).is_equal(1)
	assert_int(PROGRESS.snapshot(tree).size()).is_equal(1)

func test_seed_harvest_requires_real_brotinho_friend() -> void:
	var tree := get_tree()
	assert_bool(BAG.harvest(tree, "site_a")).is_false()
	assert_int(PROGRESS.count(tree)).is_equal(0)
	tree.set_meta(BAG.FRIENDS_KEY, {"brotinho/H01/0": true})
	assert_bool(BAG.harvest(tree, "site_a")).is_true()
	assert_bool(PROGRESS.is_marked(tree, PROGRESS.SEEDS_COLLECTED)).is_true()
	assert_bool(BAG.harvest(tree, "site_a")).is_false()
	assert_bool(BAG.harvest(tree, "site_b")).is_true()
	assert_int(BAG.seeds(tree)).is_equal(2)
	assert_int(PROGRESS.count(tree)).is_equal(1)

func test_plant_then_harvest_marks_after_each_success() -> void:
	var tree := get_tree()
	assert_bool(GARDEN.plant(tree, clock, "norte")).is_false()
	assert_int(PROGRESS.count(tree)).is_equal(0)
	assert_bool(BAG.add_item(tree, BAG.ITEM_ID, 2)).is_true()
	assert_bool(GARDEN.plant(tree, clock, "norte")).is_true()
	assert_bool(PROGRESS.is_marked(tree, PROGRESS.GARDEN_PLANTED)).is_true()
	assert_bool(GARDEN.harvest(tree, clock, "norte")).is_false()
	assert_bool(PROGRESS.is_marked(tree, PROGRESS.GARDEN_HARVESTED)).is_false()
	clock.advance_minutes(121.0)
	assert_bool(GARDEN.harvest(tree, clock, "norte")).is_true()
	assert_bool(PROGRESS.is_marked(tree, PROGRESS.GARDEN_HARVESTED)).is_true()
	assert_bool(GARDEN.harvest(tree, clock, "norte")).is_false()
	assert_bool(GARDEN.plant(tree, clock, "sul")).is_true()
	clock.advance_minutes(121.0)
	assert_bool(GARDEN.harvest(tree, clock, "sul")).is_true()
	assert_int(PROGRESS.count(tree)).is_equal(2)

func test_cooking_only_marks_after_valid_inventory_debit() -> void:
	var tree := get_tree()
	assert_str(COOKING.prepare(tree)).is_equal("needs_leaves")
	assert_bool(PROGRESS.is_marked(tree, PROGRESS.FOOD_PREPARED)).is_false()
	assert_bool(BAG.add_item(tree, BAG.LEAVES_ID, 2)).is_true()
	assert_str(COOKING.prepare(tree)).is_equal("prepared")
	assert_str(COOKING.prepare(tree)).is_equal("prepared")
	assert_bool(PROGRESS.is_marked(tree, PROGRESS.FOOD_PREPARED)).is_true()
	assert_int(PROGRESS.count(tree)).is_equal(1)
	assert_int(COOKING.portions(tree)).is_equal(2)

func test_corrupt_flags_do_not_overwrite_or_silently_mark() -> void:
	var tree := get_tree()
	var corrupt := {"foreign.event": true}
	tree.set_meta(PROGRESS.KEY, corrupt.duplicate())
	assert_bool(PROGRESS.mark_event(tree, PROGRESS.SEEDS_COLLECTED)).is_false()
	assert_int(PROGRESS.count(tree)).is_equal(-1)
	assert_dict(tree.get_meta(PROGRESS.KEY)).is_equal(corrupt)
	assert_bool(PROGRESS.is_marked(tree, PROGRESS.SEEDS_COLLECTED)).is_false()

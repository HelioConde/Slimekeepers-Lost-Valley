extends GdUnitTestSuite
## Nao usa inferencia; testa bolsa real de SceneTree e registro de preparos da sessao.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")

func before_test() -> void:
	for key in [BAG.INVENTORY_KEY, COOKING.LEDGER_KEY]:
		if get_tree().has_meta(key):
			get_tree().remove_meta(key)

func after_test() -> void:
	before_test()

func test_no_leaves_never_creates_a_meal() -> void:
	var tree := get_tree()
	assert_bool(COOKING.availability(tree).available).is_false()
	assert_str(COOKING.prepare(tree)).is_equal("needs_leaves")
	assert_int(COOKING.portions(tree)).is_equal(0)
	assert_int(BAG.leaves(tree)).is_equal(0)

func test_one_leaf_debits_exactly_once_and_records_one_portion() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, BAG.LEAVES_ID, 1)).is_true()
	assert_bool(COOKING.availability(tree).available).is_true()
	assert_str(COOKING.prepare(tree)).is_equal("prepared")
	assert_int(BAG.leaves(tree)).is_equal(0)
	assert_int(COOKING.portions(tree)).is_equal(1)
	assert_str(COOKING.prepare(tree)).is_equal("needs_leaves")
	assert_int(COOKING.portions(tree)).is_equal(1)

func test_multiple_preparations_share_single_stock() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, BAG.ITEM_ID, 2)).is_true()
	assert_bool(BAG.add_item(tree, BAG.LEAVES_ID, 2)).is_true()
	assert_str(COOKING.prepare(tree)).is_equal("prepared")
	assert_str(COOKING.prepare(tree)).is_equal("prepared")
	assert_int(BAG.leaves(tree)).is_equal(0)
	assert_int(BAG.seeds(tree)).is_equal(2)
	assert_int(COOKING.portions(tree)).is_equal(2)
	assert_dict(BAG.inventory_snapshot(tree)).is_equal({BAG.ITEM_ID: 2, COOKING.RECIPE_ID: 2})

func test_invalid_bag_and_corrupted_ledger_do_not_consume() -> void:
	var tree := get_tree()
	tree.set_meta(BAG.INVENTORY_KEY, {BAG.LEAVES_ID: 2, BAG.ITEM_ID: -1})
	assert_bool(BAG.spend_item(tree, BAG.LEAVES_ID)).is_false()
	assert_dict(tree.get_meta(BAG.INVENTORY_KEY)).is_equal({BAG.LEAVES_ID: 2, BAG.ITEM_ID: -1})
	assert_str(COOKING.prepare(tree)).is_equal("needs_leaves")
	tree.set_meta(BAG.INVENTORY_KEY, {BAG.LEAVES_ID: 2})
	tree.set_meta(COOKING.LEDGER_KEY, "not_a_ledger")
	assert_str(COOKING.prepare(tree)).is_equal("invalid_ledger")
	assert_int(BAG.leaves(tree)).is_equal(2)

func test_zero_legacy_balance_not_counted_as_food() -> void:
	var tree := get_tree()
	tree.set_meta(BAG.INVENTORY_KEY, {BAG.ITEM_ID: 0, BAG.LEAVES_ID: 1})
	assert_dict(BAG.inventory_snapshot(tree)).is_equal({BAG.LEAVES_ID: 1})
	assert_str(COOKING.prepare(tree)).is_equal("prepared")
	assert_int(BAG.seeds(tree)).is_equal(0)
	assert_int(COOKING.portions(tree)).is_equal(1)

func test_recipe_list_shows_missing_and_available_without_spending() -> void:
	var tree := get_tree()
	var first: Array[Dictionary] = COOKING.recipe_options(tree)
	assert_int(first.size()).is_equal(1)
	assert_str(first[0]["id"]).is_equal(COOKING.RECIPE_ID)
	assert_bool(first[0]["available"]).is_false()
	assert_dict(first[0]["missing"]).is_equal({BAG.LEAVES_ID: 1})
	assert_bool(BAG.add_item(tree, BAG.LEAVES_ID, 1)).is_true()
	var second: Array[Dictionary] = COOKING.recipe_options(tree)
	assert_bool(second[0]["available"]).is_true()
	assert_dict(second[0]["missing"]).is_empty()
	assert_int(BAG.leaves(tree)).is_equal(1)


extends GdUnitTestSuite
## Oferta opcional de prototipo; nao inventa preferencias nem altera amizade.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
const FOOD := preload("res://scripts/systems/slime_food_session.gd")
const SLIME_A := "brotinho/H01/0"
const SLIME_B := "bolhinha/V01/0"

func before_test() -> void:
	for key in [BAG.INVENTORY_KEY, COOKING.LEDGER_KEY, FOOD.OFFERS_KEY]:
		if get_tree().has_meta(key):
			get_tree().remove_meta(key)

func after_test() -> void:
	before_test()

func test_cooking_creates_a_consumable_portion_without_duplicating_leaves() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, BAG.LEAVES_ID, 1)).is_true()
	assert_str(COOKING.prepare(tree)).is_equal("prepared")
	assert_int(BAG.leaves(tree)).is_equal(0)
	assert_int(BAG.count_item(tree, COOKING.RECIPE_ID)).is_equal(1)
	assert_int(COOKING.portions(tree)).is_equal(1)

func test_feeding_requires_friendship_and_available_food() -> void:
	var tree := get_tree()
	assert_str(FOOD.offer(tree, SLIME_A, true)).is_equal("needs_portion")
	assert_bool(BAG.add_item(tree, COOKING.RECIPE_ID, 1)).is_true()
	assert_str(FOOD.offer(tree, SLIME_A, false)).is_equal("needs_friendship")
	assert_int(BAG.count_item(tree, COOKING.RECIPE_ID)).is_equal(1)
	assert_str(FOOD.first_food_for(tree, SLIME_A)).is_equal("")

func test_first_offer_consumes_one_portion_only() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, COOKING.RECIPE_ID, 2)).is_true()
	assert_str(FOOD.offer(tree, SLIME_A, true)).is_equal("offered")
	assert_int(BAG.count_item(tree, COOKING.RECIPE_ID)).is_equal(1)
	assert_str(FOOD.first_food_for(tree, SLIME_A)).is_equal(COOKING.RECIPE_ID)
	assert_str(FOOD.offer(tree, SLIME_A, true)).is_equal("already_offered")
	assert_int(BAG.count_item(tree, COOKING.RECIPE_ID)).is_equal(1)
	assert_str(FOOD.offer(tree, SLIME_B, true)).is_equal("offered")
	assert_int(BAG.count_item(tree, COOKING.RECIPE_ID)).is_equal(0)
	assert_str(FOOD.first_food_for(tree, SLIME_B)).is_equal(COOKING.RECIPE_ID)

func test_invalid_offer_state_and_slime_id_do_not_consume() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, COOKING.RECIPE_ID, 1)).is_true()
	assert_str(FOOD.offer(tree, "", true)).is_equal("invalid_slime")
	tree.set_meta(FOOD.OFFERS_KEY, {"not": "an_array"})
	assert_str(FOOD.offer(tree, SLIME_A, true)).is_equal("invalid_state")
	assert_int(BAG.count_item(tree, COOKING.RECIPE_ID)).is_equal(1)
	assert_str(FOOD.first_food_for(tree, SLIME_A)).is_equal("")

func test_exchange_is_atomic_on_invalid_transaction() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, BAG.LEAVES_ID, 2)).is_true()
	var before: Dictionary = BAG.inventory_snapshot(tree)
	assert_bool(BAG.exchange_item(tree, BAG.LEAVES_ID, BAG.LEAVES_ID)).is_false()
	assert_bool(BAG.exchange_item(tree, BAG.ITEM_ID, COOKING.RECIPE_ID)).is_false()
	assert_bool(BAG.exchange_item(tree, BAG.LEAVES_ID, COOKING.RECIPE_ID, 3)).is_false()
	assert_dict(BAG.inventory_snapshot(tree)).is_equal(before)

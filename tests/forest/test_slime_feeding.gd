extends GdUnitTestSuite

## Alimentar slimes: só amigos, só comida, uma vez por dia, cozido vale mais.

const Feeding := preload("res://scripts/systems/slime_feeding.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
const Cooking := preload("res://scripts/systems/valley_cooking.gd")
const ID := "brotinho/H01/0"


func before_test() -> void:
	for key in [Feeding.KEY, Feeding.FED_KEY, Bag.INVENTORY_KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func test_feeding_rules() -> void:
	var tree := get_tree()
	Bag.add_item(tree, "cenoura", 2)
	assert_str(Feeding.feed(tree, ID, false, "cenoura", 1)).is_equal("needs_friendship")
	assert_str(Feeding.feed(tree, ID, true, "semente_cenoura", 1)).is_equal("not_food")
	assert_str(Feeding.feed(tree, ID, true, "beterraba", 1)).is_equal("no_item")
	assert_str(Feeding.feed(tree, ID, true, "cenoura", 1)).is_equal("fed")
	assert_int(Bag.count_item(tree, "cenoura")).is_equal(1)
	assert_str(Feeding.feed(tree, ID, true, "cenoura", 1)).is_equal("already_fed")
	assert_int(Bag.count_item(tree, "cenoura")).is_equal(1)
	assert_str(Feeding.feed(tree, ID, true, "cenoura", 2)).is_equal("fed")
	assert_int(Feeding.points(tree, ID)).is_equal(2 * Feeding.POINTS.crop)


func test_cooked_food_is_worth_more_and_hearts_grow() -> void:
	var tree := get_tree()
	Bag.add_item(tree, Cooking.RECIPE_ID, 2)
	assert_str(Feeding.feed(tree, ID, true, Cooking.RECIPE_ID, 1)).is_equal("fed")
	assert_int(Feeding.points(tree, ID)).is_equal(Feeding.POINTS.food)
	Feeding.feed(tree, ID, true, Cooking.RECIPE_ID, 2)
	assert_int(Feeding.hearts(tree, ID)).is_equal(1)

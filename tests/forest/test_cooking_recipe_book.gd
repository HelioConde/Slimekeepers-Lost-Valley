extends GdUnitTestSuite

const BOOK := preload("res://scripts/systems/cooking_recipe_book.gd")

func _fixture() -> Dictionary:
	return {"id": "test_recipe", "ingredients": {"test_a": 2, "test_b": 1}}

func test_valid_recipe_keeps_snapshot_and_does_not_consume() -> void:
	var book := BOOK.new()
	var recipe := _fixture()
	assert_str(book.register_recipe(recipe)).is_equal("ok")
	recipe.ingredients.test_a = 99
	var inventory := {"test_a": 2, "test_b": 3}
	var before := inventory.duplicate()
	var result := book.check_availability("test_recipe", inventory)
	assert_bool(result.available).is_true()
	assert_str(result.reason).is_equal("ok")
	assert_bool(result.missing.is_empty()).is_true()
	assert_dict(inventory).is_equal(before)

func test_invalid_recipe_does_not_reserve_id() -> void:
	var book := BOOK.new()
	assert_str(book.register_recipe(null)).is_equal("invalid_recipe")
	assert_str(book.register_recipe({"id": " "})).is_equal("invalid_recipe_id")
	for invalid in [null, [], {}, {"": 1}, {"test_a": 0}, {"test_a": -2}, {"test_a": 1.5}]:
		assert_str(book.register_recipe({"id": "test_recipe", "ingredients": invalid})).is_equal("invalid_ingredients")
	assert_str(book.register_recipe(_fixture())).is_equal("ok")

func test_duplicate_recipe_preserves_original_requirements() -> void:
	var book := BOOK.new()
	assert_str(book.register_recipe(_fixture())).is_equal("ok")
	assert_str(book.register_recipe({"id": "test_recipe", "ingredients": {"test_a": 1}})).is_equal("duplicate_recipe")
	var result := book.check_availability("test_recipe", {"test_a": 1})
	assert_bool(result.available).is_false()
	assert_dict(result.missing).is_equal({"test_a": 1, "test_b": 1})

func test_insufficient_ingredients_reports_each_deficit_without_consuming() -> void:
	var book := BOOK.new()
	assert_str(book.register_recipe(_fixture())).is_equal("ok")
	var inventory := {"test_a": 1, "test_extra": 5}
	var before := inventory.duplicate()
	var result := book.check_availability("test_recipe", inventory)
	assert_bool(result.available).is_false()
	assert_str(result.reason).is_equal("insufficient_ingredients")
	assert_dict(result.missing).is_equal({"test_a": 1, "test_b": 1})
	assert_dict(inventory).is_equal(before)

func test_query_distinguishes_unknown_recipe_from_invalid_input() -> void:
	var book := BOOK.new()
	assert_str(book.check_availability("test_recipe", {}).reason).is_equal("unknown_recipe")
	assert_str(book.check_availability(null, {}).reason).is_equal("invalid_recipe_id")
	assert_str(book.register_recipe(_fixture())).is_equal("ok")
	for invalid in [null, {"test_a": -1}, {"test_b": "1"}, {"": 3}]:
		var result := book.check_availability("test_recipe", invalid)
		assert_bool(result.available).is_false()
		assert_str(result.reason).is_equal("invalid_inventory")

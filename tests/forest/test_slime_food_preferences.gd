extends GdUnitTestSuite

const Catalog := preload("res://scripts/systems/slime_food_preferences.gd")


func test_known_ids_do_not_imply_pairs() -> void:
	var catalog := Catalog.new(PackedStringArray(['slime_a']), PackedStringArray(['food_a']))
	assert_bool(catalog.has_pair('slime_a', 'food_a')).is_false()
	assert_bool(catalog.foods_for('slime_a').is_empty()).is_true()


func test_pairs_are_unique_sorted_and_scoped_to_slime() -> void:
	var catalog := Catalog.new(PackedStringArray(['slime_a', 'slime_b']), PackedStringArray(['food_a', 'food_b']))
	assert_bool(catalog.catalog_pair('slime_a', 'food_b')).is_true()
	assert_bool(catalog.catalog_pair('slime_a', 'food_a')).is_true()
	assert_bool(catalog.catalog_pair('slime_a', 'food_b')).is_false()
	var foods := catalog.foods_for('slime_a')
	assert_bool(foods == PackedStringArray(['food_a', 'food_b'])).is_true()
	foods.clear()
	assert_bool(catalog.has_pair('slime_a', 'food_b')).is_true()
	assert_bool(catalog.foods_for('slime_b').is_empty()).is_true()


func test_invalid_ids_are_rejected_without_adding_pairs() -> void:
	var catalog := Catalog.new(PackedStringArray(['slime_a', '', ' slime_b']), PackedStringArray(['food_a', ' ', 'food_b ']))
	for id in ['', ' slime_b', 'SLIME_A', 'missing']:
		assert_bool(catalog.catalog_pair(id, 'food_a')).is_false()
		assert_bool(catalog.foods_for(id).is_empty()).is_true()
	for id in ['', ' ', 'food_b ', 'FOOD_A', 'missing']:
		assert_bool(catalog.catalog_pair('slime_a', id)).is_false()
		assert_bool(catalog.has_pair('slime_a', id)).is_false()
	assert_bool(catalog.foods_for('slime_a').is_empty()).is_true()

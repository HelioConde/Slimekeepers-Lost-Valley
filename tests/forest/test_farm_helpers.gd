extends GdUnitTestSuite

## Slimes amigos na fazenda: Brotinho planta, Bolhinha rega, Musguinho aduba
## (adubada e regada cresce dois estágios); limite diário por ajudante.

const Helpers := preload("res://scripts/world/farm_helpers.gd")
const Farm := preload("res://scripts/systems/farm_state.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
const F := "teste"


func before_test() -> void:
	for key in [Farm.KEY, Bag.INVENTORY_KEY, Helpers.KEY, "forest_slime_friends", "valley_slime_friends"]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func test_only_befriended_species_with_a_role_help() -> void:
	var tree := get_tree()
	assert_array(Helpers.helpers(tree)).is_empty()
	tree.set_meta("forest_slime_friends", {"brotinho/a/0": true, "musguinho/b/1": false})
	tree.set_meta("valley_slime_friends", {"bolhinha/c/2": true})
	assert_array(Helpers.helpers(tree)).contains_exactly_in_any_order(["brotinho", "bolhinha"])


func test_plant_water_and_fertilize_grow_two_stages() -> void:
	var tree := get_tree()
	var cell := Vector2i(3, 4)
	assert_bool(Farm.till(tree, cell, F)).is_true()
	assert_that(Helpers.job(tree, F, "brotinho")).is_equal(Helpers.NONE)  # sem semente
	Bag.add_item(tree, "semente_cenoura", 2)
	assert_that(Helpers.job(tree, F, "brotinho")).is_equal(cell)
	assert_bool(Helpers.apply(tree, F, "brotinho", cell, 1)).is_true()
	assert_str(Farm.crop(tree, cell, F)).is_equal("cenoura")
	assert_that(Helpers.job(tree, F, "bolhinha")).is_equal(cell)
	assert_bool(Helpers.apply(tree, F, "bolhinha", cell, 1)).is_true()
	assert_bool(Helpers.apply(tree, F, "musguinho", cell, 1)).is_true()
	assert_that(Helpers.job(tree, F, "musguinho")).is_equal(Helpers.NONE)  # já adubada
	Farm.advance_day(tree)
	assert_int(Farm.stage(tree, cell, F)).is_equal(2)
	assert_bool(Farm.is_fertilized(tree, cell, F)).is_false()  # adubo gasto


func test_daily_limit() -> void:
	var tree := get_tree()
	for x in Helpers.DAILY + 1:
		Farm.till(tree, Vector2i(x, 0), F)
	Bag.add_item(tree, "semente_cenoura", 10)
	for x in Helpers.DAILY:
		assert_bool(Helpers.apply(tree, F, "brotinho", Vector2i(x, 0), 7)).is_true()
	assert_bool(Helpers.apply(tree, F, "brotinho", Vector2i(Helpers.DAILY, 0), 7)).is_false()
	assert_bool(Helpers.apply(tree, F, "brotinho", Vector2i(Helpers.DAILY, 0), 8)).is_true()  # dia novo

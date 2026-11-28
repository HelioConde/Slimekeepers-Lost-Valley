extends GdUnitTestSuite

## Baú da casa: guarda pilhas da bolsa sem limite; tirar só o que cabe na bolsa;
## baú cheio impede tirar o baú e demolir a casa.

const Chest := preload("res://scripts/systems/chest_storage.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
const House := preload("res://scripts/systems/house_state.gd")


func before_test() -> void:
	for key in [Chest.KEY, Bag.INVENTORY_KEY, House.KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func test_store_and_take_whole_stacks() -> void:
	var tree := get_tree()
	Bag.add_item(tree, "madeira", 40)
	assert_int(Chest.store(tree, "madeira")).is_equal(40)
	assert_int(Bag.count_item(tree, "madeira")).is_equal(0)
	Bag.add_item(tree, "madeira", 90)
	assert_int(Chest.store(tree, "madeira")).is_equal(90)
	assert_int(Chest.count(tree, "madeira")).is_equal(130)  # sem o limite de 99
	assert_int(Chest.take(tree, "madeira")).is_equal(99)  # só o que cabe na bolsa
	assert_int(Chest.count(tree, "madeira")).is_equal(31)
	assert_int(Chest.store(tree, "pedra_pequena")).is_equal(0)  # nada na bolsa


func test_full_chest_blocks_removing_it_and_demolishing() -> void:
	var tree := get_tree()
	var rect := Rect2i(0, 0, 6, 5)
	for item in House.rect_cost(rect): Bag.add_item(tree, item, int(House.rect_cost(rect)[item]))
	for item in House.FURNITURE_COSTS.bau: Bag.add_item(tree, item, int(House.FURNITURE_COSTS.bau[item]))
	assert_str(House.build(tree, "floresta", rect)).is_empty()
	assert_str(House.place_furniture(tree, Vector2i(2, 2), "bau")).is_empty()
	Bag.add_item(tree, "fibra", 5)
	Chest.store(tree, "fibra")
	assert_bool(House.remove_furniture(tree, Vector2i(2, 2))).is_false()
	assert_bool(House.demolish(tree)).is_false()
	Chest.take(tree, "fibra")
	assert_bool(House.remove_furniture(tree, Vector2i(2, 2))).is_true()

extends GdUnitTestSuite

## Caixa de venda: colheitas vão para a caixa, são pagas na virada do dia.

const Ship := preload("res://scripts/systems/shipping_state.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
const Items := preload("res://scripts/systems/item_catalog.gd")


func before_test() -> void:
	for key in [Ship.MONEY_KEY, Ship.BIN_KEY, Bag.INVENTORY_KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func test_ship_crops_and_get_paid_next_day() -> void:
	var tree := get_tree()
	assert_int(Ship.money(tree)).is_equal(Ship.STARTING_MONEY)
	Bag.add_item(tree, "cenoura", 3)
	Bag.add_item(tree, "repolho", 1)
	Bag.add_item(tree, "semente_cenoura", 5)
	assert_int(Ship.ship_all(tree)).is_equal(4)
	assert_int(Bag.count_item(tree, "cenoura")).is_equal(0)
	assert_int(Bag.count_item(tree, "semente_cenoura")).is_equal(5)  # sementes não vão
	var expected := 3 * Items.price("cenoura") + Items.price("repolho")
	assert_int(Ship.bin_value(tree)).is_equal(expected)
	assert_int(Ship.pay_out(tree)).is_equal(expected)
	assert_int(Ship.money(tree)).is_equal(Ship.STARTING_MONEY + expected)
	assert_int(Ship.bin_value(tree)).is_equal(0)


func test_cannot_spend_more_than_owned() -> void:
	var tree := get_tree()
	assert_bool(Ship.spend_money(tree, Ship.STARTING_MONEY + 1)).is_false()
	assert_bool(Ship.spend_money(tree, 50)).is_true()
	assert_int(Ship.money(tree)).is_equal(Ship.STARTING_MONEY - 50)

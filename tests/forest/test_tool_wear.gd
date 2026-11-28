extends GdUnitTestSuite
## Durabilidade (playtest ID 43): o uso gasta, avisa perto do fim e quebra a ferramenta.

const Wear := preload("res://scripts/systems/tool_wear.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")


func before_test() -> void:
	for key in [Wear.KEY, Bag.INVENTORY_KEY, Bag.LAYOUT_KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func test_use_warns_then_breaks_and_new_tool_is_full() -> void:
	var tree := get_tree()
	Bag.add_item(tree, "pa")
	var total := Wear.max_uses("pa")
	assert_float(Wear.ratio(tree, "pa")).is_equal(1.0)
	var warned := false
	for i in total - 1:
		if Wear.use(tree, "pa").contains("quase"): warned = true
	assert_bool(warned).is_true()
	assert_int(Wear.left(tree, "pa")).is_equal(1)
	assert_str(Wear.use(tree, "pa")).contains("quebrou")
	assert_int(Bag.count_item(tree, "pa")).is_equal(0)
	Bag.add_item(tree, "pa")
	assert_int(Wear.left(tree, "pa")).is_equal(total)
	assert_bool(Wear.max_uses("machado_polido") > Wear.max_uses("machado")).is_true()

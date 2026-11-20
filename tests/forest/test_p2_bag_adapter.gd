extends GdUnitTestSuite
## Contrato da bolsa unico: coleta, plantio e culinaria compartilham SceneTree.
const BAG := preload("res://scripts/systems/forest_bag.gd")

func before_test() -> void:
	for key in [BAG.INVENTORY_KEY, BAG.PATCHES_KEY, BAG.FRIENDS_KEY]:
		if get_tree().has_meta(key):
			get_tree().remove_meta(key)

func after_test() -> void:
	before_test()

func test_legacy_zero_counts_are_normalized() -> void:
	var tree := get_tree()
	tree.set_meta(BAG.INVENTORY_KEY, {BAG.ITEM_ID: 0, BAG.LEAVES_ID: 2})
	assert_int(BAG.seeds(tree)).is_equal(0)
	assert_int(BAG.leaves(tree)).is_equal(2)
	assert_dict(BAG.inventory_snapshot(tree)).is_equal({BAG.LEAVES_ID: 2})
	assert_bool(BAG.spend_seed(tree)).is_false()
	assert_bool(BAG.spend_item(tree, BAG.LEAVES_ID)).is_true()
	assert_int(BAG.leaves(tree)).is_equal(1)

func test_add_and_spend_preserves_other_resource() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, BAG.ITEM_ID, 3)).is_true()
	assert_bool(BAG.add_item(tree, BAG.LEAVES_ID, 2)).is_true()
	assert_bool(BAG.spend_item(tree, BAG.LEAVES_ID)).is_true()
	assert_bool(BAG.spend_seed(tree)).is_true()
	assert_int(BAG.seeds(tree)).is_equal(2)
	assert_int(BAG.leaves(tree)).is_equal(1)
	assert_dict(BAG.inventory_snapshot(tree)).is_equal({BAG.ITEM_ID: 2, BAG.LEAVES_ID: 1})

func test_invalid_operations_leave_inventory_unchanged() -> void:
	var tree := get_tree()
	assert_bool(BAG.add_item(tree, BAG.ITEM_ID, 1)).is_true()
	var before := BAG.inventory_snapshot(tree)
	assert_bool(BAG.spend_item(tree, BAG.LEAVES_ID, 1)).is_false()
	assert_bool(BAG.spend_item(tree, BAG.ITEM_ID, 2)).is_false()
	assert_bool(BAG.add_item(tree, "", 1)).is_false()
	assert_bool(BAG.add_item(tree, BAG.ITEM_ID, 0)).is_false()
	assert_dict(BAG.inventory_snapshot(tree)).is_equal(before)
	tree.set_meta(BAG.INVENTORY_KEY, {BAG.ITEM_ID: 1, BAG.LEAVES_ID: -1})
	var malformed: Dictionary = tree.get_meta(BAG.INVENTORY_KEY).duplicate()
	assert_bool(BAG.add_item(tree, BAG.ITEM_ID, 1)).is_false()
	assert_bool(BAG.spend_item(tree, BAG.ITEM_ID, 1)).is_false()
	assert_dict(tree.get_meta(BAG.INVENTORY_KEY)).is_equal(malformed)

func test_brotinho_harvest_once_uses_shared_stock() -> void:
	var tree := get_tree()
	assert_bool(BAG.harvest(tree, "patch_a")).is_false()
	tree.set_meta(BAG.FRIENDS_KEY, {"brotinho/H01/0": true})
	assert_bool(BAG.harvest(tree, "patch_a")).is_true()
	assert_bool(BAG.harvest(tree, "patch_a")).is_false()
	assert_bool(BAG.harvest(tree, "patch_b")).is_true()
	assert_int(BAG.seeds(tree)).is_equal(2)
	assert_dict(BAG.inventory_snapshot(tree)).is_equal({BAG.ITEM_ID: 2})

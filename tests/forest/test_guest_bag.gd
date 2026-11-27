extends GdUnitTestSuite
## Continuar em dupla: a bolsa do convidado é guardada e devolvida pelo anfitrião.

const NET := preload("res://scripts/net/net_session.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")


func before_test() -> void:
	after_test()  # outra suíte pode deixar itens na bolsa


func after_test() -> void:
	for key in NET.BAG_KEYS + [NET.GUEST_BAGS_KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func test_store_and_restore_guest_bag() -> void:
	var tree := get_tree()
	BAG.add_item(tree, "graveto", 4)
	NET.store_guest_bag(tree, "moni", NET.bag_snapshot(tree))
	for key in NET.BAG_KEYS: if tree.has_meta(key): tree.remove_meta(key)
	assert_int(BAG.count_item(tree, "graveto")).is_equal(0)
	NET.apply_bag(tree, NET.guest_bag(tree, "moni"))
	assert_int(BAG.count_item(tree, "graveto")).is_equal(4)
	assert_bool(NET.guest_bag(tree, "aren").is_empty()).is_true()


func test_guest_bags_are_saved_with_the_session() -> void:
	assert_bool(preload("res://scripts/systems/session_state.gd").SESSION_META_KEYS.has(NET.GUEST_BAGS_KEY)).is_true()

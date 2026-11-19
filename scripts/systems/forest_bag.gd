extends RefCounted
## Inventario simples, somente na sessao: sem poderes magicos nem save em disco.
const ITEM_ID := "sementes_silvestres"
const INVENTORY_KEY := "forest_bag_items"
const PATCHES_KEY := "forest_seed_patches_collected"
const FRIENDS_KEY := "forest_slime_friends"

static func seeds(tree: SceneTree) -> int:
	var bag: Dictionary = tree.get_meta(INVENTORY_KEY, {})
	return maxi(0, int(bag.get(ITEM_ID, 0)))

static func has_brotinho_friend(tree: SceneTree) -> bool:
	var friends: Dictionary = tree.get_meta(FRIENDS_KEY, {})
	for identity in friends:
		if str(identity).begins_with("brotinho/") and bool(friends[identity]):
			return true
	return false

static func is_collected(tree: SceneTree, patch_id: String) -> bool:
	var patches: Dictionary = tree.get_meta(PATCHES_KEY, {})
	return bool(patches.get(patch_id, false))

static func harvest(tree: SceneTree, patch_id: String) -> bool:
	# Both gates are checked before any session state changes.
	if patch_id.is_empty() or not has_brotinho_friend(tree) or is_collected(tree, patch_id):
		return false
	var bag: Dictionary = tree.get_meta(INVENTORY_KEY, {}).duplicate()
	var patches: Dictionary = tree.get_meta(PATCHES_KEY, {}).duplicate()
	bag[ITEM_ID] = seeds(tree) + 1
	patches[patch_id] = true
	tree.set_meta(INVENTORY_KEY, bag)
	tree.set_meta(PATCHES_KEY, patches)
	return true

extends RefCounted
## Alimentar slimes com colheitas e comida cozida (no lugar de vender): cria laço.
## Cada slime come uma vez por dia; comida cozida vale mais que colheita crua.
## Sem favoritismo por espécie (nada inventado além da Bíblia).

const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const KEY := "slime_affinity"
const FED_KEY := "slime_fed_day"
const POINTS := {"crop": 10, "food": 25}
const HEART := 50
const MAX_HEARTS := 10


static func points(tree: SceneTree, slime_id: String) -> int:
	return int(tree.get_meta(KEY, {}).get(slime_id, 0))


static func hearts(tree: SceneTree, slime_id: String) -> int:
	return mini(MAX_HEARTS, points(tree, slime_id) / HEART)


static func is_food(item_id: String) -> bool:
	return POINTS.has(ITEMS.kind(item_id))


static func fed_today(tree: SceneTree, slime_id: String, day: int) -> bool:
	return int(tree.get_meta(FED_KEY, {}).get(slime_id, 0)) == day


## Resultado: fed, needs_friendship, not_food, no_item, already_fed.
static func feed(tree: SceneTree, slime_id: String, is_friend: bool, item_id: String, day: int) -> String:
	if not is_friend:
		return "needs_friendship"
	if not is_food(item_id):
		return "not_food"
	if fed_today(tree, slime_id, day):
		return "already_fed"
	if not BAG.spend_item(tree, item_id, 1):
		return "no_item"
	var affinity: Dictionary = tree.get_meta(KEY, {}).duplicate()
	affinity[slime_id] = points(tree, slime_id) + int(POINTS[ITEMS.kind(item_id)])
	tree.set_meta(KEY, affinity)
	var fed: Dictionary = tree.get_meta(FED_KEY, {}).duplicate()
	fed[slime_id] = day
	tree.set_meta(FED_KEY, fed)
	return "fed"

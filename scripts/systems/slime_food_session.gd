extends RefCounted
## Oferta de refeicao de prototipo, independente do sistema canonico de amizade.
## Uma oferta por identidade persistente de slime; sem efeito magico nem favoritismo.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
const BOND := preload("res://scripts/systems/slime_food_bond.gd")
const OFFERS_KEY := "slime_food_offers"

static func first_food_for(tree: SceneTree, slime_id: String) -> String:
	if not tree.has_meta(OFFERS_KEY):
		return ""
	var rows: Variant = tree.get_meta(OFFERS_KEY)
	if not rows is Array:
		return ""
	for row in rows:
		if row is Dictionary and row.get("slime_id") == slime_id:
			return str(row.get("food_id", ""))
	return ""

## Nao substitui amizade; só slimes ja conhecidos podem receber o teste.
## A copia do registro e preparada antes do debito. Falhas nao gastam porcoes.
## spend=false: só registra (a porção já foi gasta por slime_feeding.feed).
static func offer(tree: SceneTree, slime_id: String, is_friend: bool, spend: bool = true) -> String:
	if slime_id.strip_edges().is_empty() or not slime_id.contains("/"):
		return "invalid_slime"
	if not is_friend:
		return "needs_friendship"
	var rows: Variant = tree.get_meta(OFFERS_KEY, [])
	if not rows is Array:
		return "invalid_state"
	var slime_ids: Array = [slime_id]
	for row in rows:
		if not row is Dictionary or typeof(row.get("slime_id")) != TYPE_STRING:
			return "invalid_state"
		var known: String = row["slime_id"]
		if not slime_ids.has(known):
			slime_ids.append(known)
	var bond = BOND.new(slime_ids, [COOKING.RECIPE_ID])
	if not bond.load_state(rows):
		return "invalid_state"
	if not bond.first_food_for(slime_id).is_empty():
		return "already_offered"
	if spend and BAG.count_item(tree, COOKING.RECIPE_ID) <= 0:
		return "needs_portion"
	if not bond.offer(slime_id, COOKING.RECIPE_ID):
		return "invalid_state"
	if spend and not BAG.spend_item(tree, COOKING.RECIPE_ID, 1):
		return "needs_portion"
	tree.set_meta(OFFERS_KEY, bond.save_state())
	return "offered"

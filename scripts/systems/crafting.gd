extends RefCounted
## Fabricação orientada a dados: receitas em res://data/crafting/recipes.gd.
## Estações: "maos" (em qualquer lugar) e "bancada" (só junto à bancada de trabalho).
## Transação atômica na bolsa da sessão: ou gasta tudo e entrega, ou não muda nada.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const DATA := preload("res://data/crafting/recipes.gd")


static func recipes(station: String = "") -> Array:
	if station.is_empty():
		return DATA.RECIPES
	return DATA.RECIPES.filter(func(r: Dictionary) -> bool: return str(r.station) == station)


static func recipe(recipe_id: String) -> Dictionary:
	for r: Dictionary in recipes():
		if str(r.id) == recipe_id:
			return r
	return {}


## "" quando dá para fazer; senão o motivo, pronto para mostrar ao jogador.
static func missing(tree: SceneTree, recipe_id: String) -> String:
	var r := recipe(recipe_id)
	if r.is_empty():
		return "Receita desconhecida."
	for tool_id: String in r.get("requires", []):
		if BAG.count_item(tree, tool_id) <= 0:
			return "Precisa de " + _name(tool_id) + "."
	for item_id: String in r.output:
		if BAG.count_item(tree, item_id) + int(r.output[item_id]) > ITEMS.max_stack(item_id):
			return ("Você já tem " if ITEMS.max_stack(item_id) == 1 else "Sem espaço para ") + _name(item_id) + "."
	var lacking: PackedStringArray = []
	for item_id: String in r.inputs:
		var need := int(r.inputs[item_id]) - BAG.count_item(tree, item_id)
		if need > 0:
			lacking.append("%d %s" % [need, _name(item_id)])
	return "" if lacking.is_empty() else "Falta: " + ", ".join(lacking) + "."


static func can_craft(tree: SceneTree, recipe_id: String) -> bool:
	return missing(tree, recipe_id).is_empty()


## Gasta os ingredientes e entrega o resultado numa única gravação da bolsa.
static func craft(tree: SceneTree, recipe_id: String) -> bool:
	if not can_craft(tree, recipe_id):
		return false
	var r := recipe(recipe_id)
	var snapshot := BAG.inventory_snapshot(tree)
	for item_id: String in r.inputs:
		snapshot[item_id] = int(snapshot.get(item_id, 0)) - int(r.inputs[item_id])
		if int(snapshot[item_id]) <= 0:
			snapshot.erase(item_id)
	for item_id: String in r.output:
		snapshot[item_id] = int(snapshot.get(item_id, 0)) + int(r.output[item_id])
	tree.set_meta(BAG.INVENTORY_KEY, snapshot)
	return true


static func _name(item_id: String) -> String:
	return str(ITEMS.info(item_id).name).to_lower()

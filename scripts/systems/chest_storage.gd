extends RefCounted
## Baú da casa (BACKLOG P2): guarda itens da bolsa sem o limite de 99 por pilha.
## Fica na sessão (e no save em disco). Mover é atômico por unidade: o que não cabe
## na bolsa fica no baú.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const KEY := "chest_items"


static func items(tree: SceneTree) -> Dictionary:
	return (tree.get_meta(KEY, {}) as Dictionary).duplicate()


static func count(tree: SceneTree, item: String) -> int:
	return int(items(tree).get(item, 0))


static func is_empty(tree: SceneTree) -> bool:
	return items(tree).is_empty()


## Guarda toda a pilha do item no baú. Devolve quantos foram guardados.
static func store(tree: SceneTree, item: String) -> int:
	var amount := BAG.count_item(tree, item)
	if amount <= 0 or not BAG.spend_item(tree, item, amount): return 0
	var data := items(tree)
	data[item] = int(data.get(item, 0)) + amount
	tree.set_meta(KEY, data)
	return amount


## Tira do baú para a bolsa o quanto couber. Devolve quantos foram tirados.
static func take(tree: SceneTree, item: String) -> int:
	var data := items(tree)
	var stored := int(data.get(item, 0))
	var moved := 0
	while moved < stored and BAG.add_item(tree, item, 1):
		moved += 1
	if moved == stored: data.erase(item)
	else: data[item] = stored - moved
	tree.set_meta(KEY, data)
	return moved

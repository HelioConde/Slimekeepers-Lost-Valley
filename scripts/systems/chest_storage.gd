extends RefCounted
## Baú da casa (BACKLOG P2): guarda itens da bolsa sem o limite de 99 por pilha.
## Fica na sessão (e no save em disco). Mover é atômico por unidade: o que não cabe
## na bolsa fica no baú.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const KEY := "chest_items"
## Baús colocados no chão (2026-11-23): {id do baú: {item: quantidade}}. "" = baú da casa.
const PLACED_KEY := "placed_chest_items"


static func items(tree: SceneTree, chest: String = "") -> Dictionary:
	if chest.is_empty(): return (tree.get_meta(KEY, {}) as Dictionary).duplicate()
	return ((tree.get_meta(PLACED_KEY, {}) as Dictionary).get(chest, {}) as Dictionary).duplicate()


static func _write(tree: SceneTree, chest: String, data: Dictionary) -> void:
	if chest.is_empty():
		tree.set_meta(KEY, data)
		return
	var all: Dictionary = (tree.get_meta(PLACED_KEY, {}) as Dictionary).duplicate()
	all[chest] = data
	tree.set_meta(PLACED_KEY, all)


static func count(tree: SceneTree, item: String, chest: String = "") -> int:
	return int(items(tree, chest).get(item, 0))


static func is_empty(tree: SceneTree, chest: String = "") -> bool:
	return items(tree, chest).is_empty()


## Põe itens direto no baú (slime Carreguim), sem passar pela bolsa.
static func deposit(tree: SceneTree, item: String, amount: int, chest: String = "") -> void:
	if amount <= 0: return
	var data := items(tree, chest)
	data[item] = int(data.get(item, 0)) + amount
	_write(tree, chest, data)


## Guarda toda a pilha do item no baú. Devolve quantos foram guardados.
static func store(tree: SceneTree, item: String, chest: String = "") -> int:
	var amount := BAG.count_item(tree, item)
	if amount <= 0 or not BAG.spend_item(tree, item, amount): return 0
	deposit(tree, item, amount, chest)
	return amount


## Tira do baú para a bolsa o quanto couber. Devolve quantos foram tirados.
static func take(tree: SceneTree, item: String, chest: String = "") -> int:
	var data := items(tree, chest)
	var stored := int(data.get(item, 0))
	var moved := 0
	while moved < stored and BAG.add_item(tree, item, 1):
		moved += 1
	if moved == stored: data.erase(item)
	else: data[item] = stored - moved
	_write(tree, chest, data)
	return moved

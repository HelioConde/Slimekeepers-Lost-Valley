extends RefCounted
## Energia do jogador na sessão: ferramentas gastam; só dormir (ou comer) recupera —
## a virada do dia sozinha não devolve energia (relatório de playtest ID 39).

const KEY := "player_energy"
const MAX := 100
const COSTS := {"till": 4, "water": 2, "chop": 3, "process": 2}  # machado: CRIACAO.md
## Comer recupera energia (BACKLOG P3): colheita crua e porção cozida.
const FOOD_ENERGY := preload("res://scripts/systems/item_catalog.gd").FOOD_ENERGY


static func current(tree: SceneTree) -> int:
	return clampi(int(tree.get_meta(KEY, MAX)), 0, MAX)


static func can_afford(tree: SceneTree, action: String) -> bool:
	return current(tree) >= int(COSTS.get(action, 0))


## Gasta a energia da ação; false (sem gastar nada) se não houver o bastante.
static func spend(tree: SceneTree, action: String) -> bool:
	var cost := int(COSTS.get(action, 0))
	if current(tree) < cost:
		return false
	tree.set_meta(KEY, current(tree) - cost)
	return true


static func restore(tree: SceneTree, amount: int = MAX) -> void:
	tree.set_meta(KEY, mini(MAX, current(tree) + amount))

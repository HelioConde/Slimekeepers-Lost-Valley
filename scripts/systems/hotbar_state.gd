extends RefCounted
## Barra rápida: 10 espaços. Ferramentas primeiro, depois sementes e colheitas que
## existem na bolsa. O espaço selecionado fica na sessão.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const SLOTS := 10
const SELECTED_KEY := "hotbar_selected"


## Lista de ids nos 10 espaços ("" = vazio).
## Os 10 primeiros espaços da bolsa (forest_bag.layout); o resto é a mochila do [E].
static func slots(tree: SceneTree) -> Array[String]:
	return BAG.layout(tree).slice(0, SLOTS)


static func selected_index(tree: SceneTree) -> int:
	return clampi(int(tree.get_meta(SELECTED_KEY, 0)), 0, SLOTS - 1)


static func select(tree: SceneTree, index: int) -> void:
	tree.set_meta(SELECTED_KEY, posmod(index, SLOTS))


static func selected_item(tree: SceneTree) -> String:
	return slots(tree)[selected_index(tree)]


static func count(tree: SceneTree, item_id: String) -> int:
	if ITEMS.kind(item_id) == "tool":
		return 0
	return BAG.count_item(tree, item_id)

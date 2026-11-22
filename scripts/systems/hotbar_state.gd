extends RefCounted
## Barra rápida: 10 espaços. Ferramentas primeiro, depois sementes e colheitas que
## existem na bolsa. O espaço selecionado fica na sessão.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const SLOTS := 10
const SELECTED_KEY := "hotbar_selected"


## Lista de ids nos 10 espaços ("" = vazio).
static func slots(tree: SceneTree) -> Array[String]:
	var result: Array[String] = []
	for tool in ITEMS.TOOLS:  # só as ferramentas que o jogador já fabricou
		if BAG.count_item(tree, tool) > 0 or (ITEMS.FREE_STARTER_TOOLS and tool in ITEMS.STARTER_TOOLS):
			result.append(tool)
	for item in ITEMS.ORDER:
		if result.size() >= SLOTS:
			break
		if BAG.count_item(tree, item) > 0:
			result.append(item)
	while result.size() < SLOTS:
		result.append("")
	return result


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

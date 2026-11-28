extends RefCounted
## Durabilidade das ferramentas (relatório de playtest ID 43): cada golpe que acerta gasta
## usos; ao chegar a zero a ferramenta quebra e sai da bolsa (fabrique outra). Aviso quando
## está quase quebrando. As de pedra polida duram mais. Uma ferramenta nova começa cheia.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const KEY := "tool_wear"  ## {ferramenta: usos que faltam}
const MAX_USES := {"machado": 80, "picareta": 80, "foice": 120, "enxada": 100, "regador": 150, "pa": 60,
	"machado_polido": 160, "picareta_polida": 160}
const WARN_AT := 10


static func max_uses(tool: String) -> int:
	return int(MAX_USES.get(tool, 100))


static func left(tree: SceneTree, tool: String) -> int:
	return int((tree.get_meta(KEY, {}) as Dictionary).get(tool, max_uses(tool)))


## Fração restante (1 = nova) para a barrinha da barra rápida.
static func ratio(tree: SceneTree, tool: String) -> float:
	return clampf(float(left(tree, tool)) / float(max_uses(tool)), 0.0, 1.0)


## Gasta `amount` usos. Devolve um aviso para o jogador ("" = nada a dizer).
static func use(tree: SceneTree, tool: String, amount: int = 1) -> String:
	if not MAX_USES.has(tool) or BAG.count_item(tree, tool) <= 0: return ""
	var wear: Dictionary = (tree.get_meta(KEY, {}) as Dictionary).duplicate()
	var now := left(tree, tool) - amount
	var tool_name := str(ITEMS.info(tool).name)
	if now <= 0:
		wear.erase(tool)  # a próxima começa cheia
		tree.set_meta(KEY, wear)
		BAG.spend_item(tree, tool, 1)
		return "%s quebrou! Fabrique outra na bancada." % tool_name
	wear[tool] = now
	tree.set_meta(KEY, wear)
	if now == WARN_AT: return "%s está quase quebrando (%d usos)." % [tool_name, now]
	return ""

extends RefCounted
## Pedidos dos slimes (decisão de 2026-11-23, opção recomendada): de vez em quando um slime
## amigo quer uma comida e mostra um balãozinho com ela por cima da cabeça (nada no HUD,
## sem lista de missões). Dar a comida pedida rende laço extra e, às vezes, uma semente.
## O pedido é sorteado por slime e por dia (sempre o mesmo naquele dia).

const FEEDING := preload("res://scripts/systems/slime_feeding.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const KEY := "slime_requests_done"  ## {id do slime: dia atendido}
const CHANCE := 0.35
const BONUS := 25  ## pontos de laço extras (meio coração)
const SEED_GIFT_CHANCE := 0.5
const CROPS := ["cenoura", "beterraba", "repolho", "folhas_frescas"]
const COOKED := ["cenoura_assada", "sopa_legumes"]
const SEEDS := ["semente_cenoura", "semente_beterraba", "semente_repolho", "sementes_silvestres"]


## Comida que o slime quer hoje ("" = nenhum pedido ou já atendido).
static func wanted(tree: SceneTree, slime_id: String, species: String, day: int) -> String:
	if int((tree.get_meta(KEY, {}) as Dictionary).get(slime_id, -1)) == day: return ""
	var roll := float(posmod(hash("%s#pedido#%d" % [slime_id, day]), 10000)) / 10000.0
	if roll >= CHANCE: return ""
	var pool: Array = COOKED if FEEDING.LIKES.get(species, "") == "cozido" else CROPS
	return str(pool[posmod(hash("%s#item#%d" % [slime_id, day]), pool.size())])


## Atende o pedido se `item` for o pedido de hoje. Devolve a semente ganha ("" sem semente),
## "ok" sem semente, ou "" se não era o pedido.
static func fulfill(tree: SceneTree, slime_id: String, species: String, day: int, item: String) -> String:
	if item.is_empty() or wanted(tree, slime_id, species, day) != item: return ""
	var done: Dictionary = (tree.get_meta(KEY, {}) as Dictionary).duplicate()
	done[slime_id] = day
	tree.set_meta(KEY, done)
	var affinity: Dictionary = (tree.get_meta(FEEDING.KEY, {}) as Dictionary).duplicate()
	affinity[slime_id] = FEEDING.points(tree, slime_id) + BONUS
	tree.set_meta(FEEDING.KEY, affinity)
	if float(posmod(hash("%s#presente#%d" % [slime_id, day]), 100)) / 100.0 < SEED_GIFT_CHANCE:
		var seed_id: String = SEEDS[posmod(hash("%s#semente#%d" % [slime_id, day]), SEEDS.size())]
		BAG.add_item(tree, seed_id, 1)
		return seed_id
	return "ok"

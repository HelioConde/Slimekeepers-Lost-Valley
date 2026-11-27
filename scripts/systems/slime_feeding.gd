extends RefCounted
## Alimentar slimes com colheitas e comida cozida (no lugar de vender): cria laço.
## Cada slime come uma vez por dia; comida cozida vale mais que colheita crua.
## Preferência por habitat (pedido do usuário, 2026-11-22; docs/gameplay/COMIDA_DOS_SLIMES.md):
## comida do grupo que a espécie prefere dá o dobro de pontos. Brotinho, Musguinho e
## Bolhinha têm preferência por ingrediente (PREFS, playtest ID 59); LIKES fica como dica do HUD.
const LIKES := {"brotinho": "vegetal", "musguinho": "vegetal", "bolhinha": "marinha",
	"colhita": "cozido", "carreguim": "cozido",  # Colhita e Carreguim preferem pratos cozidos (2026-11-23)
	"construlim": "raiz"}  # Construlim: raízes cruas (cenoura, beterraba), escolha do usuário 2026-11-23
const ROOTS := ["cenoura", "beterraba"]

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


## Preferência por ingrediente (playtest ID 59; valores provisórios, ver COMIDA_DOS_SLIMES.md).
## Fora da tabela = neutro. Espécies sem tabela usam LIKES (favorito = amado).
const PREFS := {
	"brotinho": {"cenoura": "amado", "folhas_frescas": "gostado", "beterraba": "gostado"},
	"musguinho": {"folhas_frescas": "amado", "repolho": "gostado"},
	"bolhinha": {"repolho": "amado", "beterraba": "gostado"},
}
const LEVEL_SCORE := {"amado": 2, "gostado": 1, "neutro": 0}
const LEVEL_MULT := {"amado": 2.0, "gostado": 1.5, "neutro": 1.0}
const KNOWN_KEY := "slime_food_known"  # {espécie: {item: nível}} — o que o jogador já descobriu
const RECIPES := preload("res://data/crafting/recipes.gd")


## Pontos de laço: cozida > crua, vezes o nível de preferência da espécie.
static func gain(item_id: String, species: String = "") -> int:
	var base := int(POINTS.get(ITEMS.kind(item_id), 0))
	return roundi(base * float(LEVEL_MULT[preference(item_id, species)]))


## "amado", "gostado" ou "neutro". Prato: média dos ingredientes da receita
## (combinar ingredientes amados dá prato mais atraente).
static func preference(item_id: String, species: String) -> String:
	if not PREFS.has(species):
		return "amado" if _likes(item_id, species) else "neutro"
	var table: Dictionary = PREFS[species]
	if table.has(item_id): return str(table[item_id])
	var inputs := _recipe_inputs(item_id)
	if inputs.is_empty(): return "neutro"
	var total := 0
	var count := 0
	for ingredient: String in inputs:
		total += int(LEVEL_SCORE[str(table.get(ingredient, "neutro"))]) * int(inputs[ingredient])
		count += int(inputs[ingredient])
	var avg := float(total) / count
	return "amado" if avg >= 1.5 else ("gostado" if avg >= 0.5 else "neutro")


static func _recipe_inputs(item_id: String) -> Dictionary:
	for recipe: Dictionary in RECIPES.RECIPES:
		if (recipe.output as Dictionary).has(item_id): return recipe.inputs
	return {}


## Nível já descoberto pelo jogador ("" = ainda não provou).
static func known_preference(tree: SceneTree, item_id: String, species: String) -> String:
	return str((tree.get_meta(KNOWN_KEY, {}) as Dictionary).get(species, {}).get(item_id, ""))


## Frase da reação depois de comer.
static func reaction_text(level: String) -> String:
	return {"amado": "amou! É o favorito", "gostado": "gostou", "neutro": "aceitou, sem muita vontade"}.get(level, "comeu")


## Comida favorita (amada) da espécie.
static func is_favorite(item_id: String, species: String) -> bool:
	return preference(item_id, species) == "amado"


## Grupo de LIKES. "cozido" = qualquer prato do fogão (Colhita, Carreguim).
static func _likes(item_id: String, species: String) -> bool:
	var liked: String = LIKES.get(species, "")
	if liked.is_empty(): return false
	if liked == "cozido": return ITEMS.kind(item_id) == "food"
	if liked == "raiz": return item_id in ROOTS
	return ITEMS.food_group(item_id) == liked


## Resultado: fed, needs_friendship, not_food, no_item, already_fed.
static func feed(tree: SceneTree, slime_id: String, is_friend: bool, item_id: String, day: int, species: String = "") -> String:
	if not is_friend:
		return "needs_friendship"
	if not is_food(item_id):
		return "not_food"
	if fed_today(tree, slime_id, day):
		return "already_fed"
	if not BAG.spend_item(tree, item_id, 1):
		return "no_item"
	var affinity: Dictionary = tree.get_meta(KEY, {}).duplicate()
	affinity[slime_id] = points(tree, slime_id) + gain(item_id, species)
	tree.set_meta(KEY, affinity)
	var fed: Dictionary = tree.get_meta(FED_KEY, {}).duplicate()
	fed[slime_id] = day
	tree.set_meta(FED_KEY, fed)
	if not species.is_empty():
		var known: Dictionary = (tree.get_meta(KNOWN_KEY, {}) as Dictionary).duplicate(true)
		var per: Dictionary = known.get(species, {})
		per[item_id] = preference(item_id, species)
		known[species] = per
		tree.set_meta(KNOWN_KEY, known)
	return "fed"

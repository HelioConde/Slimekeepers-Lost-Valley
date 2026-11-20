extends RefCounted
## Integracao jogavel de culinaria - porcao de teste, sem efeitos/nome canonicamente aprovados.
## Uma folha fresca da bolsa gera um preparo de teste; nao e item de inventario nem bonus de slime.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const BOOK := preload("res://scripts/systems/cooking_recipe_book.gd")
const LEDGER := preload("res://scripts/systems/cooking_serving_ledger.gd")
const RECIPE_ID := "porcao_folhas_prototipo"
const LEDGER_KEY := "valley_cooking_ledger"

static func _recipe_book() -> Variant:
	var book = BOOK.new()
	book.register_recipe({"id": RECIPE_ID, "ingredients": {"folhas_frescas": 1}})
	return book

static func availability(tree: SceneTree) -> Dictionary:
	return _recipe_book().check_availability(RECIPE_ID, BAG.inventory_snapshot(tree))

static func portions(tree: SceneTree) -> int:
	var current: Variant = tree.get_meta(LEDGER_KEY, null)
	if current == null:
		return 0
	if typeof(current) != TYPE_OBJECT or not current.has_method("count_for"):
		return -1
	return current.count_for(RECIPE_ID)

## Nenhuma folha e gasta quando a validacao de receita/registro falha.
## O registro e preparado em uma instancia separada ANTES da transacao de debito.
static func prepare(tree: SceneTree) -> String:
	var check: Dictionary = availability(tree)
	if not bool(check.get("available", false)):
		return "needs_leaves" if check.get("reason") == "insufficient_ingredients" else "invalid_recipe"
	var previous := portions(tree)
	if previous < 0:
		return "invalid_ledger"
	var replacement = LEDGER.new()
	if previous > 0 and not replacement.record_preparation(RECIPE_ID, previous):
		return "invalid_ledger"
	if not replacement.record_preparation(RECIPE_ID, 1):
		return "invalid_ledger"
	if not BAG.spend_item(tree, BAG.LEAVES_ID, 1):
		return "needs_leaves"
	tree.set_meta(LEDGER_KEY, replacement)
	return "prepared"

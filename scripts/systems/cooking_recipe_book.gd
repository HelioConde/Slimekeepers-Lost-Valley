extends RefCounted
## Registro de sessão, inicialmente vazio. IDs são Strings sem espaços nas extremidades.
var _requirements: Dictionary = {}

## Dados esperados: {"id": String, "ingredients": {id_do_item: quantidade_positiva}}.
## Retorna "ok" ou a razão da recusa; uma recusa nunca altera o registro.
func register_recipe(data: Variant) -> String:
	if not (data is Dictionary):
		return "invalid_recipe"
	var recipe_id: Variant = data.get("id")
	if not _valid_id(recipe_id):
		return "invalid_recipe_id"
	var ingredients: Variant = data.get("ingredients")
	if not _valid_counts(ingredients, 1) or ingredients.is_empty():
		return "invalid_ingredients"
	if _requirements.has(recipe_id):
		return "duplicate_recipe"
	_requirements[recipe_id] = ingredients.duplicate()
	return "ok"

## Consulta um retrato do inventário. Itens ausentes contam como zero.
## missing contém apenas os déficits, não as quantidades totais da receita.
func check_availability(recipe_id: Variant, inventory: Variant) -> Dictionary:
	if not _valid_id(recipe_id):
		return _result("invalid_recipe_id")
	if not _requirements.has(recipe_id):
		return _result("unknown_recipe")
	if not _valid_counts(inventory, 0):
		return _result("invalid_inventory")
	var required: Dictionary = _requirements[recipe_id]
	var missing: Dictionary = {}
	for item_id in required:
		var available: int = inventory.get(item_id, 0)
		var needed: int = required[item_id]
		if available < needed:
			missing[item_id] = needed - available
	return _result("ok" if missing.is_empty() else "insufficient_ingredients", missing)

func _result(reason: String, missing: Dictionary = {}) -> Dictionary:
	return {"available": reason == "ok", "reason": reason, "missing": missing}

func _valid_id(value: Variant) -> bool:
	return value is String and not value.is_empty() and value == value.strip_edges()

func _valid_counts(counts: Variant, minimum: int) -> bool:
	if not (counts is Dictionary):
		return false
	for item_id in counts:
		if not _valid_id(item_id):
			return false
		var count: Variant = counts[item_id]
		if not (count is int) or count < minimum:
			return false
	return true

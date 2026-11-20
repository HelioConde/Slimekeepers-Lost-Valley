extends RefCounted
## Consulta de ingredientes sem acesso à cena ou ao inventário da sessão.

## Ambos os mapas usam IDs String não brancos e quantidades int >= 0.
## Um ID ausente no estoque vale zero. Uma necessidade vazia é satisfeita.
## Dados inválidos não produzem um cálculo parcial de faltas.
static func check(required: Variant, stock: Variant) -> Dictionary:
	if not _is_quantity_map(required) or not _is_quantity_map(stock):
		return {"valid": false, "available": false, "missing": {}}

	var ids: Array = required.keys()
	ids.sort()
	var missing: Dictionary = {}
	for id: String in ids:
		var needed: int = required[id]
		var held: int = stock.get(id, 0)
		if needed > held:
			missing[id] = needed - held
	return {"valid": true, "available": missing.is_empty(), "missing": missing}

static func _is_quantity_map(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	for id: Variant in value:
		if typeof(id) != TYPE_STRING or id.strip_edges().is_empty():
			return false
		if typeof(value[id]) != TYPE_INT or value[id] < 0:
			return false
	return true

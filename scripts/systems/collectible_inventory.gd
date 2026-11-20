extends RefCounted
## Bolsa de sessão. O formato de salvamento é um Dictionary de String para int.
## IDs são exatos; quantidades devem ser positivas. Saldo zero é representado por ausência.

const MAX_QUANTITY: int = 0x7fffffffffffffff

var _items: Dictionary[String, int] = {}


static func _valid_id(item_id: Variant) -> bool:
	return typeof(item_id) == TYPE_STRING and not item_id.strip_edges().is_empty()


static func _valid_quantity(quantity: Variant) -> bool:
	return typeof(quantity) == TYPE_INT and quantity > 0


func count(item_id: Variant) -> int:
	if not _valid_id(item_id):
		return 0
	return _items.get(item_id, 0)


func add(item_id: Variant, quantity: Variant = 1) -> bool:
	if not _valid_id(item_id) or not _valid_quantity(quantity):
		return false
	var current := count(item_id)
	if quantity > MAX_QUANTITY - current:
		return false
	_items[item_id] = current + quantity
	return true


func remove(item_id: Variant, quantity: Variant = 1) -> bool:
	if not _valid_id(item_id) or not _valid_quantity(quantity):
		return false
	var current := count(item_id)
	if quantity > current:
		return false
	if quantity == current:
		_items.erase(item_id)
	else:
		_items[item_id] = current - quantity
	return true


func serialize() -> Dictionary:
	return _items.duplicate()


## Substitui a bolsa inteira somente após validar todas as entradas.
func deserialize(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var replacement: Dictionary[String, int] = {}
	for item_id in data:
		if not _valid_id(item_id) or not _valid_quantity(data[item_id]):
			return false
		replacement[item_id] = data[item_id]
	_items = replacement
	return true

extends RefCounted
## Índice de pares catalogados, não de comidas favoritas. Os vocabulários
## de IDs vêm do chamador; nenhum par é criado automaticamente.

var _foods_by_slime: Dictionary[String, PackedStringArray] = {}
var _known_foods: Dictionary[String, bool] = {}


func _init(slime_ids: PackedStringArray = PackedStringArray(), food_ids: PackedStringArray = PackedStringArray()) -> void:
	for id in slime_ids:
		if _valid_id(id):
			_foods_by_slime[id] = PackedStringArray()
	for id in food_ids:
		if _valid_id(id):
			_known_foods[id] = true


## Retorna true somente quando insere um par novo com dois IDs conhecidos.
func catalog_pair(slime_id: String, food_id: String) -> bool:
	if not _foods_by_slime.has(slime_id) or not _known_foods.has(food_id):
		return false
	var foods: PackedStringArray = _foods_by_slime[slime_id]
	if foods.has(food_id):
		return false
	foods.append(food_id)
	foods.sort()
	_foods_by_slime[slime_id] = foods
	return true


func has_pair(slime_id: String, food_id: String) -> bool:
	return _foods_by_slime.has(slime_id) and _foods_by_slime[slime_id].has(food_id)


## Cópia ordenada por ID; vazia para slime desconhecido ou sem registros.
func foods_for(slime_id: String) -> PackedStringArray:
	if not _foods_by_slime.has(slime_id):
		return PackedStringArray()
	return _foods_by_slime[slime_id].duplicate()


static func _valid_id(id: String) -> bool:
	return not id.is_empty() and id == id.strip_edges()

extends RefCounted
## Registro de ofertas, não de amizade: cada slime tem no máximo um marco,
## identificado pelo primeiro alimento oferecido. Não calcula afinidade.

var _slimes: Dictionary = {}
var _foods: Dictionary = {}
var _first_food: Dictionary = {}

func _init(slime_ids: Array, food_ids: Array) -> void:
	_slimes = _catalog(slime_ids)
	_foods = _catalog(food_ids)

func _catalog(ids: Array) -> Dictionary:
	var result := {}
	for id in ids:
		if id is String and not id.is_empty() and id == id.strip_edges():
			result[id] = true
	return result

## Retorna true somente quando a oferta acrescenta um marco ao registro.
func offer(slime_id: String, food_id: String) -> bool:
	if not _slimes.has(slime_id) or not _foods.has(food_id) or _first_food.has(slime_id):
		return false
	_first_food[slime_id] = food_id
	return true

## String vazia indica ausência de uma oferta registrada.
func first_food_for(slime_id: String) -> String:
	return _first_food.get(slime_id, "")

## Linhas independentes do estado interno, ordenadas pelo ID persistente.
func save_state() -> Array:
	var ids := _first_food.keys()
	ids.sort()
	var rows := []
	for id in ids:
		rows.append({"slime_id": id, "food_id": _first_food[id]})
	return rows

## Substitui todo o estado apenas se cada linha for válida e única.
func load_state(data: Variant) -> bool:
	if not data is Array:
		return false
	var restored := {}
	for row in data:
		if not row is Dictionary or row.size() != 2:
			return false
		var slime_id: Variant = row.get("slime_id")
		var food_id: Variant = row.get("food_id")
		if not slime_id is String or not food_id is String:
			return false
		if not _slimes.has(slime_id) or not _foods.has(food_id) or restored.has(slime_id):
			return false
		restored[slime_id] = food_id
	_first_food = restored
	return true

extends RefCounted
## Registro por instância, sem dependência de cena, relógio ou inventário.
## O chamador identifica cada ciclo por um inteiro não negativo.

# ciclo -> canteiro -> {recurso: quantidade}
var _cycles: Dictionary = {}


static func _valid_id(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING:
		return false
	var id: String = value
	return not id.is_empty() and id == id.strip_edges()


static func _valid_resources(resources: Dictionary) -> bool:
	if resources.is_empty():
		return false
	for key in resources:
		if not _valid_id(key):
			return false
		var amount: Variant = resources[key]
		if typeof(amount) != TYPE_INT or amount < 0:
			return false
	return true


func record_harvest(bed_id: String, cycle: int, resources: Dictionary) -> bool:
	if not _valid_id(bed_id) or cycle < 0 or not _valid_resources(resources):
		return false
	var beds: Dictionary = _cycles.get(cycle, {})
	if beds.has(bed_id):
		return false
	beds[bed_id] = resources.duplicate(true)
	_cycles[cycle] = beds
	return true


## Estado serializável como Variant do Godot, preservando as chaves inteiras.
func get_save_data() -> Dictionary:
	return {"cycles": _cycles.duplicate(true)}


## Substitui o registro somente após validar o estado inteiro.
func load_save_data(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.size() != 1 or typeof(data.get("cycles")) != TYPE_DICTIONARY:
		return false
	var cycles: Dictionary = data["cycles"]
	for cycle in cycles:
		if typeof(cycle) != TYPE_INT or cycle < 0:
			return false
		if typeof(cycles[cycle]) != TYPE_DICTIONARY:
			return false
		var beds: Dictionary = cycles[cycle]
		if beds.is_empty():
			return false
		for bed_id in beds:
			if not _valid_id(bed_id) or typeof(beds[bed_id]) != TYPE_DICTIONARY:
				return false
			if not _valid_resources(beds[bed_id]):
				return false
	_cycles = cycles.duplicate(true)
	return true

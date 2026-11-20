extends RefCounted
## Uma instância por sessão. A ausência de um ID significa que ele não foi marcado.

var _marked: Dictionary = {}


static func _valid_id(id: String) -> bool:
	return not id.is_empty() and id == id.strip_edges()


## Retorna true somente quando acrescenta uma marca.
func mark(id: String) -> bool:
	if not _valid_id(id) or _marked.has(id):
		return false
	_marked[id] = true
	return true


func is_marked(id: String) -> bool:
	return _marked.has(id)


func count() -> int:
	return _marked.size()


func clear() -> void:
	_marked.clear()


## Formato: {String: true}, com chaves em ordem lexicográfica.
func export_state() -> Dictionary:
	var snapshot := _marked.duplicate()
	snapshot.sort()
	return snapshot


## Substitui as marcas; uma entrada inválida preserva a sessão inteira.
func import_state(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var source: Dictionary = data
	var replacement: Dictionary = {}
	for key in source:
		if typeof(key) != TYPE_STRING or not _valid_id(key):
			return false
		var value: Variant = source[key]
		if typeof(value) != TYPE_BOOL or not value:
			return false
		replacement[key] = true
	_marked = replacement
	return true

extends RefCounted
## Registro de preparações por receita, mantido apenas nesta instância.

const MAX_COUNT: int = 9223372036854775807

var _counts: Dictionary[String, int] = {}


## Aceita IDs textuais no formato [a-z][a-z0-9_]*, sem normalização.
func _is_valid_id(recipe_id: Variant) -> bool:
	if typeof(recipe_id) != TYPE_STRING and typeof(recipe_id) != TYPE_STRING_NAME:
		return false
	var id := String(recipe_id)
	if id.is_empty():
		return false
	for i in range(id.length()):
		var code := id.unicode_at(i)
		if code >= 97 and code <= 122:
			continue
		if i > 0 and ((code >= 48 and code <= 57) or code == 95):
			continue
		return false
	return true


## Soma uma quantidade inteira positiva. Falhas preservam o registro.
func record_preparation(recipe_id: Variant, quantity: Variant = 1) -> bool:
	if not _is_valid_id(recipe_id) or typeof(quantity) != TYPE_INT:
		return false
	var id := String(recipe_id)
	var amount: int = quantity
	var current: int = _counts.get(id, 0)
	if amount <= 0 or amount > MAX_COUNT - current:
		return false
	_counts[id] = current + amount
	return true


## IDs ausentes ou inválidos retornam zero sem criar entradas.
func count_for(recipe_id: Variant) -> int:
	if not _is_valid_id(recipe_id):
		return 0
	return _counts.get(String(recipe_id), 0)


func snapshot() -> Dictionary[String, int]:
	# Chaves textuais e valores inteiros não exigem cópia profunda.
	return _counts.duplicate()

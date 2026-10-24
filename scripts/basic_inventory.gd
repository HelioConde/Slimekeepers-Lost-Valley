extends Node
## Inventario de prototipo: mantido durante a partida, sem gravacao em disco.
signal inventory_changed

const STACK_LIMIT: int = 99
var counts: Dictionary = {
	"madeira": 0, "pedra": 0, "fibra": 0,
	"sementes": 8, "colheita": 0, "cogumelos": 0
}

func quantity(item_id: String) -> int:
	return int(counts.get(item_id, 0))

func add_item(item_id: String, amount: int = 1) -> int:
	if amount <= 0 or not counts.has(item_id):
		return 0
	var before: int = quantity(item_id)
	var after: int = mini(STACK_LIMIT, before + amount)
	counts[item_id] = after
	if after != before:
		inventory_changed.emit()
	return after - before

func take_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or not counts.has(item_id) or quantity(item_id) < amount:
		return false
	counts[item_id] = quantity(item_id) - amount
	inventory_changed.emit()
	return true

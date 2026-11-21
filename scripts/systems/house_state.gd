extends RefCounted
## Casa construída pelo jogador: piso, paredes e mobília por célula (32 px).
## Fica na sessão (e no save em disco). A primeira vez cria uma casa inicial
## pequena com cama; depois o jogador amplia, muda e mobilia como quiser.

const KEY := "player_house"
const LAYERS := ["floor", "wall"]
## id -> nome, sprite, sólido, tamanho em células (largura, altura).
const FURNITURE := {
	"cama": {"name": "Cama", "art": "cama", "solid": true, "size": Vector2i(1, 2)},
	"mesa": {"name": "Mesa", "art": "mesa", "solid": true, "size": Vector2i(1, 1)},
	"cadeira": {"name": "Cadeira", "art": "cadeira", "solid": false, "size": Vector2i(1, 1)},
	"bau": {"name": "Baú", "art": "bau", "solid": true, "size": Vector2i(1, 1)},
	"tapete": {"name": "Tapete", "art": "tapete", "solid": false, "size": Vector2i(2, 1)},
	"planta": {"name": "Planta", "art": "planta", "solid": true, "size": Vector2i(1, 1)},
	"estante": {"name": "Estante", "art": "estante", "solid": true, "size": Vector2i(1, 1)},
	"fogao": {"name": "Fogão", "art": "fogao", "solid": true, "size": Vector2i(1, 1)},
}
const FURNITURE_ORDER := ["cama", "mesa", "cadeira", "bau", "tapete", "planta", "estante", "fogao"]

## Casa inicial: piso 7×5 (células 13..19 × 6..10), paredes em volta, porta embaixo.
const STARTER_FLOOR := Rect2i(13, 6, 7, 5)
const STARTER_DOOR := Vector2i(16, 11)
const STARTER_FURNITURE := {Vector2i(14, 7): "cama", Vector2i(17, 8): "mesa", Vector2i(18, 8): "cadeira",
	Vector2i(19, 7): "bau", Vector2i(16, 9): "tapete", Vector2i(13, 10): "planta"}


static func data(tree: SceneTree) -> Dictionary:
	if not tree.has_meta(KEY):
		tree.set_meta(KEY, starter_house())
	return tree.get_meta(KEY)


static func starter_house() -> Dictionary:
	var floor_cells := {}
	var walls := {}
	for y in range(STARTER_FLOOR.position.y - 1, STARTER_FLOOR.end.y + 1):
		for x in range(STARTER_FLOOR.position.x - 1, STARTER_FLOOR.end.x + 1):
			var cell := Vector2i(x, y)
			floor_cells[cell] = true
			if not STARTER_FLOOR.has_point(cell) and cell != STARTER_DOOR:
				walls[cell] = true
	return {"floor": floor_cells, "wall": walls, "furniture": STARTER_FURNITURE.duplicate()}


static func has(tree: SceneTree, layer: String, cell: Vector2i) -> bool:
	return data(tree)[layer].has(cell)


static func furniture_at(tree: SceneTree, cell: Vector2i) -> String:
	for origin in data(tree).furniture:
		if footprint(origin, str(data(tree).furniture[origin])).has_point(cell):
			return str(data(tree).furniture[origin])
	return ""


static func furniture_origin(tree: SceneTree, cell: Vector2i) -> Vector2i:
	for origin in data(tree).furniture:
		if footprint(origin, str(data(tree).furniture[origin])).has_point(cell):
			return origin
	return Vector2i(-99999, -99999)


static func footprint(origin: Vector2i, id: String) -> Rect2i:
	return Rect2i(origin, FURNITURE.get(id, {"size": Vector2i.ONE}).size)


## Coloca uma peça; regras: parede sobre piso livre de móveis; móvel só dentro de
## piso, sem parede e sem outro móvel; nada na célula do jogador.
static func place(tree: SceneTree, layer: String, cell: Vector2i, furniture_id: String = "", blocked: Array = []) -> bool:
	var house := data(tree)
	match layer:
		"floor":
			if house.floor.has(cell): return false
			house.floor[cell] = true
		"wall":
			if house.wall.has(cell) or cell in blocked or furniture_at(tree, cell) != "": return false
			house.wall[cell] = true
			house.floor[cell] = true
		"furniture":
			if not FURNITURE.has(furniture_id): return false
			var rect := footprint(cell, furniture_id)
			for y in range(rect.position.y, rect.end.y):
				for x in range(rect.position.x, rect.end.x):
					var c := Vector2i(x, y)
					if not house.floor.has(c) or house.wall.has(c) or furniture_at(tree, c) != "": return false
					if FURNITURE[furniture_id].solid and c in blocked: return false
			house.furniture[cell] = furniture_id
		_:
			return false
	tree.set_meta(KEY, house)
	return true


static func erase(tree: SceneTree, layer: String, cell: Vector2i) -> bool:
	var house := data(tree)
	match layer:
		"floor":
			if not house.floor.has(cell) or house.wall.has(cell) or furniture_at(tree, cell) != "": return false
			house.floor.erase(cell)
		"wall":
			if not house.wall.erase(cell): return false
		"furniture":
			var origin := furniture_origin(tree, cell)
			if not house.furniture.erase(origin): return false
		_:
			return false
	tree.set_meta(KEY, house)
	return true


## Células sólidas: paredes e a face de parede (célula logo abaixo de uma parede).
static func solid_cells(tree: SceneTree) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var house := data(tree)
	for cell in house.wall:
		cells.append(cell)
		var below: Vector2i = cell + Vector2i(0, 1)
		if not house.wall.has(below) and not cells.has(below):
			cells.append(below)
	return cells


static func is_inside(tree: SceneTree, cell: Vector2i) -> bool:
	var house := data(tree)
	return house.floor.has(cell) and not house.wall.has(cell)

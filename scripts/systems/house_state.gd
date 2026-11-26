extends RefCounted
## Casa do jogador (CASA.md): UMA só no jogo inteiro, em qualquer lugar livre do mapa
## (Floresta ou Vale). Não há casa inicial (pedido do usuário, 2026-11-22): no modo
## construir o jogador arrasta um retângulo do tamanho que quiser e paga piso e
## paredes com os recursos da bolsa — casa maior custa mais. Dentro dela coloca a
## mobília (também paga). Demolir devolve todo o material e libera construir de novo.
## Fica na sessão (e no save em disco).

const KEY := "player_house"
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
## Tamanho externo (paredes inclusas): mínimo 5×5 = 3×3 por dentro; a cama 1×2 ocupa uma coluna e sobram 2 para andar até a porta (4×4 deixava 1).
const MIN_SIZE := Vector2i(5, 5)
const MAX_SIZE := Vector2i(16, 12)
## Custo por célula de piso e de parede, e por móvel (itens da bolsa).
const FLOOR_COST := {"madeira": 1}
const WALL_COST := {"madeira": 2, "pedra_pequena": 1}
const FURNITURE_COSTS := {
	"cama": {"madeira": 4, "fibra": 6},
	"mesa": {"madeira": 3},
	"cadeira": {"madeira": 2},
	"bau": {"madeira": 4, "corda": 1},
	"tapete": {"fibra": 8},
	"planta": {"fibra": 2},
	"estante": {"madeira": 4},
	"fogao": {"pedra_pequena": 6, "madeira": 2},
}
const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const CHEST := preload("res://scripts/systems/chest_storage.gd")


static func empty() -> Dictionary:
	return {"region": "", "rect": Rect2i(), "floor": {}, "wall": {}, "furniture": {}}


static func data(tree: SceneTree) -> Dictionary:
	if not tree.has_meta(KEY):
		tree.set_meta(KEY, empty())
	var house: Dictionary = tree.get_meta(KEY)
	if not house.has("region"):  # save antigo (casa inicial da Fazenda)
		house["region"] = "fazenda" if not house.floor.is_empty() else ""
		house["rect"] = Rect2i()
	return house


static func exists(tree: SceneTree) -> bool:
	return not data(tree).floor.is_empty()


static func region_of(tree: SceneTree) -> String:
	return str(data(tree).region) if exists(tree) else ""


## A casa como a região a vê: a casa real se for dela, senão vazia.
static func view(tree: SceneTree, region: String) -> Dictionary:
	return data(tree) if region_of(tree) == region else empty()


## Porta: meio da parede de baixo.
static func door_of(rect: Rect2i) -> Vector2i:
	return Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 1)


## Paredes e pisos de um retângulo externo (porta é piso).
static func rect_counts(rect: Rect2i) -> Dictionary:
	var walls := 2 * rect.size.x + 2 * rect.size.y - 4 - 1
	var floors := rect.size.x * rect.size.y - walls
	return {"walls": walls, "floors": floors}


static func rect_cost(rect: Rect2i) -> Dictionary:
	var n := rect_counts(rect)
	var cost := {}
	for item in FLOOR_COST: cost[item] = int(cost.get(item, 0)) + int(FLOOR_COST[item]) * int(n.floors)
	for item in WALL_COST: cost[item] = int(cost.get(item, 0)) + int(WALL_COST[item]) * int(n.walls)
	return cost


## Retângulo normalizado entre duas células arrastadas.
static func drag_rect(a: Vector2i, b: Vector2i) -> Rect2i:
	var top := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	return Rect2i(top, (Vector2i(maxi(a.x, b.x), maxi(a.y, b.y)) - top) + Vector2i.ONE)


## Por que não dá para construir aqui ("" = pode). blocked(cell): ocupado pelo mapa.
static func build_problem(tree: SceneTree, rect: Rect2i, blocked: Callable = Callable(), player_cell: Variant = null) -> String:
	if exists(tree):
		return "Você já tem uma casa (%s). Demolir: clique direito nela" % region_name(region_of(tree))
	if rect.size.x < MIN_SIZE.x or rect.size.y < MIN_SIZE.y:
		return "Pequena demais (mínimo %d×%d)" % [MIN_SIZE.x, MIN_SIZE.y]
	if rect.size.x > MAX_SIZE.x or rect.size.y > MAX_SIZE.y:
		return "Grande demais (máximo %d×%d)" % [MAX_SIZE.x, MAX_SIZE.y]
	if player_cell != null and rect.has_point(player_cell):
		return "Saia de dentro da área para construir"
	if blocked.is_valid():
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if blocked.call(Vector2i(x, y)): return "Lugar ocupado (árvore, pedra ou água)"
	return missing(tree, rect_cost(rect))


## Constrói a casa no retângulo: piso em tudo, paredes em volta, porta embaixo.
## "" = construiu; senão o motivo.
static func build(tree: SceneTree, region: String, rect: Rect2i, blocked: Callable = Callable(), player_cell: Variant = null) -> String:
	var problem := build_problem(tree, rect, blocked, player_cell)
	if not problem.is_empty(): return problem
	var house := empty()
	house.region = region
	house.rect = rect
	var door := door_of(rect)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			house.floor[cell] = true
			var edge := x == rect.position.x or x == rect.end.x - 1 or y == rect.position.y or y == rect.end.y - 1
			if edge and cell != door:
				house.wall[cell] = true
	_pay(tree, rect_cost(rect))
	tree.set_meta(KEY, house)
	return ""


## Desfaz a casa inteira e devolve piso, paredes e móveis.
static func demolish(tree: SceneTree) -> bool:
	if not exists(tree) or not CHEST.is_empty(tree): return false  # baú cheio: esvaziar antes
	var house := data(tree)
	var rect: Rect2i = house.rect
	if rect.has_area():
		_refund(tree, rect_cost(rect))
	for origin in house.furniture:
		_refund(tree, FURNITURE_COSTS.get(str(house.furniture[origin]), {}))
	tree.set_meta(KEY, empty())
	return true


static func has(tree: SceneTree, layer: String, cell: Vector2i) -> bool:
	return data(tree)[layer].has(cell)


static func furniture_at(tree: SceneTree, cell: Vector2i) -> String:
	var furniture: Dictionary = data(tree).furniture
	for origin in furniture:
		if footprint(origin, str(furniture[origin])).has_point(cell):
			return str(furniture[origin])
	return ""


static func furniture_origin(tree: SceneTree, cell: Vector2i) -> Vector2i:
	var furniture: Dictionary = data(tree).furniture
	for origin in furniture:
		if footprint(origin, str(furniture[origin])).has_point(cell):
			return origin
	return Vector2i(-99999, -99999)


static func footprint(origin: Vector2i, id: String) -> Rect2i:
	return Rect2i(origin, FURNITURE.get(id, {"size": Vector2i.ONE}).size)


## Coloca um móvel dentro da casa (piso, sem parede nem outro móvel; sólido não na
## célula do jogador). Paga FURNITURE_COSTS. "" = colocou; senão o motivo.
static func place_furniture(tree: SceneTree, cell: Vector2i, furniture_id: String, blocked: Array = []) -> String:
	if not FURNITURE.has(furniture_id): return "Móvel desconhecido"
	var house := data(tree)
	var rect := footprint(cell, furniture_id)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := Vector2i(x, y)
			if not house.floor.has(c) or house.wall.has(c) or furniture_at(tree, c) != "": return "Só dentro da casa, em lugar livre"
			if FURNITURE[furniture_id].solid and c in blocked: return "Saia do lugar do móvel"
	var cost: Dictionary = FURNITURE_COSTS.get(furniture_id, {})
	var lack := missing(tree, cost)
	if not lack.is_empty(): return lack
	_pay(tree, cost)
	house.furniture[cell] = furniture_id
	tree.set_meta(KEY, house)
	return ""


## Tira o móvel da célula e devolve o material.
static func remove_furniture(tree: SceneTree, cell: Vector2i) -> bool:
	var house := data(tree)
	var origin := furniture_origin(tree, cell)
	var id := str(house.furniture.get(origin, ""))
	if id == "bau" and not CHEST.is_empty(tree): return false  # esvaziar o baú antes
	if not house.furniture.erase(origin): return false
	_refund(tree, FURNITURE_COSTS.get(id, {}))
	tree.set_meta(KEY, house)
	return true


## Células sólidas da casa dada: paredes e a face de parede (célula logo abaixo).
static func solid_cells_of(house: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in house.wall:
		cells.append(cell)
		var below: Vector2i = cell + Vector2i(0, 1)
		if not house.wall.has(below) and not cells.has(below):
			cells.append(below)
	return cells


static func solid_cells(tree: SceneTree) -> Array[Vector2i]:
	return solid_cells_of(data(tree))


static func is_inside_of(house: Dictionary, cell: Vector2i) -> bool:
	return house.floor.has(cell) and not house.wall.has(cell)


static func is_inside(tree: SceneTree, cell: Vector2i) -> bool:
	return is_inside_of(data(tree), cell)


## Primeiro item que falta na bolsa ("Falta 2 madeira") ou "".
static func missing(tree: SceneTree, cost: Dictionary) -> String:
	for item in cost:
		var have := BAG.count_item(tree, item)
		if have < int(cost[item]):
			return "Falta %d %s" % [int(cost[item]) - have, str(ITEMS.info(item).name).to_lower()]
	return ""


## Texto curto do custo: "20 madeira + 6 pedra pequena".
static func cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for item in cost: parts.append("%d %s" % [int(cost[item]), str(ITEMS.info(item).name).to_lower()])
	return " + ".join(parts) if not parts.is_empty() else "grátis"


static func region_name(region: String) -> String:
	return {"floresta": "na Floresta", "vale": "no Vale", "fazenda": "na Fazenda"}.get(region, region)


static func _pay(tree: SceneTree, cost: Dictionary) -> void:
	for item in cost: BAG.spend_item(tree, item, int(cost[item]))


static func _refund(tree: SceneTree, cost: Dictionary) -> void:
	for item in cost: BAG.add_item(tree, item, int(cost[item]))

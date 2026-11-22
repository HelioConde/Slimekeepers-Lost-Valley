extends Node2D
## Coleta manual (CRIACAO.md, etapa 1): pontos de fibra (mato), graveto e pedra
## pequena espalhados em volta da Clareira do Despertar. Posições fixas pela malha
## do mundo + hash (iguais em toda partida), só em chão livre. Coletado some e
## volta no dia seguinte; o estado fica em FORAGE_KEY (sessão, salvo em disco).

const BAG := preload("res://scripts/systems/forest_bag.gd")
const FORAGE_KEY := "forage_taken"
const REACH := 36.0
## Todo mato do chão (GroundDetail) dá fibra; arrancar exige segurar [E] (pedido do
## usuário, 2026-11-22: "não pode ser fácil pegar").
const MATO_KINDS := ["grass", "grass_tuft_sunlit"]
const PULL_SECONDS := {"fibra": 4.0}
## item, quantidade por coleta, arte no chão, deslocamento do sprite
const KINDS := {
	"fibra": [1, preload("res://assets/world/ground/grass_tuft_sunlit.png"), Vector2(0, -10)],
	"graveto": [1, preload("res://assets/ui/items/graveto.png"), Vector2(0, -6)],
	"pedra_pequena": [1, preload("res://assets/world/ground/pebbles.png"), Vector2(0, -6)],
}

var spots: Array[Dictionary] = []  # {id, item, at, sprite}


## center: miolo da Clareira; plan: {item: quantidade de pontos}; free: chão livre?
func setup(center: Vector2, inner: float, outer: float, plan: Dictionary, free: Callable) -> void:
	name = "ForageSpots"
	y_sort_enabled = true
	var placed := 0
	var candidates: Array = []
	var cell := 44.0
	for gy in range(int(-outer / cell), int(outer / cell) + 1):
		for gx in range(int(-outer / cell), int(outer / cell) + 1):
			var key := Vector2i(gx, gy)
			var jitter := Vector2(_rand(key, 1), _rand(key, 2)) * cell * 0.6
			var at := (center + Vector2(key) * cell + jitter).round()
			var d := at.distance_to(center)
			if d < inner or d > outer or not free.call(at): continue
			candidates.append([_rand(key, 3), at, key])
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	var order: Array = []
	for item: String in plan:
		for i in int(plan[item]): order.append(item)
	for item: String in order:
		if placed >= candidates.size(): break
		var c: Array = candidates[placed]
		placed += 1
		_add_spot("%s_%d_%d" % [item, c[2].x, c[2].y], item, c[1])


func _add_spot(id: String, item: String, at: Vector2) -> void:
	var data: Array = KINDS[item]
	var sprite := Sprite2D.new()
	sprite.name = "Forage_" + id
	sprite.texture = data[1]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = data[2]
	sprite.position = to_local(at)
	add_child(sprite)
	spots.append({"id": id, "item": item, "at": at, "sprite": sprite})


## Cada tufo de mato do detalhe de chão vira um ponto de fibra (o próprio sprite some).
func add_mato(detail: Node2D) -> void:
	for entry: Dictionary in detail.placed:
		if entry.kind not in MATO_KINDS: continue
		var at: Vector2 = detail.to_global(entry.at)
		spots.append({"id": "mato_%d_%d" % [roundi(at.x), roundi(at.y)], "item": "fibra", "at": at, "sprite": entry.sprite})


## Mato pintado em tiles (VegetationLow da floresta): cada célula com a textura de
## mato vira um ponto de fibra; colhido, o tile é apagado e volta no dia seguinte.
func add_mato_tiles(layer: TileMapLayer, texture: Texture2D) -> void:
	for source_index in layer.tile_set.get_source_count():
		var source_id := layer.tile_set.get_source_id(source_index)
		var source := layer.tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null or source.texture != texture: continue
		for cell in layer.get_used_cells_by_id(source_id):
			var at := layer.to_global(layer.map_to_local(cell))
			spots.append({"id": "matot_%d_%d" % [cell.x, cell.y], "item": "fibra", "at": at,
				"layer": layer, "cell": cell, "source": source_id, "atlas": layer.get_cell_atlas_coords(cell)})


## Mostra ou esconde o ponto (sprite próprio ou tile da camada).
static func _show(spot: Dictionary, shown: bool) -> void:
	if spot.has("sprite"):
		(spot.sprite as CanvasItem).visible = shown
	elif shown:
		(spot.layer as TileMapLayer).set_cell(spot.cell, spot.source, spot.atlas)
	else:
		(spot.layer as TileMapLayer).erase_cell(spot.cell)


## Segundos segurando [E] para coletar o item (0 = na hora).
static func pull_seconds(item: String) -> float:
	return float(PULL_SECONDS.get(item, 0.0))


static func _rand(key: Vector2i, salt: int) -> float:
	return float(posmod(hash(Vector3i(key.x, key.y, salt + 4177)), 10000)) / 10000.0


static func is_taken(tree: SceneTree, id: String, day: int) -> bool:
	var taken: Dictionary = tree.get_meta(FORAGE_KEY, {})
	return taken.has(id) and int(taken[id]) >= day  # volta no dia seguinte


## Mostra/esconde conforme o dia (chamado ao entrar e a cada troca de dia).
func refresh(day: int) -> void:
	var taken: Dictionary = get_tree().get_meta(FORAGE_KEY, {})
	for spot in spots:
		var shown := not (taken.has(spot.id) and int(taken[spot.id]) >= day)
		if spot.has("layer") and shown == ((spot.layer as TileMapLayer).get_cell_source_id(spot.cell) != -1):
			continue  # tile já no estado certo: milhares de células, não regravar
		_show(spot, shown)


## Ponto disponível mais próximo ao alcance, ou {}.
func nearest(at: Vector2, day: int) -> Dictionary:
	var best: Dictionary = {}
	var best_d := REACH
	for spot in spots:
		var d := (spot.at as Vector2).distance_to(at)
		if d < best_d and not is_taken(get_tree(), spot.id, day):
			best = spot
			best_d = d
	return best


## Coleta: entra na bolsa e some até amanhã. "" se ok; senão o motivo.
func take(spot: Dictionary, day: int) -> String:
	var amount: int = KINDS[spot.item][0]
	if not BAG.add_item(get_tree(), spot.item, amount):
		return "A bolsa não tem espaço para mais."
	var taken: Dictionary = get_tree().get_meta(FORAGE_KEY, {}).duplicate()
	taken[spot.id] = day
	get_tree().set_meta(FORAGE_KEY, taken)
	_show(spot, false)
	return ""

extends Node2D
## Coleta manual (CRIACAO.md, etapa 1): pontos de fibra (mato), graveto e pedra
## pequena espalhados em volta da Clareira do Despertar. Posições fixas pela malha
## do mundo + hash (iguais em toda partida), só em chão livre. Coletado some e
## volta no dia seguinte; o estado fica em FORAGE_KEY (sessão, salvo em disco).

const BAG := preload("res://scripts/systems/forest_bag.gd")
const FORAGE_KEY := "forage_taken"
const REACH := 36.0
## item, quantidade por coleta, arte no chão, deslocamento do sprite
const KINDS := {
	"fibra": [2, preload("res://assets/world/ground/grass_tuft_sunlit.png"), Vector2(0, -10)],
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


static func _rand(key: Vector2i, salt: int) -> float:
	return float(posmod(hash(Vector3i(key.x, key.y, salt + 4177)), 10000)) / 10000.0


static func is_taken(tree: SceneTree, id: String, day: int) -> bool:
	var taken: Dictionary = tree.get_meta(FORAGE_KEY, {})
	return taken.has(id) and int(taken[id]) >= day  # volta no dia seguinte


## Mostra/esconde conforme o dia (chamado ao entrar e a cada troca de dia).
func refresh(day: int) -> void:
	for spot in spots:
		(spot.sprite as Sprite2D).visible = not is_taken(get_tree(), spot.id, day)


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
	(spot.sprite as Sprite2D).visible = false
	return ""

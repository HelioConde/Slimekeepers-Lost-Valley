extends Node2D
## Pedras médias e grandes espalhadas pelo mapa (pedido do usuário, 2026-11-23).
## - Pedra média: só com picareta; 3 golpes e solta 5 pedras pequenas no chão.
## - Pedra grande: precisa de uma picareta melhor (ainda não existe no jogo).
## Pedra quebrada volta depois de REGROW_DAYS dias. Estado na sessão (KEY).

const KEY := "rocks_broken"
const HITS := {"medium": 3, "large": 6}
const DROPS := {"medium": 5, "large": 12}  # playtest ID 07: rendimento maior
const REGROW_DAYS := 5
const REACH := 44.0
const ART := {"medium": "res://assets/world/rocks/rock_medium.png", "large": "res://assets/world/rocks/rock_large.png"}
## Raio (px) da colisão na base de cada tamanho.
const RADIUS := {"medium": 12.0, "large": 22.0}

var rocks: Dictionary = {}  # id -> {kind, at, node}
var drop: Callable  # item_drops.spawn(item, amount, at)
var _hits: Dictionary = {}


func _init() -> void:
	name = "BreakableRocks"
	y_sort_enabled = true


## Espalha `plan` ({"medium": n, "large": n}) numa grade com sorteio estável dentro de
## `area`; `free(at)` diz se o ponto está livre (sem água, árvore ou parede).
func scatter(area: Rect2, cell: float, plan: Dictionary, free: Callable, prefix: String = "") -> void:
	var candidates: Array = []
	for gy in range(int(area.position.y / cell), int(area.end.y / cell)):
		for gx in range(int(area.position.x / cell), int(area.end.x / cell)):
			var key := Vector2i(gx, gy)
			var at := (Vector2(key) * cell + Vector2(_rand(key, 1), _rand(key, 2)) * cell).round()
			candidates.append([_rand(key, 3), at, key])
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	var order: Array = []
	for kind: String in plan:
		for i in int(plan[kind]): order.append(kind)
	var used := 0
	for kind: String in order:
		while used < candidates.size():
			var c: Array = candidates[used]
			used += 1
			if free.call(c[1]):
				_add("%srock_%s_%d_%d" % [prefix, kind, c[2].x, c[2].y], kind, c[1])
				break


func _add(id: String, kind: String, at: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "Rock_" + id
	body.position = to_local(at)
	body.collision_layer = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS[kind]
	shape.shape = circle
	body.add_child(shape)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load(ART[kind])
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var used: Rect2i = sprite.texture.get_image().get_used_rect()
	# Base da pedra (última linha visível) no ponto do chão.
	sprite.offset = Vector2(0, -(used.end.y - sprite.texture.get_height() * 0.5) + 2)
	body.add_child(sprite)
	add_child(body)
	rocks[id] = {"id": id, "kind": kind, "at": at, "node": body}


static func _rand(key: Vector2i, salt: int) -> float:
	var h := hash([key.x, key.y, salt, 7349])
	return float(h % 10000) / 10000.0


## Esconde as quebradas e devolve as que já cresceram de novo.
func refresh(day: int) -> void:
	var broken: Dictionary = get_tree().get_meta(KEY, {})
	for id in rocks:
		var gone := broken.has(id) and day - int(broken[id]) < REGROW_DAYS
		var node: StaticBody2D = rocks[id].node
		node.visible = not gone
		node.collision_layer = 0 if gone else 2


func target(at: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d := REACH
	for id in rocks:
		var r: Dictionary = rocks[id]
		if not (r.node as Node2D).visible: continue
		var d := at.distance_to(r.at)
		if d < best_d:
			best_d = d
			best = r
	return best


func hits(id: String) -> int:
	return int(_hits.get(id, 0))


## Um golpe de picareta (power: quantos golpes vale; pedra polida = 2). Devolve "hit" ou "broken".
func strike(rock: Dictionary, day: int, power: int = 1) -> String:
	var id: String = rock.id
	_hits[id] = hits(id) + power
	if hits(id) < int(HITS[rock.kind]): return "hit"
	_hits.erase(id)
	var broken: Dictionary = get_tree().get_meta(KEY, {}).duplicate()
	broken[id] = day
	get_tree().set_meta(KEY, broken)
	refresh(day)
	if drop.is_valid(): drop.call("pedra_pequena", int(DROPS[rock.kind]), rock.at)
	return "broken"

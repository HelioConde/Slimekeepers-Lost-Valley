extends Node2D
## Itens que caem no chão (pedido do usuário, 2026-11-22): ao coletar, cortar ou
## colher, o produto salta do ponto, dá 3 quicadas cada vez menores e fica no chão;
## com o jogador dentro do alcance (MAGNET_RANGE) ele é puxado até o jogador e entra
## na bolsa. Bolsa cheia: o item espera no chão. Ao sair da região, o que sobrou vai
## para a bolsa (se couber).
##
## Multijogador (playtest IDs 20 e 21): com o outro jogador no mesmo mapa, cada drop
## tem um id estável e aparece nas duas telas (mesmo ponto e mesmas quicadas). O
## anfitrião decide quem pega: ele recolhe direto; o convidado pede ("drop_req") e só
## põe na bolsa quando o anfitrião entrega ("drop_give"). Quem chega primeiro ao
## anfitrião leva; o outro vê o item sumir ("drop_set" com n = 0). Mensagens:
##   drop      {id, item, n, x, y, dx, dy, sc, r}  criou (r = já no chão, sem quicar)
##   drop_req  {id, item, n}                       convidado quer pegar
##   drop_give {id, item, n}                       anfitrião entrega ao convidado
##   drop_set  {id, n}                             anfitrião: sobrou n (0 = sumiu)

const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
## Alcance do ímã (px): a partir daqui o item voa para o jogador.
const MAGNET_RANGE := 72.0
const PICKUP_RANGE := 10.0
const FLY_SPEED := 260.0
## Alturas das 3 quicadas (px) e duração de cada uma (s).
const BOUNCES := [[28.0, 0.34], [14.0, 0.24], [6.0, 0.16]]
## Tempo parado no chão depois das quicadas, antes do ímã (s): dá para ver o item cair.
const REST_ON_GROUND := 0.35

signal picked(item: String, amount: int)

var player: Node2D
var drops: Array[Dictionary] = []  # {id, item, amount, node, ready, speed, shared, pending, keep_away}

## Ids recolhidos pelo anfitrião (sobrevive à troca de região): pedido atrasado do
## convidado por um item que já sumiu é negado, sem duplicar.
static var _gone: Dictionary = {}
static var _salt := ""
static var _next := 0
var _session: Node
var _peer_scene := ""  # mapa do outro jogador (das mensagens "state" do net_presence)


func _init() -> void:
	name = "ItemDrops"
	y_sort_enabled = true
	add_to_group("item_drops")  # barra rápida e mochila soltam itens aqui


func _ready() -> void:
	_session = get_node_or_null("/root/NetSession")
	if _session == null: return
	_session.message.connect(_on_message)
	_session.peer_left.connect(_on_peer_left)


## Solta `amount` de `item` no chão a partir de `at` (pula para um lado).
func spawn(item: String, amount: int, at: Vector2) -> void:
	if amount <= 0: return
	var away := Vector2(randf_range(-1.0, 1.0), randf_range(0.2, 1.0))
	if is_instance_valid(player) and player.global_position.distance_to(at) > 4.0:
		away = (at - player.global_position).normalized() + away * 0.4  # salta para longe do jogador
	var side := away.normalized() * randf_range(22.0, 32.0)
	_share(_add(_new_id(), item, amount, at, side), at, side)


## Mochila/barra (playtest ID 21): tira `amount` de `item` da bolsa e solta à frente
## do jogador. Quem soltou só puxa de volta depois de se afastar; o outro pega na hora.
func drop_from_bag(item: String, amount: int) -> bool:
	if item.is_empty() or amount <= 0 or not is_instance_valid(player): return false
	if not BAG.spend_item(get_tree(), item, amount): return false  # não tem o bastante
	var facing := str(player.get("facing"))
	var dir := Vector2(1.0 if "east" in facing else -1.0 if "west" in facing else 0.0,
		-1.0 if "north" in facing else 1.0 if "south" in facing else 0.0).normalized()
	if dir == Vector2.ZERO: dir = Vector2.DOWN
	var at := player.global_position + dir * 6.0
	var side := dir * randf_range(26.0, 34.0)
	var entry := _add(_new_id(), item, amount, at, side)
	entry.keep_away = true
	_share(entry, at, side)
	preload("res://scripts/systems/sfx.gd").play(get_tree(), "pegar")
	return true


func _new_id() -> String:
	if _salt.is_empty(): _salt = "%x" % randi()  # dois jogos não repetem ids
	_next += 1
	return "%s_%d" % [_salt, _next]


## Cria o item no chão. `landed`: já parado (quem chega ao mapa recebe os que existem).
func _add(id: String, item: String, amount: int, at: Vector2, side: Vector2, landed := false) -> Dictionary:
	var holder := Node2D.new()
	holder.name = "Drop_%s" % item
	holder.position = to_local(at)
	add_child(holder)
	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.22)
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0
		pts.append(Vector2(cos(a) * 6.0, sin(a) * 2.5))
	shadow.polygon = pts
	holder.add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.name = "Icon"
	sprite.texture = ITEMS.icon(item)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 0.8
	sprite.offset = Vector2(0, -10)
	holder.add_child(sprite)
	var entry := {"id": id, "item": item, "amount": amount, "node": holder, "ready": landed, "speed": 0.0,
		"shared": false, "pending": false, "keep_away": false}
	drops.append(entry)
	if landed: return entry
	# 3 quicadas: anda para um lado e sobe/desce cada vez menos.
	var tween := holder.create_tween()
	var from := holder.position
	var step := side / BOUNCES.size()
	for b in BOUNCES:
		var height: float = b[0]
		var time: float = b[1]
		tween.tween_property(sprite, "position:y", -height, time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(holder, "position", from + step, time).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(sprite, "position:y", 0.0, time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		from += step
	tween.tween_interval(REST_ON_GROUND)
	tween.tween_callback(func() -> void: entry.ready = true)
	return entry


func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	for entry in drops.duplicate():
		var node: Node2D = entry.node
		if not is_instance_valid(node): continue
		var target := player.global_position + Vector2(0, -14)
		var d := node.global_position.distance_to(target)
		if entry.keep_away:  # quem soltou: só depois de sair do alcance do ímã
			if d > MAGNET_RANGE: entry.keep_away = false
			continue
		if not entry.ready: continue
		if d > MAGNET_RANGE and float(entry.speed) <= 0.0: continue
		if not BAG.can_add(get_tree(), str(entry.item), 1):
			entry.speed = 0.0
			continue  # bolsa cheia: fica no chão
		entry.speed = minf(float(entry.speed) + FLY_SPEED * 3.0 * delta, FLY_SPEED * 2.0)
		node.global_position = node.global_position.move_toward(target, float(entry.speed) * delta)
		if node.global_position.distance_to(target) > PICKUP_RANGE: continue
		if _asks_host(entry):
			if not entry.pending:  # espera a resposta junto do jogador
				entry.pending = true
				_session.send({"t": "drop_req", "id": entry.id, "item": entry.item, "n": int(entry.amount)})
		else:
			_collect(entry)


func _collect(entry: Dictionary) -> void:
	entry.amount = int(entry.amount) - _to_bag(str(entry.item), int(entry.amount))
	_announce(entry)
	if int(entry.amount) <= 0: _remove(entry)
	else: entry.speed = 0.0


## Põe até `amount` na bolsa (o que couber); devolve quanto entrou.
func _to_bag(item: String, amount: int) -> int:
	var got := 0
	while got < amount and BAG.add_item(get_tree(), item, 1): got += 1
	if got > 0:
		picked.emit(item, got)
		preload("res://scripts/systems/sfx.gd").play(get_tree(), "pegar")
	return got


func _remove(entry: Dictionary) -> void:
	if is_instance_valid(entry.node): (entry.node as Node).queue_free()
	drops.erase(entry)


## Carreguim (farm_helpers.gd): reserva o item pronto mais perto de `at` (até `radius`)
## e o tira do chão sem pôr na bolsa. Devolve {item, amount, at} ou {}.
func claim(at: Vector2, radius: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d := radius
	for entry in drops:
		var node: Node2D = entry.node
		if not is_instance_valid(node) or not entry.ready or float(entry.speed) > 0.0 or _asks_host(entry): continue
		var d := node.global_position.distance_to(at)
		if d < best_d:
			best = entry
			best_d = d
	if best.is_empty(): return {}
	var out := {"item": str(best.item), "amount": int(best.amount), "at": (best.node as Node2D).global_position}
	best.amount = 0
	_announce(best)
	_remove(best)
	return out


## Item pronto mais perto (sem tirar do chão), para o Carreguim andar até ele.
func nearest_ready(at: Vector2, radius: float) -> Vector2:
	var best := Vector2.INF
	for entry in drops:
		var node: Node2D = entry.node
		if is_instance_valid(node) and entry.ready and float(entry.speed) <= 0.0 and not _asks_host(entry) and node.global_position.distance_to(at) < minf(radius, best.distance_to(at) if best.is_finite() else radius):
			best = node.global_position
	return best


## Itens ainda no chão (para testes e para recolher ao sair).
func pending() -> int:
	var total := 0
	for entry in drops: total += int(entry.amount)
	return total


## Põe na bolsa tudo o que estiver no chão e couber (sair da região, testes). Convidado:
## os itens compartilhados ficam no mundo do anfitrião (sem duplicar).
func collect_all() -> void:
	for entry in drops.duplicate():
		if not _asks_host(entry): _collect(entry)


func _exit_tree() -> void:
	collect_all()


# --- Multijogador ------------------------------------------------------------

func _scene() -> String:
	var current := get_tree().current_scene
	return current.scene_file_path if current else ""


func _connected() -> bool:
	return _session != null and bool(_session.connected)


func _is_host() -> bool:
	return _connected() and str(_session.mode) == "host"


## Convidado não decide sozinho sobre item compartilhado.
func _asks_host(entry: Dictionary) -> bool:
	return bool(entry.shared) and _connected() and str(_session.mode) == "guest"


## Avisa o outro jogador do item novo quando ele está no mesmo mapa.
func _share(entry: Dictionary, at: Vector2, side: Vector2, landed := false) -> void:
	if not _connected() or _peer_scene != _scene(): return
	entry.shared = true
	_session.send({"t": "drop", "id": entry.id, "item": entry.item, "n": int(entry.amount),
		"x": at.x, "y": at.y, "dx": side.x, "dy": side.y, "sc": _scene(), "r": landed})


## Anfitrião: conta ao convidado quanto sobrou do item compartilhado (0 = sumiu).
func _announce(entry: Dictionary) -> void:
	if not bool(entry.shared) or not _is_host(): return
	if int(entry.amount) <= 0: _gone[entry.id] = true
	_session.send({"t": "drop_set", "id": entry.id, "n": int(entry.amount)})


func _find(id: String) -> Dictionary:
	for entry in drops:
		if entry.id == id: return entry
	return {}


func _on_message(data: Dictionary) -> void:
	var kind := str(data.get("t", ""))
	if kind == "state":
		var was := _peer_scene
		_peer_scene = str(data.get("scene", ""))
		if was != _peer_scene and _peer_scene == _scene():  # chegou aqui: recebe o que está no chão
			for entry in drops: _share(entry, (entry.node as Node2D).global_position, Vector2.ZERO, true)
		return
	if not kind.begins_with("drop"): return
	var id := str(data.get("id", ""))
	var item := str(data.get("item", ""))
	var n := clampi(int(data.get("n", 0)), 0, ITEMS.MAX_STACK)
	if id.is_empty(): return
	match kind:
		"drop":
			if str(data.get("sc", "")) != _scene() or not ITEMS.ITEMS.has(item) or n <= 0: return
			if not _find(id).is_empty() or _gone.has(id): return
			var at := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
			var made := _add(id, item, n, at, Vector2(float(data.get("dx", 0.0)), float(data.get("dy", 0.0))), bool(data.get("r", false)))
			made.shared = true
		"drop_req":
			if not _is_host(): return
			var entry := _find(id)
			if entry.is_empty():
				if _gone.has(id) or not ITEMS.ITEMS.has(item) or n <= 0:
					_session.send({"t": "drop_set", "id": id, "n": 0})  # já foi: nega
					return
				# shortcut: item que o anfitrião nunca viu (outro mapa, corrida) vai para quem pediu.
				_gone[id] = true
				_session.send({"t": "drop_give", "id": id, "item": item, "n": n})
				return
			_gone[id] = true
			_session.send({"t": "drop_give", "id": id, "item": entry.item, "n": int(entry.amount)})
			_remove(entry)
		"drop_give":
			if not ITEMS.ITEMS.has(item): return
			var entry := _find(id)
			var at := player.global_position if is_instance_valid(player) else Vector2.ZERO
			if not entry.is_empty():
				at = (entry.node as Node2D).global_position
				_remove(entry)
			# shortcut: sem ItemDrops ativo (no meio da troca de mapa) a entrega se perde; guardar fora da região se acontecer.
			var left := n - _to_bag(item, n)
			if left > 0: spawn(item, left, at)  # não coube: volta ao chão (novo id)
		"drop_set":
			var entry := _find(id)
			if entry.is_empty(): return
			if n <= 0: _remove(entry)
			else:
				entry.amount = n
				entry.pending = false
				entry.speed = 0.0


## Caiu a conexão: o convidado larga os itens do mundo do anfitrião; o anfitrião fica com eles.
func _on_peer_left() -> void:
	_peer_scene = ""
	for entry in drops.duplicate():
		if not bool(entry.shared): continue
		if str(_session.mode) == "guest": _remove(entry)
		else: entry.shared = false

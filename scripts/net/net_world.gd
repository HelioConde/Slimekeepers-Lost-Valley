extends Node
## Mundo compartilhado no multijogador (scripts/net/net_session.gd): a fazenda, a
## coleta, as pedras quebradas e as árvores cortadas valem para os dois jogadores.
## Cada lado confere as chaves da sessão a cada CHECK_EVERY s; o que mudou aqui vai
## inteiro para o outro, que grava e redesenha a região.
## shortcut: última escrita vence por chave (dois jogadores mexendo na mesma chave no
## mesmo meio segundo perdem uma ação); trocar por diferenças por item se incomodar.
## Bancadas colocadas (placed_stations) ainda não sincronizam.

const KEYS := ["farm_cells", "forage_taken", "rocks_broken", "chopped_trees"]
const CHECK_EVERY := 0.5

var region: Node  ## região atual (farm, gathering, choppable)
var _session: Node
var _known: Dictionary = {}  # chave -> hash do último valor enviado ou recebido
var _time := 0.0


func _ready() -> void:
	name = "NetWorld"
	_session = get_node_or_null("/root/NetSession")
	if _session == null: return
	_session.message.connect(_on_message)
	_session.peer_joined.connect(func(_who: String) -> void: _known.clear())  # quem entra recebe tudo
	for key in KEYS: _known[key] = hash(get_tree().get_meta(key, {}))


func _process(delta: float) -> void:
	if _session == null or not bool(_session.connected): return
	_time += delta
	if _time < CHECK_EVERY: return
	_time = 0.0
	for key: String in KEYS:
		var value: Variant = get_tree().get_meta(key, {})
		var h := hash(value)
		if _known.get(key) == h: continue
		_known[key] = h
		_session.send({"t": "world", "key": key, "value": value})


func _on_message(data: Dictionary) -> void:
	if str(data.get("t", "")) != "world": return
	var key := str(data.get("key", ""))
	if not KEYS.has(key) or not data.get("value") is Dictionary: return  # só chaves conhecidas
	get_tree().set_meta(key, data.value)
	_known[key] = hash(data.value)
	apply(region, GameClock.day_number)


## Redesenha o que a região mostra a partir da sessão.
static func apply(where: Node, day: int) -> void:
	if not is_instance_valid(where): return
	var farm: Node = where.get("farm")
	if is_instance_valid(farm) and farm.has_method("refresh"): farm.refresh()
	var gathering: Node = where.get("gathering")
	if is_instance_valid(gathering):
		for part in ["forage", "rocks"]:
			var node: Node = gathering.get(part)
			if is_instance_valid(node): node.refresh(day)
	var choppable: Node = where.get("choppable")
	if is_instance_valid(choppable): choppable.apply_day(day)

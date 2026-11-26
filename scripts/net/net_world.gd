extends Node
## Mundo compartilhado no multijogador (scripts/net/net_session.gd): fazenda, coleta,
## pedras quebradas, árvores cortadas, bancadas, baú e casa valem para os dois.
## Cada lado confere as chaves da sessão a cada CHECK_EVERY s; o que mudou aqui vai
## inteiro para o outro, que grava e redesenha a região.
## shortcut: última escrita vence por chave (dois jogadores mexendo na mesma chave no
## mesmo meio segundo perdem uma ação); trocar por diferenças por item se incomodar.
## Itens soltos no chão sincronizam em scripts/world/item_drops.gd (id por drop; o
## anfitrião decide quem pega). Relógio: o anfitrião manda a hora a cada CLOCK_EVERY s.

const KEYS := ["farm_cells", "forage_taken", "rocks_broken", "chopped_trees",
	"placed_stations", "chest_items", "player_house", "placed_chest_items"]
const CHECK_EVERY := 0.5
const CLOCK_EVERY := 5.0
const CLOCK_SLACK := 2.0  ## minutos de jogo de diferença tolerados
var _clock_time := 0.0

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
	_clock_time += delta
	if _clock_time >= CLOCK_EVERY and str(_session.get("mode")) == "host":
		_clock_time = 0.0
		var clock: Node = get_node("/root/GameClock")
		_session.send({"t": "clock", "day": clock.day_number, "minutes": clock.get_hour() * 60 + clock.get_minute()})
	_time += delta
	if _time < CHECK_EVERY: return
	_time = 0.0
	for key: String in KEYS:
		if not get_tree().has_meta(key): continue
		var value: Variant = get_tree().get_meta(key)
		var h := hash(value)
		if _known.get(key) == h: continue
		_known[key] = h
		_session.send({"t": "world", "key": key, "value": value})


func _on_message(data: Dictionary) -> void:
	if str(data.get("t", "")) == "clock":
		follow_clock(get_node("/root/GameClock"), int(data.get("day", 1)), float(data.get("minutes", 0)))
		return
	if str(data.get("t", "")) != "world": return
	var key := str(data.get("key", ""))
	var value: Variant = data.get("value")
	if not KEYS.has(key) or not (value is Dictionary or value is Array): return  # só chaves conhecidas
	get_tree().set_meta(key, value)
	_known[key] = hash(value)
	apply(region, GameClock.day_number)


## Convidado segue o relógio do anfitrião. Atrasado: avança (viradas de dia acontecem uma
## vez, pelo caminho normal); adiantado no mesmo dia: só ajusta a hora (nunca volta o dia).
static func follow_clock(clock: Node, day: int, minutes: float) -> void:
	var mine: float = clock.day_number * 1440.0 + clock.get_hour() * 60.0 + clock.get_minute()
	var diff: float = day * 1440.0 + minutes - mine
	if diff > CLOCK_SLACK: clock.advance_minutes(diff)
	elif diff < -CLOCK_SLACK and day == int(clock.day_number): clock.set_time(int(minutes) / 60, int(minutes) % 60)


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
	var placer: Node = where.get("placer")
	if is_instance_valid(placer): placer.reload()
	var house: Node = where.get("house")
	if is_instance_valid(house) and house.has_method("rebuild"): house.rebuild()

extends RefCounted
## Obra em etapas (playtest IDs 24 e 40): bancada, baú do chão e casa seguem a mesma
## máquina de estados, guardada no próprio registro da obra (entrada de "placed_stations"
## ou o "player_house" com built = false):
##   prévia (só na tela, sem registro) -> "plan" (planta confirmada SEM custo, esperando
##   materiais) -> "ready" (materiais completos: planta verde) -> "building" (progress > 0;
##   jogadores e o Construlim somam segundos) -> "done" (built = true, uma vez só).
## Campos: cost {item: n}, deposited {item: n}, progress (s), time (s), built.
## Registro sem "cost" (save antigo, ou bancada fabricada antes como item) = já pago.
## Multijogador: o anfitrião é a autoridade dos depósitos, do progresso, da colocação e do
## cancelamento; o convidado manda pedidos "build_*" e vê o resultado pela chave
## sincronizada (net_world.gd). Depósito do convidado: sai da bolsa antes do pedido e o
## anfitrião devolve o que sobrar (build_back), então nunca duplica item.

const HOUSE := preload("res://scripts/systems/house_state.gd")
const CRAFTING := preload("res://scripts/systems/crafting.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const STATIONS_KEY := "placed_stations"
const HOUSE_ID := "casa"
## Segundos de obra de um jogador sozinho (dois juntos = metade).
const TIMES := {"bancada": 10.0, "bau_campo": 5.0}
const MAX_WORK_MESSAGE := 1.0  ## segundos aceitos por pedido do convidado


static func station_id(entry: Dictionary) -> String:
	return "%s_%d_%d" % [entry.region, int(entry.x), int(entry.y)]


## Registro novo de bancada/baú. paid: o item já fabricado foi gasto (materiais completos).
static func new_station(region: String, at: Vector2, kind: String, paid: bool = false) -> Dictionary:
	var cost: Dictionary = (CRAFTING.recipe(kind).get("inputs", {}) as Dictionary).duplicate()
	return {"region": region, "x": at.x, "y": at.y, "kind": kind, "built": false, "progress": 0.0,
		"time": float(TIMES.get(kind, 10.0)), "cost": cost, "deposited": cost.duplicate() if paid else {}}


## Registro vivo da obra (mexer nele muda a sessão); {} se não existe mais.
static func find(tree: SceneTree, id: String) -> Dictionary:
	if id == HOUSE_ID:
		return HOUSE.data(tree) if HOUSE.planned(tree) else {}
	for entry: Dictionary in tree.get_meta(STATIONS_KEY, []):
		if station_id(entry) == id: return entry
	return {}


static func stage(site: Dictionary) -> String:
	if site.is_empty() or bool(site.get("built", true)): return "done"
	if not remaining(site).is_empty(): return "plan"
	return "building" if float(site.get("progress", 0.0)) > 0.0 else "ready"


static func remaining(site: Dictionary) -> Dictionary:
	var cost: Dictionary = site.get("cost", {})
	var have: Dictionary = site.get("deposited", {})
	var out := {}
	for item in cost:
		var n := int(cost[item]) - int(have.get(item, 0))
		if n > 0: out[item] = n
	return out


static func time_of(site: Dictionary) -> float:
	return float(site.get("time", TIMES.get(str(site.get("kind", "bancada")), 10.0)))


## O que a bolsa tem do que falta (o que um [F] na planta deposita).
static func offer_from_bag(tree: SceneTree, site: Dictionary) -> Dictionary:
	var need := remaining(site)
	var out := {}
	for item in need:
		var n := mini(int(need[item]), BAG.count_item(tree, item))
		if n > 0: out[item] = n
	return out


## Põe na obra até `offered`; devolve o que entrou (nunca passa do que falta).
static func deposit(tree: SceneTree, id: String, offered: Dictionary) -> Dictionary:
	var site := find(tree, id)
	var took := {}
	if stage(site) != "plan": return took
	var need := remaining(site)
	var have: Dictionary = (site.get("deposited", {}) as Dictionary).duplicate()
	for item in offered:
		var n := mini(int(offered[item]), int(need.get(item, 0)))
		if n <= 0: continue
		have[item] = int(have.get(item, 0)) + n
		took[item] = n
	site["deposited"] = have
	return took


## Soma segundos de obra (só com os materiais completos). true = concluiu agora (uma vez).
static func work(tree: SceneTree, id: String, seconds: float) -> bool:
	var site := find(tree, id)
	if not (stage(site) in ["ready", "building"]): return false
	var total := time_of(site)
	site["progress"] = minf(float(site.get("progress", 0.0)) + maxf(seconds, 0.0), total)
	if float(site.progress) < total: return false
	if id == HOUSE_ID: HOUSE.complete(tree)
	else: site["built"] = true
	return true


## Desfaz a planta (não a obra pronta) e devolve o que fora depositado.
static func cancel(tree: SceneTree, id: String) -> Dictionary:
	var site := find(tree, id)
	if stage(site) == "done": return {}
	var back: Dictionary = (site.get("deposited", {}) as Dictionary).duplicate()
	if id == HOUSE_ID:
		tree.set_meta(HOUSE.KEY, HOUSE.empty())
		return back
	if not site.has("cost"): back = {str(site.get("kind", "bancada")): 1}  # save antigo: o item volta
	tree.set_meta(STATIONS_KEY, (tree.get_meta(STATIONS_KEY, []) as Array).filter(func(e: Dictionary) -> bool: return station_id(e) != id))
	return back


## Dá itens à bolsa; o que não couber vai ao chão (drops = item_drops da região) ou se perde.
static func give(tree: SceneTree, items: Dictionary, drops: Node = null, at: Vector2 = Vector2.ZERO) -> void:
	for item in items:
		var left := int(items[item])
		while left > 0 and BAG.add_item(tree, str(item)): left -= 1
		if left > 0 and is_instance_valid(drops): drops.call("spawn", str(item), left, at)


## Texto junto da obra: o que falta (depositado/necessário) ou o estado.
static func status_text(site: Dictionary) -> String:
	match stage(site):
		"plan":
			var lines: PackedStringArray = []
			var have: Dictionary = site.get("deposited", {})
			for item in site.get("cost", {}):
				lines.append("%s %d/%d" % [str(ITEMS.info(item).name), int(have.get(item, 0)), int(site.cost[item])])
			return "\n".join(lines)
		"ready": return "Materiais completos!\n[F] construir"
		"building": return "Construindo %d%%" % mini(99, int(float(site.progress) / time_of(site) * 100.0))
	return ""


## "Falta 2 graveto, 4 pedrinha" (o que ainda falta depositar).
static func missing_text(site: Dictionary) -> String:
	var need := remaining(site)
	return ("Falta " + items_text(need)) if not need.is_empty() else ""


## "3 graveto, 1 corda".
static func items_text(items: Dictionary) -> String:
	var parts: PackedStringArray = []
	for item in items: parts.append("%d %s" % [int(items[item]), str(ITEMS.info(item).name).to_lower()])
	return ", ".join(parts)


static func _items(value: Variant) -> Dictionary:
	var out := {}
	if not value is Dictionary: return out
	for item in value:
		var n := clampi(int(value[item]), 0, 999)
		if ITEMS.ITEMS.has(str(item)) and n > 0: out[str(item)] = n
	return out


## Mensagens de obra (net_world.gd). Anfitrião aplica os pedidos; o convidado recebe o
## que voltou. true = a mensagem era de obra (o mapa precisa redesenhar as plantas).
static func handle(tree: SceneTree, data: Dictionary, session: Node, drops: Node = null) -> bool:
	var kind := str(data.get("t", ""))
	if not kind.begins_with("build_") or kind == "build_ghost": return false
	var host := str(session.get("mode")) == "host"
	var id := str(data.get("id", ""))
	match kind:
		"build_place":
			var region := str(data.get("region", ""))
			var what := str(data.get("kind", ""))
			if not host or region.is_empty() or not TIMES.has(what): return true
			var entry := new_station(region, Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0))), what, bool(data.get("paid", false)))
			if find(tree, station_id(entry)).is_empty():
				tree.set_meta(STATIONS_KEY, (tree.get_meta(STATIONS_KEY, []) as Array) + [entry])
		"build_dep":
			if not host: return true
			var offered := _items(data.get("items"))
			var took := deposit(tree, id, offered)
			var back := {}
			for item in offered:
				if int(offered[item]) > int(took.get(item, 0)): back[item] = int(offered[item]) - int(took.get(item, 0))
			if not back.is_empty(): session.call("send", {"t": "build_back", "items": back})
		"build_work":
			if host: work(tree, id, clampf(float(data.get("s", 0.0)), 0.0, MAX_WORK_MESSAGE))
		"build_cancel":
			if not host: return true
			var back := cancel(tree, id)
			if not back.is_empty(): session.call("send", {"t": "build_back", "items": back})
		"build_back":
			if not host:
				var at := Vector2.ZERO
				if is_instance_valid(drops) and is_instance_valid(drops.get("player")): at = (drops.get("player") as Node2D).global_position
				give(tree, _items(data.get("items")), drops, at)
	return true

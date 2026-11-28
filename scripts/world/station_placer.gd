extends Node2D
## Construção posicionável (CRIACAO.md, etapa 4; obra em etapas, playtest IDs 23, 24 e 40).
## Uma prévia segue o mouse (dentro de PLACE_REACH; sem mouse perto, fica à frente do
## jogador), verde = pode, vermelha = não pode; clique ou [F] confirma a PLANTA:
## - escolhida na fabricação (begin_plan): não gasta nada; o material vem depois;
## - com o item já fabricado na barra (saves antigos): gasta o item e a planta já nasce paga.
## Na planta, [F] deposita o que a bolsa tem do que falta; completa, ela fica verde e [F]
## constrói (sozinho, em dupla ou com o Construlim, que somam). Clique direito na planta
## cancela e devolve o depositado. A planta da casa (house_builder.gd) entra aqui também.
## Estado e regras: scripts/systems/build_site.gd (o anfitrião é a autoridade no multijogador).
## Bancadas e baús ficam salvos por região (PLACED_KEY); [F] perto de uma bancada pronta
## abre a fabricação no modo bancada.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const BUILD := preload("res://scripts/systems/build_site.gd")
const HOUSE := preload("res://scripts/systems/house_state.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const PLACED_KEY := "placed_stations"
const ART := preload("res://assets/world/crafting/workbench.png")
const FOOTPRINT := Vector2(44, 16)  # base sólida (pés da bancada)
## Construções que se colocam no chão: bancada e baú (2026-11-23; o Carreguim leva ao baú).
const KINDS := {
	"bancada": {"art": ART, "footprint": FOOTPRINT, "name": "a bancada", "build": BUILD.TIMES.bancada,
		"done": "Bancada pronta! Use [F] nela para fabricar."},
	"bau_campo": {"art": preload("res://assets/objects/furniture/bau.png"), "footprint": Vector2(30, 12), "name": "o baú", "build": BUILD.TIMES.bau_campo,
		"done": "Baú pronto! Use [F] para guardar; o Carreguim também traz coisas para cá."},
}
const HOUSE_DONE := "Casa pronta! Coloque a cama para poder dormir."
## Planta esperando material: azul translúcida; materiais completos: verde (pronta para
## construir); construindo: enche de amarelo de baixo para cima (blueprint_fill.gdshader).
const BLUEPRINT := Color(0.55, 0.85, 1.0, 0.55)
const READY := Color(0.45, 1.0, 0.55, 0.65)
const FILL_SHADER := preload("res://scripts/world/blueprint_fill.gdshader")
const MOVES := ["move_left", "move_right", "move_up", "move_down"]
const WORK_SEND_EVERY := 0.2  ## convidado: segundos de obra juntados por mensagem
const GHOST_SEND_EVERY := 0.1
## Id da obra que ESTE jogador constrói agora (id, não o nó: a sincronização recria os nós;
## guardar o nó era o que cancelava a obra de quem ajudava — playtest ID 24).
var _building := ""
var _net_work := 0.0
var _plan_kind := ""  ## planta escolhida na fabricação (prévia sem custo)
var _plan_frame := -1
var _open_sites := {}  ## id -> tipo das obras ainda não prontas (avisa uma vez ao concluir)
## Aviso para a região mostrar (planta colocada, depósito, obra pronta...); ela limpa.
var notice := ""
## Construtor da casa da região (house_builder.gd): a planta da casa vira uma obra aqui.
var house: Node2D
var _session: Node
var _remote_ghost: Sprite2D
var _remote_area: Node2D
var _remote_rect := Rect2()
var _remote_ok := true
var _ghost_wait := 0.0
var _ghost_shown := false
## Abre o baú colocado (a região liga em open_chest(id)).
var open_chest: Callable
const AHEAD := 44.0
const USE_REACH := 48.0
const PLACE_REACH := 150.0
var _click := false  # clique esquerdo neste quadro (coloca onde o mouse está)
var _right_click := false  # clique direito neste quadro (cancela a planta sob o mouse)
const DIRS := {"south": Vector2(0, 1), "north": Vector2(0, -1), "east": Vector2(1, 0), "west": Vector2(-1, 0),
	"south-east": Vector2(1, 1), "south-west": Vector2(-1, 1), "north-east": Vector2(1, -1), "north-west": Vector2(-1, -1)}

var region_id := ""
## Chão bloqueado além da física (água etc.); a região informa.
var blocked: Callable = func(_at: Vector2) -> bool: return false
var _ghost: Sprite2D
var _stations: Array[Node2D] = []


func setup(id: String) -> void:
	name = "StationPlacer"
	region_id = id
	y_sort_enabled = true
	_ghost = _ghost_sprite()
	_remote_ghost = _ghost_sprite()  # prévia do outro jogador (ID 23)
	_remote_area = Node2D.new()
	_remote_area.z_as_relative = false
	_remote_area.z_index = 39
	_remote_area.draw.connect(func() -> void:
		if _remote_rect.has_area():
			_remote_area.draw_rect(_remote_rect, Color(0.4, 1, 0.5, 0.12) if _remote_ok else Color(1, 0.35, 0.3, 0.12))
			_remote_area.draw_rect(_remote_rect, Color(0.5, 1, 0.6, 0.7) if _remote_ok else Color(1, 0.45, 0.4, 0.7), false, 2.0))
	add_child(_remote_area)
	_session = get_node_or_null("/root/NetSession")
	if _session: _session.message.connect(_on_message)
	reload()


func _ghost_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = ART
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Vector2(0, -ART.get_height() * 0.5 + 4)
	sprite.visible = false
	sprite.z_index = 5
	add_child(sprite)
	return sprite


## Liga a casa da região: a planta dela aparece aqui como obra.
func attach_house(builder: Node2D) -> void:
	house = builder
	builder.set("placer", self)
	reload()


## Refaz as plantas e construções desta região a partir da sessão (multijogador: o outro
## colocou, depositou ou construiu).
## Mantém os nós que continuam (só repinta) e cria/tira o que mudou.
func reload() -> void:
	var want := {}
	for entry: Dictionary in _saved():
		if str(entry.region) == region_id: want[BUILD.station_id(entry)] = entry
	var plan := _house_plan()
	if not plan.is_empty(): want[BUILD.HOUSE_ID] = plan
	for station in _stations.duplicate():
		var id := str(station.get_meta("id"))
		var same: bool = want.has(id) and str(want[id].get("kind", BUILD.HOUSE_ID)) == str(station.get_meta("kind")) \
			and (not station.has_meta("area") or Rect2(Vector2(plan.rect.position * 32), Vector2(plan.rect.size * 32)) == station.get_meta("area"))
		if same:
			want.erase(id)
			_paint(station)
		else:
			_stations.erase(station)
			station.queue_free()
	for id: String in want:
		if id == BUILD.HOUSE_ID: _spawn_house(want[id])
		else: _spawn(want[id])


func _saved() -> Array:
	return get_tree().get_meta(PLACED_KEY, [])


func _house_plan() -> Dictionary:
	return HOUSE.plan_of(get_tree(), str(house.region_id)) if is_instance_valid(house) else {}


func _guest() -> bool:
	return _session != null and bool(_session.connected) and str(_session.mode) == "guest"


func spot_for(player: Node2D) -> Vector2:
	var mouse := get_global_mouse_position()
	if mouse.distance_to(player.global_position) <= PLACE_REACH and get_viewport().get_visible_rect().has_point(get_viewport().get_mouse_position()):
		return mouse.round()  # prévia segue o mouse
	var dir: Vector2 = DIRS.get(str(player.get("facing")), Vector2(0, 1))
	return (player.global_position + dir.normalized() * AHEAD).round()


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	var key := event as InputEventKey
	if not _plan_kind.is_empty() and ((mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT) or (key and key.pressed and key.physical_keycode == KEY_ESCAPE)):
		_plan_kind = ""  # desiste da prévia escolhida na fabricação
		get_viewport().set_input_as_handled()
		return
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		_right_click = true
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and is_instance_valid(_ghost) and _ghost.visible:
		_click = true
		get_viewport().set_input_as_handled()  # o clique é da construção, não do [F]


## Começa a prévia de uma planta sem custo (botão da fabricação).
func begin_plan(kind: String) -> void:
	if not KINDS.has(kind): return
	_plan_kind = kind
	_plan_frame = Engine.get_process_frames()  # o [F] que apertou o botão não confirma


func can_place(at: Vector2, kind: String = "bancada") -> bool:
	if blocked.call(at): return false
	for station in _stations:
		if station.has_meta("area"):
			if (station.get_meta("area") as Rect2).grow(8.0).has_point(at): return false
		elif station.global_position.distance_to(at) < 56.0: return false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(KINDS.get(kind, KINDS.bancada).footprint) + Vector2(6, 6)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, at + Vector2(0, -Vector2(KINDS.get(kind, KINDS.bancada).footprint).y * 0.5))
	query.collision_mask = 2
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## Chamado a cada quadro pela região. Devolve o texto de dica ("" = nada a dizer) e trata
## [F]: colocar a planta, depositar, construir ou abrir a bancada/o baú próximo. Eventos
## (colocou, depositou, cancelou, pronta) deixam o texto em `notice`.
func update(player: Node2D, interact: bool, open_bench: Callable) -> String:
	var tree := get_tree()
	var held := HOTBAR.selected_item(tree)
	var kind := _plan_kind if not _plan_kind.is_empty() else (held if KINDS.has(held) and BAG.count_item(tree, held) > 0 else "")
	var right := _right_click
	_ghost.visible = not kind.is_empty()
	if _ghost.visible:
		_ghost.texture = KINDS[kind].art
		_ghost.offset = Vector2(0, -_ghost.texture.get_height() * 0.5 + 4)
		var at := spot_for(player)
		var ok := can_place(at, kind)
		_ghost.global_position = at
		_ghost.modulate = Color(0.6, 1.0, 0.6, 0.7) if ok else Color(1.0, 0.45, 0.45, 0.7)
		_send_ghost(kind, at, ok)
		var place := (interact or _click) and Engine.get_process_frames() != _plan_frame
		_click = false
		var what: String = KINDS[kind].name
		if place and ok:
			var paid := _plan_kind.is_empty()
			if paid: BAG.spend_item(tree, kind)
			_place(at, kind, paid)
			_plan_kind = ""
			_ghost.visible = false
			_send_ghost("", at, ok)
			if paid: notice = "Planta d%s no chão! Aperte [F] nela para construir (%d s)." % [what, int(KINDS[kind].build)]
			else: notice = "Planta d%s no chão, sem gastar nada! Traga o material e aperte [F] nela para depositar." % what
			return "placed" if kind == "bancada" else "placed_" + kind
		var tail := " · clique direito cancela" if not _plan_kind.is_empty() else ""
		return ("Clique ou [F] para colocar a planta d%s%s" % [what, tail]) if ok else ("Aqui não dá para colocar %s%s" % [what, tail])
	_send_ghost("", Vector2.ZERO, true)
	if not _building.is_empty():
		return _build_step(player)
	var near := nearest_station(player.global_position)
	if near == null: return ""
	var id := str(near.get_meta("id"))
	var site := BUILD.find(tree, id)
	var stage := BUILD.stage(site)
	var label := _name_of(near).trim_prefix("a ").trim_prefix("o ")
	if right and stage != "done" and _under_mouse(near):
		cancel_site(id)
		return "cancelled"
	match stage:
		"plan":
			if interact: return _deposit(id, site)
			return "[F] Depositar material na planta d%s · %s · clique direito cancela" % [_name_of(near), BUILD.missing_text(site)]
		"ready", "building":
			if interact:
				_building = id
				return _build_step(player)
			return "[F] Construir %s (%d s)" % [label, int(ceil(BUILD.time_of(site) - float(site.get("progress", 0.0))))]
	if str(near.get_meta("kind", "bancada")) == "bau_campo":
		if interact and open_chest.is_valid(): open_chest.call(str(near.get_meta("chest_id")))
		return "[F] Abrir o baú"
	if interact: open_bench.call()
	return "[F] Usar a bancada de trabalho"


func _name_of(station: Node2D) -> String:
	var kind := str(station.get_meta("kind", "bancada"))
	return "a casa" if kind == BUILD.HOUSE_ID else str(KINDS.get(kind, KINDS.bancada).name)


func _under_mouse(station: Node2D) -> bool:
	var mouse := get_global_mouse_position()
	if station.has_meta("area"): return (station.get_meta("area") as Rect2).has_point(mouse)
	return mouse.distance_to(station.global_position + Vector2(0, -12)) < 28.0


## Confirma a planta (o anfitrião é quem grava no multijogador).
func _place(at: Vector2, kind: String, paid: bool) -> void:
	if _guest():
		_session.send({"t": "build_place", "region": region_id, "x": at.x, "y": at.y, "kind": kind, "paid": paid})
		return
	get_tree().set_meta(PLACED_KEY, _saved() + [BUILD.new_station(region_id, at, kind, paid)])
	reload()


## [F] na planta: deposita o que a bolsa tem do que falta (parcial, sem cobrar duas vezes).
func _deposit(id: String, site: Dictionary) -> String:
	var tree := get_tree()
	var offer := BUILD.offer_from_bag(tree, site)
	if offer.is_empty():
		notice = "Nada disso na bolsa. " + BUILD.missing_text(site)
		return "deposited"
	if _guest():  # sai da bolsa já; o anfitrião devolve o que sobrar (build_back)
		var spent := {}
		for item in offer:
			if BAG.spend_item(tree, item, int(offer[item])): spent[item] = int(offer[item])
		_session.send({"t": "build_dep", "id": id, "items": spent})
		notice = "Depositou %s." % BUILD.items_text(spent)
		return "deposited"
	var took := BUILD.deposit(tree, id, offer)
	for item in took: BAG.spend_item(tree, item, int(took[item]))
	var done := BUILD.stage(site) == "ready"
	notice = "Depositou %s. %s" % [BUILD.items_text(took), "Materiais completos! Aperte [F] para construir." if done else BUILD.missing_text(site)]
	reload()
	return "deposited"


## Cancela a planta (não a obra pronta) e devolve o que fora depositado a quem cancelou.
func cancel_site(id: String) -> void:
	if _building == id: _building = ""
	notice = "Planta cancelada; o material depositado voltou para a bolsa."
	if _guest():
		_session.send({"t": "build_cancel", "id": id})
		return
	var where := _node(id).global_position if _node(id) else Vector2.ZERO
	BUILD.give(get_tree(), BUILD.cancel(get_tree(), id), get_parent().get("item_drops") if get_parent() else null, where)
	reload()


## Um quadro de construção: o jogador trabalha agachado; andar pausa (o progresso fica).
## Termina quando a obra conclui — aqui, pelo parceiro ou pelo Construlim.
func _build_step(player: Node2D) -> String:
	var station := _node(_building)
	var site := BUILD.find(get_tree(), _building)
	if station == null or not (BUILD.stage(site) in ["ready", "building"]) \
			or MOVES.any(func(m: String) -> bool: return Input.is_action_pressed(m)) or not _near(station, player.global_position, USE_REACH * 1.5):
		_stop_building(player)
		return ""
	player.facing = player._get_direction_name(station.global_position - player.global_position)
	if player.has_method("hold_pose"): player.hold_pose("pick_big", player.PICK_BIG_GROUND)
	add_progress(station, get_process_delta_time())
	var progress: float = float(site.get("progress", 0.0))
	return "Construindo %s... %d%% · andar pausa" % [_name_of(station).trim_prefix("a ").trim_prefix("o "), mini(99, int(progress / BUILD.time_of(site) * 100.0))]


func _stop_building(player: Node2D) -> void:
	_flush_work()
	_building = ""
	if player.has_method("release_pose"): player.release_pose()


## Soma `seconds` de obra à planta (jogador ou Construlim; juntos somam). No convidado vai
## para o anfitrião, que soma as contribuições. Devolve true quando ela está pronta.
func add_progress(station: Node2D, seconds: float) -> bool:
	var id := str(station.get_meta("id"))
	if _guest():
		_net_work += seconds
		if _net_work >= WORK_SEND_EVERY: _flush_work()
	else:
		BUILD.work(get_tree(), id, seconds)
		_paint(station)
	return BUILD.stage(BUILD.find(get_tree(), id)) == "done"


func _flush_work() -> void:
	if _net_work > 0.0 and _guest() and not _building.is_empty():
		_session.send({"t": "build_work", "id": _building, "s": _net_work})
	_net_work = 0.0


## Plantas com material completo nesta região (o Construlim escolhe a mais perto). No
## convidado fica vazio: o Construlim do anfitrião é quem trabalha (sem contar dobrado).
func blueprints() -> Array[Node2D]:
	var out: Array[Node2D] = []
	if _guest(): return out
	for station in _stations:
		if is_instance_valid(station) and BUILD.stage(BUILD.find(get_tree(), str(station.get_meta("id")))) in ["ready", "building"]: out.append(station)
	return out


## Avisa uma vez quando uma obra desta região conclui (qualquer que tenha sido o construtor)
## e redesenha. Limpa os cliques deste quadro (a região já chamou update()).
func _process(delta: float) -> void:
	_click = false
	_right_click = false
	_share_house_ghost(delta)
	var open := {}
	var finished: Array[String] = []
	for entry: Dictionary in _saved():
		if str(entry.region) != region_id: continue
		var id := BUILD.station_id(entry)
		if BUILD.stage(entry) != "done": open[id] = str(entry.get("kind", "bancada"))
		elif _open_sites.has(id): finished.append(str(_open_sites[id]))
	if not _house_plan().is_empty(): open[BUILD.HOUSE_ID] = BUILD.HOUSE_ID
	elif _open_sites.has(BUILD.HOUSE_ID) and is_instance_valid(house) and HOUSE.region_of(get_tree()) == str(house.region_id): finished.append(BUILD.HOUSE_ID)
	_open_sites = open
	if finished.is_empty(): return
	reload()
	if finished.has(BUILD.HOUSE_ID) and house.has_method("rebuild"): house.rebuild()
	notice = HOUSE_DONE if finished[0] == BUILD.HOUSE_ID else str(KINDS.get(finished[0], KINDS.bancada).done)
	preload("res://scripts/systems/sfx.gd").play(get_tree(), "fabricar")


## Baús colocados (todas as regiões): [{id, region, at}] — o Carreguim escolhe entre eles.
static func chests(tree: SceneTree) -> Array:
	var out: Array = []
	for entry: Dictionary in tree.get_meta(PLACED_KEY, []):
		if str(entry.get("kind", "bancada")) == "bau_campo" and bool(entry.get("built", true)):
			out.append({"id": chest_id(entry), "region": str(entry.region), "at": Vector2(entry.x, entry.y)})
	return out


static func chest_id(entry: Dictionary) -> String:
	return BUILD.station_id(entry)


func nearest_station(at: Vector2) -> Node2D:
	var plan: Node2D = null
	for station in _stations:
		if station.has_meta("area"):
			if _near(station, at, USE_REACH): plan = station
		elif station.global_position.distance_to(at) < USE_REACH: return station
	return plan


func _node(id: String) -> Node2D:
	for station in _stations:
		if is_instance_valid(station) and str(station.get_meta("id")) == id: return station
	return null


## Perto da obra. A casa conta a área toda, mas de fora (quem está dentro não fica preso
## nas paredes quando ela conclui).
func _near(station: Node2D, at: Vector2, reach: float) -> bool:
	if station.has_meta("area"):
		var area: Rect2 = station.get_meta("area")
		return area.grow(reach * 0.75).has_point(at) and not area.has_point(at)
	return station.global_position.distance_to(at) < reach


func _spawn(entry: Dictionary) -> void:
	var kind := str(entry.get("kind", "bancada"))
	var info: Dictionary = KINDS.get(kind, KINDS.bancada)
	var at := Vector2(entry.x, entry.y)
	var station := Node2D.new()
	station.name = "Workbench" if kind == "bancada" else "Chest"
	station.global_position = at
	station.set_meta("kind", kind)
	station.set_meta("id", BUILD.station_id(entry))
	station.set_meta("chest_id", chest_id(entry))
	add_child(station)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	var art: Texture2D = info.art
	sprite.texture = art
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Vector2(0, -art.get_height() * 0.5 + 4)
	station.add_child(sprite)
	var body := StaticBody2D.new()
	body.name = "Body"
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = info.footprint
	shape.shape = rect
	shape.position = Vector2(0, -Vector2(info.footprint).y * 0.5)
	body.add_child(shape)
	station.add_child(body)
	_add_label(station, Vector2(-70, -art.get_height() - 4), true)
	_stations.append(station)
	_paint(station)


## Obra da casa: um ponto embaixo da porta com o texto; a planta em si o house_builder desenha.
func _spawn_house(plan: Dictionary) -> void:
	var rect: Rect2i = plan.rect
	var area := Rect2(Vector2(rect.position * 32), Vector2(rect.size * 32))
	var station := Node2D.new()
	station.name = "HousePlan"
	station.global_position = Vector2(area.get_center().x, area.end.y + 4)
	station.set_meta("kind", BUILD.HOUSE_ID)
	station.set_meta("id", BUILD.HOUSE_ID)
	station.set_meta("area", area)
	add_child(station)
	_add_label(station, Vector2(-70, 4), false)
	_stations.append(station)
	_paint(station)


## Texto do que falta; `up`: cresce para cima (acima da arte), senão para baixo (casa).
func _add_label(station: Node2D, at: Vector2, up: bool) -> void:
	var label := Label.new()
	label.name = "Needs"
	label.position = at
	label.size = Vector2(140, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM if up else VERTICAL_ALIGNMENT_TOP
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN if up else Control.GROW_DIRECTION_END
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.05, 0.9))
	label.z_index = 20
	station.add_child(label)


## Cor e texto conforme a etapa: azul (falta material), verde (pronta), amarelo (construindo),
## arte normal e sólida (concluída).
func _paint(station: Node2D) -> void:
	var site := BUILD.find(get_tree(), str(station.get_meta("id")))
	var stage := BUILD.stage(site)
	station.set_meta("built", stage == "done")
	station.set_meta("progress", float(site.get("progress", 0.0)))
	var label := station.get_node("Needs") as Label
	label.text = BUILD.status_text(site)
	label.visible = stage != "done"
	label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.75) if stage != "plan" else Color(0.85, 0.95, 1.0))
	var sprite := station.get_node_or_null("Sprite") as Sprite2D
	if sprite == null: return
	var body := station.get_node("Body") as StaticBody2D
	body.collision_layer = 2 if stage == "done" else 0  # a planta não bloqueia a passagem
	if stage == "done":
		sprite.material = null
		return
	var fill := sprite.material as ShaderMaterial
	if fill == null:
		fill = ShaderMaterial.new()
		fill.shader = FILL_SHADER
		sprite.material = fill
	fill.set_shader_parameter("plan_color", BLUEPRINT if stage == "plan" else READY)
	fill.set_shader_parameter("progress", clampf(float(site.get("progress", 0.0)) / BUILD.time_of(site), 0.0, 1.0))


# --- Prévia compartilhada (playtest ID 23) ---------------------------------------

## Manda a prévia deste jogador ao outro (kind "" = escondeu).
func _send_ghost(kind: String, at: Vector2, ok: bool) -> void:
	if _session == null or not bool(_session.connected): return
	if kind.is_empty():
		if _ghost_shown: _session.send({"t": "build_ghost", "sc": region_id, "k": ""})
		_ghost_shown = false
		return
	_ghost_wait -= get_process_delta_time()
	if _ghost_wait > 0.0 and _ghost_shown: return
	_ghost_wait = GHOST_SEND_EVERY
	_ghost_shown = true
	_session.send({"t": "build_ghost", "sc": region_id, "k": kind, "x": at.x, "y": at.y, "ok": ok})


## Arraste da casa no modo construir também aparece para o outro.
func _share_house_ghost(delta: float) -> void:
	if not is_instance_valid(house) or _session == null or not bool(_session.connected): return
	if not bool(house.get("building")) or str(house.get("mode")) != "house": return
	_ghost_wait -= delta
	if _ghost_wait > 0.0: return
	_ghost_wait = GHOST_SEND_EVERY
	var rect: Rect2i = house.call("drag_area")
	var ok := HOUSE.place_problem(get_tree(), rect, house.get("blocked_world"), house.call("player_cell")).is_empty()
	_session.send({"t": "build_ghost", "sc": region_id, "k": BUILD.HOUSE_ID, "r": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "ok": ok, "until": 0.4})


func _on_message(data: Dictionary) -> void:
	if str(data.get("t", "")) != "build_ghost": return
	var kind := str(data.get("k", ""))
	var here := str(data.get("sc", "")) == region_id
	_remote_ghost.visible = here and KINDS.has(kind)
	if _remote_ghost.visible:
		_remote_ghost.texture = KINDS[kind].art
		_remote_ghost.offset = Vector2(0, -_remote_ghost.texture.get_height() * 0.5 + 4)
		_remote_ghost.global_position = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
		_remote_ghost.modulate = Color(0.6, 1.0, 0.6, 0.45) if bool(data.get("ok", true)) else Color(1.0, 0.45, 0.45, 0.45)
	_remote_rect = Rect2()
	var r: Variant = data.get("r")
	if here and kind == BUILD.HOUSE_ID and r is Array and (r as Array).size() == 4:
		_remote_rect = Rect2(Vector2(float(r[0]), float(r[1])) * 32.0, Vector2(float(r[2]), float(r[3])) * 32.0)
		_remote_ok = bool(data.get("ok", true))
		_remote_area.get_tree().create_timer(float(data.get("until", 0.4))).timeout.connect(_expire_rect.bind(_remote_rect))
	_remote_area.queue_redraw()


## O arraste da casa some sozinho quando o outro para de mandar (saiu do modo construir).
func _expire_rect(rect: Rect2) -> void:
	if _remote_rect == rect:
		_remote_rect = Rect2()
		_remote_area.queue_redraw()

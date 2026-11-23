extends Node2D
## Construção posicionável (CRIACAO.md, etapa 4): com a bancada selecionada na barra,
## uma prévia segue o mouse (dentro de PLACE_REACH; sem mouse perto, fica à frente do
## jogador), verde = pode, vermelha = não pode; clique ou [F] a coloca, gastando o item. Bancadas colocadas ficam salvas por região
## (PLACED_KEY) e [F] perto de uma abre a janela de fabricação no modo bancada.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const PLACED_KEY := "placed_stations"
const ART := preload("res://assets/world/crafting/workbench.png")
const FOOTPRINT := Vector2(44, 16)  # base sólida (pés da bancada)
## Construções que se colocam no chão: bancada e baú (2026-11-23; o Carreguim leva ao baú).
const KINDS := {
	"bancada": {"art": ART, "footprint": FOOTPRINT, "name": "a bancada", "build": 10.0},
	"bau_campo": {"art": preload("res://assets/objects/furniture/bau.png"), "footprint": Vector2(30, 12), "name": "o baú", "build": 5.0},
}
## Planta de construção (pedido do usuário, 2026-11-23): colocar deixa a planta no chão;
## [F] nela começa a construir (segue sozinho, andar cancela; o progresso fica salvo).
## Futuro: um slime que ajuda a construir.
const BLUEPRINT := Color(0.55, 0.85, 1.0, 0.55)
const FILL_SHADER := preload("res://scripts/world/blueprint_fill.gdshader")
const MOVES := ["move_left", "move_right", "move_up", "move_down"]
var _building: Node2D  ## planta sendo construída agora
var _save_wait := 0.0
## Abre o baú colocado (a região liga em open_chest(id)).
var open_chest: Callable
const AHEAD := 44.0
const USE_REACH := 48.0
const PLACE_REACH := 150.0
var _click := false  # clique esquerdo neste quadro (coloca onde o mouse está)
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
	_ghost = Sprite2D.new()
	_ghost.texture = ART
	_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ghost.offset = Vector2(0, -ART.get_height() * 0.5 + 4)
	_ghost.visible = false
	_ghost.z_index = 5
	add_child(_ghost)
	for entry: Dictionary in _saved():
		if str(entry.region) == region_id:
			_spawn(Vector2(entry.x, entry.y), str(entry.get("kind", "bancada")), bool(entry.get("built", true)), float(entry.get("progress", 0.0)))


## Refaz as bancadas desta região a partir da sessão (multijogador: o outro colocou uma).
func reload() -> void:
	for station in _stations: station.queue_free()
	_stations.clear()
	for entry: Dictionary in _saved():
		if str(entry.region) == region_id:
			_spawn(Vector2(entry.x, entry.y), str(entry.get("kind", "bancada")), bool(entry.get("built", true)), float(entry.get("progress", 0.0)))


func _saved() -> Array:
	return get_tree().get_meta(PLACED_KEY, [])


func spot_for(player: Node2D) -> Vector2:
	var mouse := get_global_mouse_position()
	if mouse.distance_to(player.global_position) <= PLACE_REACH and get_viewport().get_visible_rect().has_point(get_viewport().get_mouse_position()):
		return mouse.round()  # prévia segue o mouse
	var dir: Vector2 = DIRS.get(str(player.get("facing")), Vector2(0, 1))
	return (player.global_position + dir.normalized() * AHEAD).round()


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and is_instance_valid(_ghost) and _ghost.visible:
		_click = true
		get_viewport().set_input_as_handled()  # o clique é da construção, não do [F]


func can_place(at: Vector2, kind: String = "bancada") -> bool:
	if blocked.call(at): return false
	for station in _stations:
		if station.global_position.distance_to(at) < 56.0: return false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(KINDS.get(kind, KINDS.bancada).footprint) + Vector2(6, 6)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, at + Vector2(0, -Vector2(KINDS.get(kind, KINDS.bancada).footprint).y * 0.5))
	query.collision_mask = 2
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## Chamado a cada quadro pela região. Devolve o texto de dica ("" = nada a dizer)
## e trata [F]: colocar a bancada ou abrir a bancada próxima.
func update(player: Node2D, interact: bool, open_bench: Callable) -> String:
	var kind := HOTBAR.selected_item(get_tree())
	var holding := KINDS.has(kind) and BAG.count_item(get_tree(), kind) > 0
	_ghost.visible = holding
	if holding:
		_ghost.texture = KINDS[kind].art
		_ghost.offset = Vector2(0, -_ghost.texture.get_height() * 0.5 + 4)
		var at := spot_for(player)
		var ok := can_place(at, kind)
		_ghost.global_position = at
		_ghost.modulate = Color(0.6, 1.0, 0.6, 0.7) if ok else Color(1.0, 0.45, 0.45, 0.7)
		var place := interact or _click
		_click = false
		if place and ok:
			BAG.spend_item(get_tree(), kind)
			_spawn(at, kind, false)
			var saved := _saved().duplicate()
			saved.append({"region": region_id, "x": at.x, "y": at.y, "kind": kind, "built": false, "progress": 0.0})
			get_tree().set_meta(PLACED_KEY, saved)
			_ghost.visible = false
			return "placed" if kind == "bancada" else "placed_" + kind
		var what: String = KINDS[kind].name
		return ("Clique ou [F] para colocar " + what) if ok else ("Aqui não dá para colocar " + what)
	if is_instance_valid(_building):
		return _build_step(player)
	var near := nearest_station(player.global_position)
	if near != null and not bool(near.get_meta("built", true)):
		var info: Dictionary = KINDS.get(str(near.get_meta("kind")), KINDS.bancada)
		if interact:
			_building = near
			return _build_step(player)
		return "[F] Construir %s (%d s)" % [str(info.name).trim_prefix("a ").trim_prefix("o "), int(ceil(float(info.build) - float(near.get_meta("progress", 0.0))))]
	if near != null:
		if str(near.get_meta("kind", "bancada")) == "bau_campo":
			if interact and open_chest.is_valid(): open_chest.call(str(near.get_meta("chest_id")))
			return "[F] Abrir o baú"
		if interact: open_bench.call()
		return "[F] Usar a bancada de trabalho"
	return ""


## Um quadro de construção: o jogador trabalha agachado; andar cancela (fica o progresso).
func _build_step(player: Node2D) -> String:
	var station := _building
	if MOVES.any(func(m: String) -> bool: return Input.is_action_pressed(m)) or station.global_position.distance_to(player.global_position) > USE_REACH * 1.5:
		_building = null
		if player.has_method("release_pose"): player.release_pose()
		_store_progress(station)
		return ""
	var info: Dictionary = KINDS.get(str(station.get_meta("kind")), KINDS.bancada)
	var progress: float = float(station.get_meta("progress", 0.0)) + get_process_delta_time()
	station.set_meta("progress", progress)
	var sprite_fill := (station.get_node("Sprite") as Sprite2D).material as ShaderMaterial
	if sprite_fill: sprite_fill.set_shader_parameter("progress", clampf(progress / float(info.build), 0.0, 1.0))
	player.facing = player._get_direction_name(station.global_position - player.global_position)
	if player.has_method("hold_pose"): player.hold_pose("pick_big", player.PICK_BIG_GROUND)
	_save_wait -= get_process_delta_time()
	if _save_wait <= 0.0:
		_save_wait = 1.0
		_store_progress(station)
	if progress < float(info.build):
		return "Construindo %s... %d%% · andar cancela" % [str(info.name).trim_prefix("a ").trim_prefix("o "), mini(99, int(progress / float(info.build) * 100.0))]
	_building = null
	if player.has_method("release_pose"): player.release_pose()
	station.set_meta("built", true)
	_store_progress(station)
	_finish(station)
	return "built" if str(station.get_meta("kind")) == "bancada" else "built_" + str(station.get_meta("kind"))


## Grava built/progresso da construção na sessão.
func _store_progress(station: Node2D) -> void:
	var saved := _saved().duplicate(true)
	for entry: Dictionary in saved:
		if str(entry.region) == region_id and Vector2(entry.x, entry.y).distance_to(station.global_position) < 1.0:
			entry["built"] = bool(station.get_meta("built", true))
			entry["progress"] = float(station.get_meta("progress", 0.0))
	get_tree().set_meta(PLACED_KEY, saved)


## Planta vira construção pronta: cor normal e passa a bloquear a passagem.
func _finish(station: Node2D) -> void:
	(station.get_node("Sprite") as Sprite2D).material = null  # pronta: arte normal
	var body := station.get_node("Body") as StaticBody2D
	body.collision_layer = 2


## Baús colocados (todas as regiões): [{id, region, at}] — o Carreguim escolhe entre eles.
static func chests(tree: SceneTree) -> Array:
	var out: Array = []
	for entry: Dictionary in tree.get_meta(PLACED_KEY, []):
		if str(entry.get("kind", "bancada")) == "bau_campo" and bool(entry.get("built", true)):
			out.append({"id": chest_id(entry), "region": str(entry.region), "at": Vector2(entry.x, entry.y)})
	return out


static func chest_id(entry: Dictionary) -> String:
	return "%s_%d_%d" % [entry.region, int(entry.x), int(entry.y)]


func nearest_station(at: Vector2) -> Node2D:
	for station in _stations:
		if station.global_position.distance_to(at) < USE_REACH: return station
	return null


func _spawn(at: Vector2, kind: String = "bancada", built: bool = true, progress: float = 0.0) -> void:
	var info: Dictionary = KINDS.get(kind, KINDS.bancada)
	var station := Node2D.new()
	station.name = "Workbench" if kind == "bancada" else "Chest"
	station.global_position = at
	station.set_meta("kind", kind)
	station.set_meta("chest_id", chest_id({"region": region_id, "x": at.x, "y": at.y}))
	station.set_meta("built", built)
	station.set_meta("progress", progress)
	add_child(station)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	if not built:  # planta: azul translúcida; enche de amarelo ao construir
		var fill := ShaderMaterial.new()
		fill.shader = FILL_SHADER
		fill.set_shader_parameter("progress", progress / float(info.build))
		sprite.material = fill
	var art: Texture2D = info.art
	sprite.texture = art
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Vector2(0, -art.get_height() * 0.5 + 4)
	station.add_child(sprite)
	var body := StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 2 if built else 0  # a planta não bloqueia a passagem
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = info.footprint
	shape.shape = rect
	shape.position = Vector2(0, -Vector2(info.footprint).y * 0.5)
	body.add_child(shape)
	station.add_child(body)
	_stations.append(station)

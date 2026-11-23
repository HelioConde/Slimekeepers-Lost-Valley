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
			_spawn(Vector2(entry.x, entry.y))


## Refaz as bancadas desta região a partir da sessão (multijogador: o outro colocou uma).
func reload() -> void:
	for station in _stations: station.queue_free()
	_stations.clear()
	for entry: Dictionary in _saved():
		if str(entry.region) == region_id:
			_spawn(Vector2(entry.x, entry.y))


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


func can_place(at: Vector2) -> bool:
	if blocked.call(at): return false
	for station in _stations:
		if station.global_position.distance_to(at) < 56.0: return false
	var shape := RectangleShape2D.new()
	shape.size = FOOTPRINT + Vector2(6, 6)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, at + Vector2(0, -FOOTPRINT.y * 0.5))
	query.collision_mask = 2
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## Chamado a cada quadro pela região. Devolve o texto de dica ("" = nada a dizer)
## e trata [F]: colocar a bancada ou abrir a bancada próxima.
func update(player: Node2D, interact: bool, open_bench: Callable) -> String:
	var holding := HOTBAR.selected_item(get_tree()) == "bancada" and BAG.count_item(get_tree(), "bancada") > 0
	_ghost.visible = holding
	if holding:
		var at := spot_for(player)
		var ok := can_place(at)
		_ghost.global_position = at
		_ghost.modulate = Color(0.6, 1.0, 0.6, 0.7) if ok else Color(1.0, 0.45, 0.45, 0.7)
		var place := interact or _click
		_click = false
		if place and ok:
			BAG.spend_item(get_tree(), "bancada")
			_spawn(at)
			var saved := _saved().duplicate()
			saved.append({"region": region_id, "x": at.x, "y": at.y})
			get_tree().set_meta(PLACED_KEY, saved)
			_ghost.visible = false
			return "placed"
		return "Clique ou [F] para colocar a bancada" if ok else "Aqui não dá para colocar a bancada"
	var near := nearest_station(player.global_position)
	if near != null:
		if interact: open_bench.call()
		return "[F] Usar a bancada de trabalho"
	return ""


func nearest_station(at: Vector2) -> Node2D:
	for station in _stations:
		if station.global_position.distance_to(at) < USE_REACH: return station
	return null


func _spawn(at: Vector2) -> void:
	var station := Node2D.new()
	station.name = "Workbench"
	station.global_position = at
	add_child(station)
	var sprite := Sprite2D.new()
	sprite.texture = ART
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Vector2(0, -ART.get_height() * 0.5 + 4)
	station.add_child(sprite)
	var body := StaticBody2D.new()
	body.collision_layer = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = FOOTPRINT
	shape.shape = rect
	shape.position = Vector2(0, -FOOTPRINT.y * 0.5)
	body.add_child(shape)
	station.add_child(body)
	_stations.append(station)

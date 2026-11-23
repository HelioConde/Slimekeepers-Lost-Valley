extends Node2D
## Casa do jogador (em qualquer lugar do mapa; cada região guarda a sua): desenha piso, paredes (com face) e telhado a partir
## de house_state com os tilesets PixelLab (dual-grid: cada tile usa os 4 cantos
## das células vizinhas), coloca a mobília e a colisão, e oferece o modo construir.
##
## Modo construir [B]: [Q] troca entre Casa e Mobília. Casa: arrastar com o botão
## esquerdo marca o retângulo (tamanho livre, custa mais quanto maior; só UMA casa no
## jogo); clique direito nela demole e devolve tudo. Mobília: roda escolhe o móvel,
## esquerdo coloca, direito tira. [B]/[Esc] fecha.

const HOUSE := preload("res://scripts/systems/house_state.gd")
## A casa desta região mudou (construída/demolida): área em pixels, vazia se não há.
signal footprint_changed(area: Rect2)
const CELL := 32
const LAYER_NAMES := {"house": "Casa", "furniture": "Mobília"}
const MODES := ["house", "furniture"]
const FURNITURE_ART := "res://assets/objects/furniture/%s.png"

var player: Node2D
var building := false
var mode := "house"
var furniture_choice := "cama"
var cursor_cell := Vector2i.ZERO
var message := ""
var problem := ""  # o que falta para colocar a última peça
## Região deste construtor: "floresta", "vale" ("fazenda" no mapa antigo).
var region_id := "fazenda"
var drag_start: Variant = null  # célula onde o arraste começou (modo Casa)
## Célula ocupada pelo mapa (árvore, pedra, água)? Vazio = tudo livre.
var blocked_world: Callable

var _atlas := {}
var _floor_layer: Node2D
var _roof_layer: Node2D
var _wall_rows: Node2D
var _furniture: Node2D
var _cursor: Node2D
var _body: StaticBody2D
var _roof_alpha := 1.0


func _ready() -> void:
	name = "PlayerHouse"
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for sheet in ["floor", "wall", "roof"]:
		_atlas[sheet] = {
			"texture": load("res://assets/tilesets/house/%s.png" % sheet),
			"tiles": JSON.parse_string(FileAccess.get_file_as_string("res://assets/tilesets/house/%s.json" % sheet)).tiles,
		}
	_floor_layer = _layer("Floor", -3, _draw_floor)
	_wall_rows = Node2D.new()
	_wall_rows.name = "Walls"
	_wall_rows.y_sort_enabled = true
	add_child(_wall_rows)
	_furniture = Node2D.new()
	_furniture.name = "Furniture"
	_furniture.y_sort_enabled = true
	add_child(_furniture)
	_roof_layer = _layer("Roof", 30, _draw_roof)
	_cursor = _layer("BuildCursor", 40, _draw_cursor)
	_body = StaticBody2D.new()
	_body.name = "HouseCollision"
	_body.collision_layer = 2
	add_child(_body)
	rebuild()


func _layer(layer_name: String, z: int, painter: Callable) -> Node2D:
	var node := Node2D.new()
	node.name = layer_name
	node.z_as_relative = false
	node.z_index = z
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.draw.connect(painter)
	add_child(node)
	return node


## A casa vista desta região (vazia se a casa do jogador estiver em outra).
func house() -> Dictionary:
	return HOUSE.view(get_tree(), region_id)


## Recria paredes, mobília e colisão a partir do estado.
func rebuild() -> void:
	_floor_layer.queue_redraw()
	_roof_layer.queue_redraw()
	for child in _wall_rows.get_children():
		child.queue_free()
	for child in _furniture.get_children():
		child.queue_free()
	for child in _body.get_children():
		child.queue_free()
	_build_wall_rows()
	_build_furniture()
	var rect: Rect2i = house().rect
	footprint_changed.emit(Rect2(Vector2(rect.position * CELL), Vector2(rect.size * CELL)))
	for cell in HOUSE.solid_cells_of(house()):
		_add_box(Rect2(Vector2(cell * CELL), Vector2(CELL, CELL)))


func _add_box(rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	_body.add_child(shape)


## Estado do canto (célula) para cada folha: m material, f face de parede, e vazio.
func corner_state(sheet: String, cell: Vector2i) -> String:
	var data := house()
	match sheet:
		"floor":
			# Sem piso sob a parede de cima (aparecia uma faixa clara por fora); nas
			# outras paredes o piso continua por baixo e não deixa vão de grama.
			var top_wall: bool = data.wall.has(cell) and not data.floor.has(cell + Vector2i(0, -1))
			return "m" if data.floor.has(cell) and not top_wall else "e"
		"roof":
			return "m" if data.floor.has(cell) else "e"
		"wall":
			if data.wall.has(cell): return "m"
			return "f" if data.wall.has(cell + Vector2i(0, -1)) else "e"
	return "e"


## Tile do dual-grid no vértice (x, y): cantos = células (x-1,y-1) (x,y-1) (x-1,y) (x,y).
func tile_rect(sheet: String, vertex: Vector2i) -> Rect2:
	var key := ",".join([corner_state(sheet, vertex + Vector2i(-1, -1)), corner_state(sheet, vertex + Vector2i(0, -1)),
		corner_state(sheet, vertex + Vector2i(-1, 0)), corner_state(sheet, vertex)])
	if key == "e,e,e,e":
		return Rect2()
	var tiles: Dictionary = _atlas[sheet].tiles
	if not tiles.has(key):
		key = _closest_key(tiles, key)
	var at: Array = tiles[key]
	return Rect2(at[0], at[1], CELL, CELL)


## Combinação sem tile próprio (a folha de parede tem 21 de 81): usa a mais parecida,
## priorizando os cantos de material.
static func _closest_key(tiles: Dictionary, key: String) -> String:
	var want := key.split(",")
	var best := ""
	var best_score := -1
	for candidate in tiles:
		var have: PackedStringArray = candidate.split(",")
		var score := 0
		for i in 4:
			if have[i] == want[i]: score += 3 if want[i] == "m" else 2
			elif (have[i] == "e") == (want[i] == "e"): score += 1
		if score > best_score:
			best_score = score
			best = candidate
	return best


func _vertices(sheet: String) -> Array[Vector2i]:
	var cells: Array = house().floor.keys() + house().wall.keys()
	var seen := {}
	var result: Array[Vector2i] = []
	# Um tile no vértice v toca as células v-1..v; cada célula afeta os vértices
	# cell..cell+1 (e +2 em Y, pela face da parede na célula de baixo).
	for cell in cells:
		for dy in 3:
			for dx in 2:
				var v: Vector2i = cell + Vector2i(dx, dy)
				if not seen.has(v):
					seen[v] = true
					result.append(v)
	return result


func _draw_tiles(target: Node2D, sheet: String, vertices: Array[Vector2i], tint: Color = Color.WHITE) -> void:
	var texture: Texture2D = _atlas[sheet].texture
	for vertex in vertices:
		var rect := tile_rect(sheet, vertex)
		if rect.size == Vector2.ZERO:
			continue
		target.draw_texture_rect_region(texture, Rect2(Vector2(vertex * CELL) - Vector2(CELL, CELL) * 0.5 - target.position, Vector2(CELL, CELL)), rect, tint)


func _draw_floor() -> void:
	_draw_tiles(_floor_layer, "floor", _vertices("floor"))


func _draw_roof() -> void:
	if _roof_alpha <= 0.01 or building and mode != "roof":
		return
	# Telhado um pouco acima (beiral), cobrindo as paredes.
	_roof_layer.position = Vector2(0, -20)
	_draw_tiles(_roof_layer, "roof", _vertices("roof"), Color(1, 1, 1, _roof_alpha))


## Paredes em fileiras ordenadas por Y: o jogador passa na frente/atrás corretamente.
func _build_wall_rows() -> void:
	var rows := {}
	for vertex in _vertices("wall"):
		if tile_rect("wall", vertex).size != Vector2.ZERO:
			if not rows.has(vertex.y): rows[vertex.y] = []
			rows[vertex.y].append(vertex)
	for row_y in rows:
		var row := Node2D.new()
		row.name = "WallRow_%d" % row_y
		# Base da fileira = fundo do tile; o jogador abaixo dela é desenhado na frente.
		row.position = Vector2(0, row_y * CELL + CELL * 0.5)
		var vertices: Array[Vector2i] = []
		vertices.assign(rows[row_y])
		row.draw.connect(func(): _draw_tiles(row, "wall", vertices))
		_wall_rows.add_child(row)


func _build_furniture() -> void:
	var furniture: Dictionary = house().furniture
	for origin in furniture:
		var id := str(furniture[origin])
		var info: Dictionary = HOUSE.FURNITURE.get(id, {})
		if info.is_empty():
			continue
		var rect := HOUSE.footprint(origin, id)
		var anchor := Node2D.new()
		anchor.name = "Furniture_%s_%d_%d" % [id, origin.x, origin.y]
		anchor.position = Vector2(rect.position * CELL) + Vector2(rect.size.x * CELL * 0.5, rect.size.y * CELL - 2)
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = load(FURNITURE_ART % info.art)
		sprite.centered = false
		var used := sprite.texture.get_image().get_used_rect()
		sprite.position = -Vector2(used.position.x + used.size.x * 0.5, used.end.y)
		anchor.add_child(sprite)
		if id == "tapete":
			anchor.z_as_relative = false
			anchor.z_index = -2  # no chão, embaixo de tudo
		_furniture.add_child(anchor)
		if info.solid:
			_add_box(Rect2(Vector2(rect.position * CELL) + Vector2(4, CELL * (rect.size.y - 1) + 8), Vector2(rect.size.x * CELL - 8, CELL - 10)))


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var inside := HOUSE.is_inside_of(house(), Vector2i((player.global_position / CELL).floor()))
	var goal := 0.0 if inside or building else 1.0
	var next := move_toward(_roof_alpha, goal, delta * 4.0)
	if next != _roof_alpha:
		_roof_alpha = next
		_roof_layer.queue_redraw()
	if building:
		cursor_cell = Vector2i((get_global_mouse_position() / CELL).floor())
		_cursor.queue_redraw()


func near_bed(actor: Node2D) -> bool:
	return near_furniture(actor, "cama")


## Ator ao lado de um móvel desta casa (cama: dormir; fogão: cozinhar).
func near_furniture(actor: Node2D, id: String) -> bool:
	var furniture: Dictionary = house().furniture
	for origin in furniture:
		if furniture[origin] == id:
			var rect := HOUSE.footprint(origin, id)  # Rect2i.get_center() arredonda: centro exato
			var center := (Vector2(rect.position) + Vector2(rect.size) * 0.5) * CELL
			if actor.global_position.distance_to(center) < 48:
				return true
	return false


func toggle_build() -> void:
	building = not building
	get_tree().set_meta("build_mode", building)
	if is_instance_valid(player):
		player.set_physics_process(not building)
	_cursor.queue_redraw()
	_roof_layer.queue_redraw()


func cycle_mode() -> void:
	mode = MODES[(MODES.find(mode) + 1) % MODES.size()]


func cycle_furniture(step: int) -> void:
	var order: Array = HOUSE.FURNITURE_ORDER
	furniture_choice = order[posmod(order.find(furniture_choice) + step, order.size())]


func blocked_cells() -> Array:
	return [Vector2i((player.global_position / CELL).floor())] if is_instance_valid(player) else []


func player_cell() -> Variant:
	return Vector2i((player.global_position / CELL).floor()) if is_instance_valid(player) else null


## Retângulo do arraste atual (ou só a célula do cursor).
func drag_area() -> Rect2i:
	return HOUSE.drag_rect(drag_start if drag_start != null else cursor_cell, cursor_cell)


## Constrói a casa no retângulo arrastado. "" = construiu.
func build_rect(rect: Rect2i) -> String:
	problem = HOUSE.build(get_tree(), region_id, rect, blocked_world, player_cell())
	if problem.is_empty():
		message = "Casa construída! Coloque a cama para poder dormir."
		rebuild()
	return problem


func demolish() -> bool:
	if HOUSE.region_of(get_tree()) != region_id: return false
	if not HOUSE.CHEST.is_empty(get_tree()):
		problem = "Esvazie o baú antes de demolir"
		return false
	if not HOUSE.demolish(get_tree()): return false
	problem = ""
	message = "Casa demolida; o material voltou para a bolsa."
	rebuild()
	return true


func place_at(cell: Vector2i) -> bool:
	if mode != "furniture": return false
	problem = "Construa a casa primeiro (Q: Casa)" if HOUSE.region_of(get_tree()) != region_id else 		HOUSE.place_furniture(get_tree(), cell, furniture_choice, blocked_cells())
	if problem.is_empty(): rebuild()
	return problem.is_empty()


func erase_at(cell: Vector2i) -> bool:
	if mode == "house":
		return house().floor.has(cell) and demolish()
	if HOUSE.furniture_at(get_tree(), cell) == "bau" and not HOUSE.CHEST.is_empty(get_tree()):
		problem = "Esvazie o baú antes de tirá-lo"
		return false
	var ok := HOUSE.region_of(get_tree()) == region_id and HOUSE.remove_furniture(get_tree(), cell)  # devolve o material
	if ok:
		problem = ""
		rebuild()
	return ok


func build_hint() -> String:
	var detail := ""
	if mode == "house":
		var rect := drag_area()
		detail = ": arraste para marcar  %d×%d = %s" % [rect.size.x, rect.size.y, HOUSE.cost_text(HOUSE.rect_cost(rect))]
		if HOUSE.exists(get_tree()): detail = ": " + HOUSE.build_problem(get_tree(), rect)
	else:
		var id: String = furniture_choice
		detail = ": %s (roda) = %s" % [HOUSE.FURNITURE[id].name, HOUSE.cost_text(HOUSE.FURNITURE_COSTS.get(id, {}))]
	var tail := ("   •   " + problem) if not problem.is_empty() else ""
	return "[Construir] %s%s%s   •   [Q] Casa/Mobília   •   [B] sair" % [LAYER_NAMES[mode], detail, tail]


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		if key.physical_keycode == KEY_B or (building and key.physical_keycode == KEY_ESCAPE):
			toggle_build()
			get_viewport().set_input_as_handled()
			return
		if building and key.physical_keycode == KEY_Q:
			cycle_mode()
			get_viewport().set_input_as_handled()
			return
	if not building:
		return
	var mouse := event as InputEventMouseButton
	if mouse and mouse.button_index == MOUSE_BUTTON_LEFT and mode == "house":
		# Arrastar: aperta numa ponta, solta na outra.
		if mouse.pressed:
			drag_start = cursor_cell
		elif drag_start != null:
			build_rect(drag_area())
			drag_start = null
		get_viewport().set_input_as_handled()
		return
	if mouse and mouse.pressed:
		match mouse.button_index:
			MOUSE_BUTTON_LEFT: place_at(cursor_cell)
			MOUSE_BUTTON_RIGHT: erase_at(cursor_cell)
			MOUSE_BUTTON_WHEEL_UP: cycle_furniture(-1)
			MOUSE_BUTTON_WHEEL_DOWN: cycle_furniture(1)
		get_viewport().set_input_as_handled()


func _draw_cursor() -> void:
	if not building:
		return
	var rect := Rect2(Vector2(cursor_cell * CELL), Vector2(CELL, CELL))
	if mode == "house":
		var area := drag_area()
		var ok := HOUSE.build_problem(get_tree(), area, blocked_world, player_cell()).is_empty()
		var shown := Rect2(Vector2(area.position * CELL), Vector2(area.size * CELL))
		_cursor.draw_rect(shown, Color(0.4, 1, 0.5, 0.18) if ok else Color(1, 0.35, 0.3, 0.18))
		_cursor.draw_rect(shown, Color(0.5, 1, 0.6, 0.95) if ok else Color(1, 0.45, 0.4, 0.95), false, 2.0)
		return
	if mode == "furniture":
		rect.size = Vector2(HOUSE.FURNITURE[furniture_choice].size * CELL)
		var art: Texture2D = load(FURNITURE_ART % HOUSE.FURNITURE[furniture_choice].art)
		var used := art.get_image().get_used_rect()
		var foot := rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2)
		_cursor.draw_texture(art, foot - Vector2(used.position.x + used.size.x * 0.5, used.end.y), Color(1, 1, 1, 0.6))
	_cursor.draw_rect(rect, Color(1, 0.95, 0.6, 0.9), false, 2.0)

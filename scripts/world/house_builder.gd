extends Node2D
## Casa do jogador na fazenda: desenha piso, paredes (com face) e telhado a partir
## de house_state com os tilesets PixelLab (dual-grid: cada tile usa os 4 cantos
## das células vizinhas), coloca a mobília e a colisão, e oferece o modo construir.
##
## Modo construir [B]: [Q] troca a camada (Piso, Parede, Mobília), roda do mouse
## escolhe o móvel, clique esquerdo coloca, direito remove, [B]/[Esc] fecha.

const HOUSE := preload("res://scripts/systems/house_state.gd")
const CELL := 32
const LAYER_NAMES := {"floor": "Piso", "wall": "Parede", "furniture": "Mobília"}
const MODES := ["floor", "wall", "furniture"]
const FURNITURE_ART := "res://assets/objects/furniture/%s.png"

var player: Node2D
var building := false
var mode := "wall"
var furniture_choice := "cama"
var cursor_cell := Vector2i.ZERO
var message := ""

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


func house() -> Dictionary:
	return HOUSE.data(get_tree())


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
	for cell in HOUSE.solid_cells(get_tree()):
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
		"floor", "roof":
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
	var inside := HOUSE.is_inside(get_tree(), Vector2i((player.global_position / CELL).floor()))
	var goal := 0.0 if inside or building else 1.0
	var next := move_toward(_roof_alpha, goal, delta * 4.0)
	if next != _roof_alpha:
		_roof_alpha = next
		_roof_layer.queue_redraw()
	if building:
		cursor_cell = Vector2i((get_global_mouse_position() / CELL).floor())
		_cursor.queue_redraw()


func near_bed(actor: Node2D) -> bool:
	var furniture: Dictionary = house().furniture
	for origin in furniture:
		if furniture[origin] == "cama":
			var center := Vector2(HOUSE.footprint(origin, "cama").get_center() * CELL)
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


func place_at(cell: Vector2i) -> bool:
	var ok := HOUSE.place(get_tree(), mode, cell, furniture_choice, blocked_cells())
	if ok: rebuild()
	return ok


func erase_at(cell: Vector2i) -> bool:
	var ok := HOUSE.erase(get_tree(), mode, cell)
	if ok: rebuild()
	return ok


func build_hint() -> String:
	var choice := ("  •  " + str(HOUSE.FURNITURE[furniture_choice].name) + " (roda)") if mode == "furniture" else ""
	return "[Construir] %s%s   •   [Q] camada   •   clique: colocar / direito: tirar   •   [B] sair" % [LAYER_NAMES[mode], choice]


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
	if mode == "furniture":
		rect.size = Vector2(HOUSE.FURNITURE[furniture_choice].size * CELL)
		var art: Texture2D = load(FURNITURE_ART % HOUSE.FURNITURE[furniture_choice].art)
		var used := art.get_image().get_used_rect()
		var foot := rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2)
		_cursor.draw_texture(art, foot - Vector2(used.position.x + used.size.x * 0.5, used.end.y), Color(1, 1, 1, 0.6))
	_cursor.draw_rect(rect, Color(1, 0.95, 0.6, 0.9), false, 2.0)

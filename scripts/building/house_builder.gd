extends Node2D
## Casa automatica: somente o piso e editavel. Contorno, janelas,
## porta e telhado sao sempre derivados dos pisos conectados.
## Inspirado no gerador de contorno de Slime-Harvest.
const Scales = preload("res://scripts/world_object_scales.gd")
const SAVE_FILE: String = "user://slv_house_clearing_v1.json"
const TILE: int = 32
const INVALID: Vector2i = Vector2i(99999, 99999)
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const TILE_PREFIX: Array[String] = [
	"house_floor_wood_seamless", "house_wall_wood_detailed",
	"house_roof_red_tiles", "house_door_wood_detailed",
	"house_window_wood_detailed"
]
const FALLBACK: Array[Color] = [
	Color("#a57449"), Color("#d7c09a"), Color("#ae5945"),
	Color("#784b2f"), Color("#6c9fa1")
]
@export_range(2, 64, 1) var max_spawn_distance_tiles: int = 25
@export_range(1, 3, 1) var player_build_clearance_tiles: int = 1
@export var freeze_player_during_build: bool = true
@export_range(0.1, 1.0, 0.05) var roof_opacity_in_build: float = 0.45

@onready var player: CharacterBody2D = $"../WorldObjects/Player"
@onready var ground: TileMapLayer = $"../Ground"
@onready var inventory: Node = $"../Inventory"
@onready var world: Node2D = $"../WorldObjects"

var floor_layer: TileMapLayer
var wall_layer: TileMapLayer
var roof_layer: TileMapLayer
var front_layer: TileMapLayer
var openings_layer: TileMapLayer
var collisions: Node2D
var preview: Sprite2D
var status_label: Label
var floors: Dictionary = {}
var walls: Dictionary = {}
var roofs: Dictionary = {}
var doors: Dictionary = {}
var windows: Dictionary = {}
var history: Array[Dictionary] = []
var building: bool = false
var roof_hidden: bool = false
var anchor_cell: Vector2i = INVALID
var spawn_cell: Vector2i = Vector2i.ZERO
var door_cell: Vector2i = INVALID
var cursor_cell: Vector2i = INVALID
var _last_cell: Vector2i = INVALID
var _last_status: String = ""
var _textures: Array[Texture2D] = []
var _paint_button: int = 0
var _previous_drag_cell: Vector2i = INVALID


func _ready() -> void:
	add_to_group("slv_house_builder")
	spawn_cell = _player_cell()
	_build_tileset_and_layers()
	_create_hud()
	_rebuild()
	# O pai pinta o terreno na inicializacao. Carregar no quadro seguinte.
	call_deferred("_load_house")


func is_building() -> bool:
	return building


func is_world_point_protected(world_point: Vector2, margin_tiles: int = 2) -> bool:
	var cell: Vector2i = _to_cell(world_point)
	for key in floors:
		var existing: Vector2i = key
		if maxi(absi(cell.x - existing.x), absi(cell.y - existing.y)) <= margin_tiles:
			return true
	return false


func _build_tileset_and_layers() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	for i in range(TILE_PREFIX.size()):
		var tex: Texture2D = _load_tile_texture(TILE_PREFIX[i], FALLBACK[i])
		_textures.append(tex)
		var atlas := TileSetAtlasSource.new()
		atlas.texture = tex
		atlas.texture_region_size = Vector2i(TILE, TILE)
		atlas.create_tile(Vector2i.ZERO)
		tiles.add_source(atlas, i)
	floor_layer = _make_layer("InteriorFloor", -6, tiles)
	wall_layer = _make_layer("AutomaticWalls", 7, tiles)
	openings_layer = _make_layer("AutomaticDoorsAndWindows", 8, tiles)
	roof_layer = _make_layer("AutomaticRoof", 20, tiles)
	front_layer = _make_layer("AutomaticFrontFacade", 21, tiles)
	collisions = Node2D.new()
	collisions.name = "GeneratedWallCollisions"
	add_child(collisions)
	preview = Sprite2D.new()
	preview.name = "FloorGhost"
	preview.texture = _textures[0]
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.z_index = 30
	preview.hide()
	add_child(preview)


func _make_layer(label: String, z: int, tiles: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = label
	layer.tile_set = tiles
	layer.z_index = z
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(layer)
	return layer


func _load_tile_texture(prefix: String, fallback_color: Color) -> Texture2D:
	var dirs: PackedStringArray = DirAccess.get_directories_at(Scales.ROOT)
	dirs.sort()
	for folder in dirs:
		if not folder.begins_with(prefix):
			continue
		var texture: Texture2D = Scales.preview_texture(Scales.ROOT.path_join(folder))
		if texture == null:
			continue
		var original: Image = texture.get_image()
		if original == null or original.is_empty() or original.get_used_rect().size.x < 7:
			continue
		var scaled: Image = original.duplicate() as Image
		scaled.convert(Image.FORMAT_RGBA8)
		scaled.resize(TILE, TILE, Image.INTERPOLATE_NEAREST)
		return ImageTexture.create_from_image(scaled)
	push_error("Modulo real PixelLab ausente: " + prefix)
	var transparent_image: Image = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	transparent_image.fill(Color.TRANSPARENT)
	return ImageTexture.create_from_image(transparent_image)


func _create_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "BuildModeHUD"
	hud.layer = 28
	add_child(hud)
	var panel := PanelContainer.new()
	panel.offset_left = 14
	panel.offset_top = 76
	panel.offset_right = 505
	panel.offset_bottom = 189
	hud.add_child(panel)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(status_label)
	hud.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.physical_keycode == KEY_B:
			_toggle_build()
		elif building and key.physical_keycode == KEY_ESCAPE:
			_toggle_build()
		elif not building:
			return
		elif key.ctrl_pressed and key.physical_keycode == KEY_Z:
			_undo()
		elif key.ctrl_pressed and key.physical_keycode == KEY_S:
			_save_house()
		elif key.ctrl_pressed and key.physical_keycode == KEY_L:
			_load_house()
		elif key.physical_keycode == KEY_R:
			roof_hidden = not roof_hidden
			_set_status("Telhado visivel" if not roof_hidden else "Telhado oculto")
		else:
			return
		get_viewport().set_input_as_handled()
	elif building and event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
			return
		if mb.pressed:
			_paint_button = mb.button_index
			_previous_drag_cell = INVALID
			_paint_at_cursor()
		else:
			_paint_button = 0
		get_viewport().set_input_as_handled()


func _toggle_build() -> void:
	building = not building
	_paint_button = 0
	_previous_drag_cell = INVALID
	cursor_cell = INVALID
	if freeze_player_during_build:
		player.set_movement_locked(building)
	preview.visible = building
	get_node("BuildModeHUD").visible = building
	# A barra 1-4 do inventario nao faz parte do editor da casa.
	var hotbar: Control = get_node_or_null("../HUD/MiniHUDRoot/BarraDeFerramentas") as Control
	if hotbar != null:
		hotbar.visible = not building
	_set_status("Desenhe SOMENTE o piso. A casa se monta sozinha!")
	_update_roof_visibility()
	queue_redraw()


func _process(_delta: float) -> void:
	_update_roof_visibility()
	if not building:
		return
	if _paint_button != 0 and not Input.is_mouse_button_pressed(_paint_button):
		_paint_button = 0
		_previous_drag_cell = INVALID
	cursor_cell = _to_cell(get_global_mouse_position())
	preview.position = _cell_world(cursor_cell)
	var error: String = _reason(cursor_cell, true)
	preview.modulate = Color(0.55, 1.0, 0.55, 0.52) if error.is_empty() else Color(1, 0.28, 0.28, 0.52)
	if cursor_cell != _last_cell:
		_last_cell = cursor_cell
		_update_hud(error)
		queue_redraw()
	if _paint_button != 0 and get_viewport().get_mouse_position().y < get_viewport_rect().size.y - 90.0:
		_paint_at_cursor()


func _draw() -> void:
	if not building or cursor_cell == INVALID:
		return
	var center: Vector2 = _cell_world(cursor_cell)
	var rect := Rect2(center - Vector2(16, 16), Vector2(TILE, TILE))
	draw_rect(rect, Color("#6cd882") if _reason(cursor_cell, true).is_empty() else Color("#e35b5b"), false, 2)


func _paint_at_cursor() -> void:
	var cell: Vector2i = _to_cell(get_global_mouse_position())
	if cell == _previous_drag_cell:
		return
	_previous_drag_cell = cell
	_apply_floor(cell, _paint_button == MOUSE_BUTTON_LEFT)


func _to_cell(point: Vector2) -> Vector2i:
	return ground.local_to_map(ground.to_local(point))


func _cell_world(cell: Vector2i) -> Vector2:
	return ground.to_global(ground.map_to_local(cell))


func _player_cell() -> Vector2i:
	return _to_cell(player.global_position)


func _wall_ring(footprint: Dictionary) -> Dictionary:
	var ring: Dictionary = {}
	for key in footprint:
		var floor_cell: Vector2i = key
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var outside: Vector2i = floor_cell + Vector2i(dx, dy)
				if not footprint.has(outside):
					ring[outside] = true
	return ring


func _reason(cell: Vector2i, placing: bool) -> String:
	if cell == INVALID:
		return "Posicao invalida"
	if placing and floors.has(cell):
		return "Piso existente"
	if not placing:
		if not floors.has(cell):
			return "Nao ha piso aqui"
		if cell == anchor_cell:
			return "Nao e permitido apagar a ancora da casa inicial"
		var reduced: Dictionary = floors.duplicate()
		reduced.erase(cell)
		if not _connected(reduced):
			return "Os pisos precisam permanecer conectados"
		return ""
	if ground.get_cell_source_id(cell) < 0:
		return "Fora do terreno"
	var world_position: Vector2 = _cell_world(cell)
	var spawn_position: Vector2 = _cell_world(spawn_cell)
	if world_position.distance_to(spawn_position) > float(max_spawn_distance_tiles * TILE):
		return "Distancia maior que %d blocos do spawn" % max_spawn_distance_tiles
	var proposed: Dictionary = floors.duplicate()
	proposed[cell] = true
	if floors.size() > 0 and not _adjacent_to_floor(cell):
		return "Construa junto ao piso existente"
	# Verifique tambem a borda e as paredes criadas automaticamente.
	var generated_walls: Dictionary = _wall_ring(proposed)
	for key in proposed:
		var filled: Vector2i = key
		if not floors.has(filled):
			if not _clear_for_player(filled):
				return "Afaste o jogador do novo piso"
	for key in generated_walls:
		var outside: Vector2i = key
		if not walls.has(outside) and not _clear_for_player(outside):
			return "Afaste o jogador das novas paredes"
	for key in generated_walls:
		var outside: Vector2i = key
		if ground.get_cell_source_id(outside) < 0:
			return "Deixe uma margem para paredes e telhado"
		if not walls.has(outside) and _outside_blocked(_cell_world(outside)):
			return "Sem espaco para paredes ao redor"
	if _outside_blocked(world_position):
		return "Limpe a area antes de construir"
	return ""


func _clear_for_player(cell: Vector2i) -> bool:
	var delta: Vector2i = cell - _player_cell()
	return maxi(absi(delta.x), absi(delta.y)) > player_build_clearance_tiles


func _outside_blocked(point: Vector2) -> bool:
	var main: Node = get_parent()
	if main.has_method("_inside_water") and bool(main.call("_inside_water", point, 1.1)):
		return true
	if main.has_method("_is_road") and bool(main.call("_is_road", point)):
		return true
	if point.x > 685.0 and point.y < -320.0:
		return true
	for candidate in world.get_children():
		if candidate == player or not candidate is Node2D:
			continue
		var item: Node2D = candidate as Node2D
		if point.distance_to(item.global_position) > 20.0:
			continue
		if item.name.begins_with("Tree_") or item.name.begins_with("rock_") or item.name.begins_with("fruit_tree_"):
			return true
	return false


func _adjacent_to_floor(cell: Vector2i) -> bool:
	for direction in DIRS:
		if floors.has(cell + direction):
			return true
	return false


func _connected(cells: Dictionary) -> bool:
	if cells.size() <= 1:
		return true
	var origin: Vector2i = cells.keys()[0]
	var visited: Dictionary = {origin: true}
	var queue: Array[Vector2i] = [origin]
	var index: int = 0
	while index < queue.size():
		var cell: Vector2i = queue[index]
		index += 1
		for direction in DIRS:
			var near: Vector2i = cell + direction
			if cells.has(near) and not visited.has(near):
				visited[near] = true
				queue.append(near)
	return visited.size() == cells.size()


func _apply_floor(cell: Vector2i, placing: bool) -> void:
	var error: String = _reason(cell, placing)
	if not error.is_empty():
		if error != "Piso existente" and error != "Nao ha piso aqui":
			_set_status(error)
		return
	if placing and int(inventory.call("quantity", "madeira")) < 1:
		_set_status("Sem madeira. Colete com o machado.")
		return
	_remember()
	if placing:
		inventory.call("take_item", "madeira", 1)
		if floors.is_empty():
			anchor_cell = cell
		floors[cell] = true
	else:
		floors.erase(cell)
		inventory.call("add_item", "madeira", 1)
	_rebuild()
	_set_status("Piso atualizado - estrutura gerada automaticamente")


func _choose_door() -> Vector2i:
	if floors.is_empty():
		return INVALID
	var bottom: int = -2147483647
	var sum_x: float = 0.0
	for key in floors:
		var p: Vector2i = key
		bottom = maxi(bottom, p.y)
		sum_x += float(p.x)
	var mean_x: float = sum_x / float(floors.size())
	var best: Vector2i = INVALID
	var best_distance: float = INF
	for key in floors:
		var p: Vector2i = key
		if p.y != bottom:
			continue
		var distance: float = absf(float(p.x) - mean_x)
		if distance < best_distance:
			best_distance = distance
			best = p + Vector2i.DOWN
	return best


func _window_candidates() -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for key in walls:
		var cell: Vector2i = key
		if cell == door_cell:
			continue
		var front_wall: bool = floors.has(cell + Vector2i.UP)
		var rear_wall: bool = floors.has(cell + Vector2i.DOWN)
		var west_wall: bool = floors.has(cell + Vector2i.RIGHT)
		var east_wall: bool = floors.has(cell + Vector2i.LEFT)
		var in_row: bool = walls.has(cell + Vector2i.LEFT) and walls.has(cell + Vector2i.RIGHT)
		var in_col: bool = walls.has(cell + Vector2i.UP) and walls.has(cell + Vector2i.DOWN)
		if ((front_wall or rear_wall) and in_row) or ((west_wall or east_wall) and in_col):
			candidates.append(cell)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	return candidates


func _recalculate_structure() -> void:
	walls = _wall_ring(floors)
	doors.clear()
	windows.clear()
	roofs = floors.duplicate()
	if floors.is_empty():
		door_cell = INVALID
		return
	door_cell = _choose_door()
	walls.erase(door_cell)
	doors[door_cell] = true
	# O telhado cobre o piso, o contorno e o vao da entrada.
	for key in walls:
		roofs[key] = true
	roofs[door_cell] = true
	var possible: Array[Vector2i] = _window_candidates()
	# Sem janelas consecutivas, posicionadas sem qualquer pincel manual.
	var gap: Dictionary = {}
	for candidate in possible:
		var too_close: bool = false
		for direction in DIRS:
			if gap.has(candidate + direction):
				too_close = true
				break
		if not too_close and candidate.distance_to(door_cell) > 1.5:
			windows[candidate] = true
			gap[candidate] = true
	# Evitar que uma casa curta fique sem janelas.
	if windows.is_empty() and not possible.is_empty():
		windows[possible[0]] = true


func _rebuild() -> void:
	if floor_layer == null:
		return
	_recalculate_structure()
	floor_layer.clear()
	wall_layer.clear()
	openings_layer.clear()
	roof_layer.clear()
	front_layer.clear()
	for key in floors:
		var cell: Vector2i = key
		floor_layer.set_cell(cell, 0, Vector2i.ZERO)
	for key in walls:
		var cell: Vector2i = key
		wall_layer.set_cell(cell, 1, Vector2i.ZERO)
	for key in roofs:
		var cell: Vector2i = key
		roof_layer.set_cell(cell, 2, Vector2i.ZERO)
	for key in windows:
		var cell: Vector2i = key
		openings_layer.set_cell(cell, 4, Vector2i.ZERO)
	for key in doors:
		var cell: Vector2i = key
		openings_layer.set_cell(cell, 3, Vector2i.ZERO)
	# Reexibe a fachada sul na frente da cobertura: a porta e as
	# janelas nao ficam escondidas atras dos tiles do telhado.
	for key in walls:
		var cell: Vector2i = key
		if floors.has(cell + Vector2i.UP):
			front_layer.set_cell(cell, 4 if windows.has(cell) else 1, Vector2i.ZERO)
	for key in doors:
		var cell: Vector2i = key
		front_layer.set_cell(cell, 3, Vector2i.ZERO)
	_rebuild_wall_collisions()
	_update_roof_visibility()


func _rebuild_wall_collisions() -> void:
	for existing in collisions.get_children():
		# Desliga antes de remover para evitar colisao fantasma no frame.
		if existing is CollisionObject2D:
			(existing as CollisionObject2D).collision_layer = 0
		existing.queue_free()
	for key in walls:
		var cell: Vector2i = key
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = _cell_world(cell)
		collisions.add_child(body)
		var shape := RectangleShape2D.new()
		shape.size = Vector2(30, 30)
		var hitbox := CollisionShape2D.new()
		hitbox.shape = shape
		body.add_child(hitbox)


func _update_roof_visibility() -> void:
	if roof_layer == null:
		return
	var player_inside: bool = floors.has(_player_cell())
	roof_layer.visible = not roof_hidden and (building or not player_inside)
	roof_layer.modulate.a = roof_opacity_in_build if building else 1.0


func _remember() -> void:
	var counts: Dictionary = inventory.get("counts")
	history.append({"floor": floors.duplicate(), "anchor": anchor_cell, "items": counts.duplicate()})
	if history.size() > 40:
		history.pop_front()


func _undo() -> void:
	if history.is_empty():
		_set_status("Nao ha acoes para desfazer")
		return
	var data: Dictionary = history.pop_back()
	floors = data.get("floor", {}).duplicate()
	anchor_cell = data.get("anchor", INVALID)
	inventory.set("counts", data.get("items", {}).duplicate())
	inventory.emit_signal("inventory_changed")
	_rebuild()
	_set_status("Desfeito: casa e materiais restaurados")


func _cells_to_json(cells: Dictionary) -> Array:
	var output: Array = []
	for key in cells:
		var cell: Vector2i = key
		output.append([cell.x, cell.y])
	return output


func _cells_from_json(raw: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not raw is Array:
		return result
	for point in raw:
		if point is Array and point.size() == 2:
			var cell := Vector2i(int(point[0]), int(point[1]))
			if ground.get_cell_source_id(cell) >= 0:
				result[cell] = true
	return result


func _save_house() -> void:
	var data: Dictionary = {
		"version": 2, "floor": _cells_to_json(floors),
		"anchor": [anchor_cell.x, anchor_cell.y],
		"items": inventory.get("counts")
	}
	var file: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		_set_status("Falha ao salvar a casa")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_set_status("Casa e materiais salvos")


func _load_house() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var file: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		_set_status("Falha ao ler o salvamento")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_set_status("Salvamento invalido")
		return
	var data: Dictionary = parsed
	if int(data.get("version", -1)) not in [1, 2]:
		_set_status("Versao de save incompativel")
		return
	var loaded: Dictionary = _cells_from_json(data.get("floor", []))
	if not _connected(loaded):
		_set_status("Casa salva nao esta conectada")
		return
	floors = loaded
	var saved_anchor: Variant = data.get("anchor", [])
	if saved_anchor is Array and saved_anchor.size() == 2:
		anchor_cell = Vector2i(int(saved_anchor[0]), int(saved_anchor[1]))
	else:
		anchor_cell = INVALID
	if not floors.is_empty() and not floors.has(anchor_cell):
		anchor_cell = floors.keys()[0]
	if floors.is_empty():
		anchor_cell = INVALID
	var saved_items: Variant = data.get("items", {})
	if saved_items is Dictionary:
		var amounts: Dictionary = inventory.get("counts").duplicate()
		for id in amounts:
			if saved_items.has(id):
				amounts[id] = clampi(int(saved_items[id]), 0, 99)
		inventory.set("counts", amounts)
		inventory.emit_signal("inventory_changed")
	history.clear()
	# Save v1 guarda paredes/telhados manuais. Agora piso e fonte unica:
	# regeneramos os demais elementos independentemente do save antigo.
	_rebuild()
	_set_status("Casa carregada; estruturas regeneradas automaticamente")


func _set_status(message: String) -> void:
	_last_status = message
	_update_hud()


func _update_hud(reason: String = "") -> void:
	if status_label == null:
		return
	var info: String = "CASA AUTOMATICA  [B]  -  desenhe apenas o PISO\n"
	info += "Clique esquerdo: desenhar | Direito: apagar | Arraste para ampliar\n"
	info += "Ctrl+Z desfazer | Ctrl+S salvar | Ctrl+L carregar | R telhado\n"
	info += "Madeira: %d | 1 madeira / piso | %d pisos\n" % [int(inventory.call("quantity", "madeira")), floors.size()]
	info += reason if not reason.is_empty() else _last_status
	status_label.text = info

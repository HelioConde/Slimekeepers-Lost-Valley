extends Node2D
## Construção em camadas inspirada no HouseBuilder de Slime-Harvest.
## Grade 32x32: pisos independentes, paredes, telhados, porta e save.
## Os tiles são montados em memória a partir dos PNGs PixelLab do projeto.

const Scales = preload("res://scripts/world_object_scales.gd")
const SAVE_FILE: String = "user://slv_house_clearing_v1.json"
const TILE: int = 32
const INVALID_CELL: Vector2i = Vector2i(99999, 99999)
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const BRUSHES: Array[String] = ["Piso", "Parede", "Telhado", "Porta"]
const PREFIXES: Array[String] = [
	"house_floor_wood_seamless", "house_wall_wood_detailed",
	"house_roof_red_tiles", "house_door_wood_detailed"
]
const FALLBACK_COLORS: Array[Color] = [
	Color("#a57449"), Color("#d7c09a"), Color("#ae5945"), Color("#784b2f")
]
const FIRST_CELL_MAX_RANGE: float = 25.0

@export_range(2, 64, 1) var max_spawn_distance_tiles: int = 25
@export_range(1, 3, 1) var player_build_clearance_tiles: int = 1
@export var freeze_player_during_build: bool = true
@export var roof_opacity_in_build: float = 0.52

@onready var player: CharacterBody2D = $"../WorldObjects/Player"
@onready var ground: TileMapLayer = $"../Ground"
@onready var inventory: Node = $"../Inventory"
@onready var world: Node2D = $"../WorldObjects"

var floor_layer: TileMapLayer
var wall_layer: TileMapLayer
var roof_layer: TileMapLayer
var door_layer: TileMapLayer
var collisions: Node2D
var preview: Sprite2D
var status_label: Label
var floors: Dictionary = {}
var walls: Dictionary = {}
var roofs: Dictionary = {}
var doors: Dictionary = {}
var history: Array[Dictionary] = []
var brush_index: int = 0
var building: bool = false
var hide_roof_manually: bool = false
var anchor_cell: Vector2i = INVALID_CELL
var spawn_cell: Vector2i = Vector2i.ZERO
var cursor_cell: Vector2i = INVALID_CELL
var tile_textures: Array[Texture2D] = []
var _last_status: String = ""
var _last_cell: Vector2i = INVALID_CELL


func _ready() -> void:
	add_to_group("slv_house_builder")
	spawn_cell = _player_cell()
	_build_tileset_and_layers()
	_make_panel()
	_update_rendering()
	# O terreno e pintado em _ready do pai: carregue depois da geracao do mapa.
	call_deferred("_load_house")
	set_process(true)


func is_building() -> bool:
	return building


func is_world_point_protected(point: Vector2, margin_tiles: int = 2) -> bool:
	if floors.is_empty():
		return false
	var cell: Vector2i = _to_cell(point)
	var radius: int = maxi(0, margin_tiles)
	for key in floors:
		var existing: Vector2i = key
		if absi(existing.x - cell.x) <= radius and absi(existing.y - cell.y) <= radius:
			return true
	return false


func _build_tileset_and_layers() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	for i in range(BRUSHES.size()):
		var texture: Texture2D = _find_modular_texture(PREFIXES[i], FALLBACK_COLORS[i])
		tile_textures.append(texture)
		var source := TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(TILE, TILE)
		source.create_tile(Vector2i.ZERO)
		tiles.add_source(source, i)
	floor_layer = _make_layer("InteriorFloor", -6, tiles)
	wall_layer = _make_layer("HouseWalls", 7, tiles)
	door_layer = _make_layer("HouseDoors", 8, tiles)
	roof_layer = _make_layer("HouseRoof", 20, tiles)
	collisions = Node2D.new()
	collisions.name = "HouseWallCollisions"
	add_child(collisions)
	preview = Sprite2D.new()
	preview.name = "BuildPreview"
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.z_index = 30
	preview.visible = false
	add_child(preview)


func _make_layer(title: String, depth: int, tiles: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = title
	layer.tile_set = tiles
	layer.z_index = depth
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(layer)
	return layer


func _find_modular_texture(prefix: String, fallback: Color) -> Texture2D:
	var dirs: PackedStringArray = DirAccess.get_directories_at(Scales.ROOT)
	dirs.sort()
	for name in dirs:
		if not name.begins_with(prefix):
			continue
		var full: String = Scales.ROOT.path_join(name)
		var original: Texture2D = Scales.preview_texture(full)
		if original == null:
			continue
		var image: Image = original.get_image()
		if image == null or image.is_empty():
			continue
		var used: Rect2i = image.get_used_rect()
		if used.size.x < 7 or used.size.y < 7:
			continue
		# Exportacoes PixelLab vieram em celulas 48x48; unifica em 32x32,
		# sem alterar seus PNGs no disco.
		var converted: Image = image.duplicate() as Image
		converted.convert(Image.FORMAT_RGBA8)
		converted.resize(TILE, TILE, Image.INTERPOLATE_NEAREST)
		return ImageTexture.create_from_image(converted)
	push_warning("Construtor sem PNG PixelLab '%s'; usando bloco de teste." % prefix)
	var placeholder: Image = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	placeholder.fill(fallback)
	for k in range(TILE):
		placeholder.set_pixel(k, 0, fallback.lightened(0.22))
		placeholder.set_pixel(k, TILE - 1, fallback.darkened(0.25))
	return ImageTexture.create_from_image(placeholder)


func _make_panel() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "BuildModeHUD"
	canvas.layer = 28
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.name = "Instructions"
	panel.offset_left = 14.0
	panel.offset_top = 76.0
	panel.offset_right = 498.0
	panel.offset_bottom = 214.0
	canvas.add_child(panel)
	var label := Label.new()
	label.name = "Status"
	label.add_theme_font_size_override("font_size", 13)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	status_label = label
	canvas.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if not k.pressed or k.echo:
			return
		if k.physical_keycode == KEY_B:
			_toggle_mode()
		elif building and (k.physical_keycode == KEY_ESCAPE):
			_toggle_mode()
		elif not building:
			return
		elif k.ctrl_pressed and k.physical_keycode == KEY_Z:
			_undo()
		elif k.ctrl_pressed and k.physical_keycode == KEY_S:
			_save_house()
		elif k.ctrl_pressed and k.physical_keycode == KEY_L:
			_load_house()
		elif k.physical_keycode == KEY_R:
			hide_roof_manually = not hide_roof_manually
			_set_status("Telhado alternado.")
		elif k.physical_keycode >= KEY_1 and k.physical_keycode <= KEY_4:
			brush_index = k.physical_keycode - KEY_1
			_last_cell = INVALID_CELL
			_set_status("Pincel: " + BRUSHES[brush_index])
		else:
			return
		get_viewport().set_input_as_handled()
	elif building and event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if not mouse.pressed:
			return
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_apply_cell(_mouse_cell(), true)
			get_viewport().set_input_as_handled()
		elif mouse.button_index == MOUSE_BUTTON_RIGHT:
			_apply_cell(_mouse_cell(), false)
			get_viewport().set_input_as_handled()


func _toggle_mode() -> void:
	building = not building
	if freeze_player_during_build:
		player.call("set_movement_locked", building)
	if building:
		brush_index = 0
		_set_status("Modo construcao ativado")
	else:
		_set_status("Construcao encerrada; Ctrl+S salva enquanto edita")
	preview.visible = building
	_update_rendering()
	get_node("BuildModeHUD").visible = building
	_last_cell = INVALID_CELL
	queue_redraw()


func _process(_delta: float) -> void:
	_update_roof_visibility()
	if not building:
		return
	cursor_cell = _mouse_cell()
	preview.position = _cell_center(cursor_cell)
	preview.texture = tile_textures[brush_index]
	var reason: String = _valid_reason(cursor_cell, true)
	preview.modulate = Color(0.55, 1.0, 0.65, 0.65) if reason.is_empty() else Color(1.0, 0.32, 0.32, 0.62)
	if cursor_cell != _last_cell:
		_last_cell = cursor_cell
		_refresh_panel(reason)
		queue_redraw()


func _draw() -> void:
	if not building or cursor_cell == INVALID_CELL:
		return
	var top_left: Vector2 = Vector2(cursor_cell * TILE) - Vector2(TILE * 0.5, TILE * 0.5)
	var rect := Rect2(top_left, Vector2.ONE * float(TILE))
	var valid: bool = _valid_reason(cursor_cell, true).is_empty()
	draw_rect(rect, Color("#5ad782") if valid else Color("#ee6060"), false, 2.0)
	for n in range(-1, 2):
		var side: Vector2 = Vector2(cursor_cell + Vector2i(n, -1)) * float(TILE)
		draw_rect(Rect2(side - Vector2.ONE * 16.0, Vector2.ONE * float(TILE)), Color(1, 1, 1, 0.08), false, 1.0)


func _mouse_cell() -> Vector2i:
	return _to_cell(get_global_mouse_position())


func _to_cell(point: Vector2) -> Vector2i:
	return ground.local_to_map(ground.to_local(point))


func _cell_center(cell: Vector2i) -> Vector2:
	return ground.to_global(ground.map_to_local(cell))


func _player_cell() -> Vector2i:
	return _to_cell(player.global_position)


func _layer_set() -> Dictionary:
	match brush_index:
		0: return floors
		1: return walls
		2: return roofs
		3: return doors
	return floors


func _valid_reason(cell: Vector2i, adding: bool) -> String:
	if cell == INVALID_CELL:
		return "Posicao invalida"
	var current: Dictionary = _layer_set()
	if adding and current.has(cell):
		return "Ja existe este bloco"
	if not adding and not current.has(cell):
		return "Nenhum bloco desta camada aqui"
	if not adding:
		if brush_index == 0:
			if cell == anchor_cell:
				return "A casa inicial nao pode perder a ancora"
			var remainder: Dictionary = floors.duplicate()
			remainder.erase(cell)
			if not _connected(remainder):
				return "O piso precisa continuar conectado"
		return ""
	if ground.get_cell_source_id(cell) < 0:
		return "Fora do terreno editavel"
	var point: Vector2 = _cell_center(cell)
	var max_distance: float = float(max_spawn_distance_tiles * TILE)
	if point.distance_to(_cell_center(spawn_cell)) > max_distance:
		return "Construa perto do ponto inicial (25 blocos)"
	var player_offset: Vector2i = cell - _player_cell()
	var clearance: int = maxi(1, player_build_clearance_tiles)
	if absi(player_offset.x) <= clearance and absi(player_offset.y) <= clearance:
		return "Muito perto do personagem"
	if brush_index == 0:
		var scene: Node = get_parent()
		if scene.has_method("_inside_water") and bool(scene.call("_inside_water", point, 1.12)):
			return "Nao e possivel construir dentro da lagoa"
		if point.x > 685.0 and point.y < -320.0:
			return "Nao construa sobre a encosta"
		if scene.has_method("_is_road") and bool(scene.call("_is_road", point)):
			return "Deixe as trilhas livres"
		if not floors.is_empty() and not _has_neighbor(floors, cell):
			return "Amplie a casa por pisos vizinhos"
		if _near_world_obstacle(point):
			return "Remova os objetos neste local"
	elif not floors.has(cell):
		return "Primeiro pinte o piso"
	elif brush_index == 1:
		if doors.has(cell):
			return "Ja existe uma porta aqui"
		if not _is_edge(cell):
			return "Parede apenas na borda do piso"
	elif brush_index == 2:
		pass
	elif brush_index == 3:
		if not walls.has(cell):
			return "A porta substitui uma parede existente"
		if floors.has(cell + Vector2i.DOWN):
			return "Coloque a porta na fachada sul"
	return ""


func _near_world_obstacle(point: Vector2) -> bool:
	for candidate in world.get_children():
		if candidate == player or not (candidate is Node2D):
			continue
		var item: Node2D = candidate as Node2D
		if point.distance_to(item.global_position) > 24.0:
			continue
		if item.name.begins_with("Tree_") or item.name.begins_with("rock_") or item.name.begins_with("fruit_tree_"):
			return true
	return false


func _has_neighbor(set_of_cells: Dictionary, cell: Vector2i) -> bool:
	for direction in DIRS:
		if set_of_cells.has(cell + direction):
			return true
	return false


func _is_edge(cell: Vector2i) -> bool:
	if not floors.has(cell):
		return false
	for direction in DIRS:
		if not floors.has(cell + direction):
			return true
	return false


func _connected(cells: Dictionary) -> bool:
	if cells.size() <= 1:
		return true
	var first: Vector2i = cells.keys()[0]
	var visited: Dictionary = {first: true}
	var queue: Array[Vector2i] = [first]
	var index: int = 0
	while index < queue.size():
		var current: Vector2i = queue[index]
		index += 1
		for direction in DIRS:
			var nxt: Vector2i = current + direction
			if cells.has(nxt) and not visited.has(nxt):
				visited[nxt] = true
				queue.append(nxt)
	return visited.size() == cells.size()


func _apply_cell(cell: Vector2i, adding: bool) -> void:
	var reason: String = _valid_reason(cell, adding)
	if not reason.is_empty():
		_set_status(reason)
		return
	if adding and brush_index == 0 and int(inventory.call("quantity", "madeira")) < 1:
		_set_status("Falta madeira. Colete troncos usando machado")
		return
	_remember()
	if adding and brush_index == 0:
		inventory.call("take_item", "madeira", 1)
		if floors.is_empty():
			anchor_cell = cell
	var selected: Dictionary = _layer_set()
	if adding:
		selected[cell] = true
	else:
		selected.erase(cell)
		if brush_index == 0:
			walls.erase(cell)
			roofs.erase(cell)
			doors.erase(cell)
			inventory.call("add_item", "madeira", 1)
		elif brush_index == 1:
			doors.erase(cell)
	# Um quadro de porta toma o lugar da pintura de parede, mas nao de sua colisao.
	_update_rendering()
	_set_status(BRUSHES[brush_index] + (" colocado" if adding else " removido"))


func _remember() -> void:
	history.append(_snapshot())
	if history.size() > 40:
		history.pop_front()


func _snapshot() -> Dictionary:
	var amounts: Dictionary = inventory.get("counts")
	return {
		"floors": floors.duplicate(), "walls": walls.duplicate(),
		"roofs": roofs.duplicate(), "doors": doors.duplicate(),
		"anchor": anchor_cell, "resources": amounts.duplicate()
	}


func _restore(previous: Dictionary) -> void:
	floors = previous.get("floors", {}).duplicate()
	walls = previous.get("walls", {}).duplicate()
	roofs = previous.get("roofs", {}).duplicate()
	doors = previous.get("doors", {}).duplicate()
	anchor_cell = previous.get("anchor", INVALID_CELL)
	var items: Dictionary = previous.get("resources", {}).duplicate()
	if not items.is_empty():
		inventory.set("counts", items)
		inventory.emit_signal("inventory_changed")
	_update_rendering()


func _undo() -> void:
	if history.is_empty():
		_set_status("Nao ha mais acoes para desfazer")
		return
	_restore(history.pop_back())
	_set_status("Ultima alteracao desfeita")


func _update_rendering() -> void:
	if floor_layer == null:
		return
	floor_layer.clear()
	wall_layer.clear()
	roof_layer.clear()
	door_layer.clear()
	for cell in floors:
		floor_layer.set_cell(cell, 0, Vector2i.ZERO)
	for cell in walls:
		wall_layer.set_cell(cell, 1, Vector2i.ZERO)
	for cell in roofs:
		roof_layer.set_cell(cell, 2, Vector2i.ZERO)
	for cell in doors:
		door_layer.set_cell(cell, 3, Vector2i.ZERO)
	_rebuild_wall_collisions()
	_update_roof_visibility()


func _rebuild_wall_collisions() -> void:
	for child in collisions.get_children():
		child.queue_free()
	for cell in walls:
		if doors.has(cell):
			continue
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = _cell_center(cell)
		collisions.add_child(body)
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(29.0, 28.0)
		collision.shape = shape
		body.add_child(collision)


func _update_roof_visibility() -> void:
	if roof_layer == null:
		return
	roof_layer.visible = not hide_roof_manually and (building and brush_index == 2 or not building and not floors.has(_player_cell()))
	roof_layer.modulate.a = roof_opacity_in_build if building else 1.0


func _set_status(msg: String) -> void:
	_last_status = msg
	_refresh_panel()


func _refresh_panel(reason: String = "") -> void:
	if status_label == null:
		return
	var text := "CONSTRUIR CASA [B]  |  %s\n" % BRUSHES[brush_index]
	text += "1 Piso  2 Parede  3 Telhado  4 Porta | LMB pintar | RMB apagar\n"
	text += "Ctrl+Z desfazer  Ctrl+S salvar  Ctrl+L carregar  R ver telhado\n"
	text += "Madeira: %d | Piso -1 madeira/bloco | Parede/telhado/porta: gratis\n" % int(inventory.call("quantity", "madeira"))
	text += (reason if not reason.is_empty() else _last_status)
	status_label.text = text


func _cells_to_json(cells: Dictionary) -> Array:
	var data: Array = []
	for cell in cells:
		data.append([cell.x, cell.y])
	return data


func _cells_from_json(data: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not (data is Array):
		return result
	for point in data:
		if point is Array and point.size() == 2:
			var cell := Vector2i(int(point[0]), int(point[1]))
			if ground.get_cell_source_id(cell) >= 0:
				result[cell] = true
	return result


func _save_house() -> void:
	var obj: Dictionary = {
		"version": 1,
		"floor": _cells_to_json(floors),
		"wall": _cells_to_json(walls),
		"roof": _cells_to_json(roofs),
		"door": _cells_to_json(doors),
		"anchor": [anchor_cell.x, anchor_cell.y],
		"items": inventory.get("counts")
	}
	var file: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		_set_status("Nao foi possivel gravar o arquivo")
		return
	file.store_string(JSON.stringify(obj, "\t"))
	file.close()
	_set_status("Casa e inventario salvos")


func _load_house() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var file: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		_set_status("Erro ao abrir save")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_set_status("Save invalido")
		return
	var data: Dictionary = parsed
	if int(data.get("version", -1)) != 1:
		_set_status("Versao de save nao suportada")
		return
	var loaded_floor: Dictionary = _cells_from_json(data.get("floor", []))
	if not _connected(loaded_floor):
		_set_status("Casa salva desconectada: leitura cancelada")
		return
	floors = loaded_floor
	walls = _cells_from_json(data.get("wall", []))
	roofs = _cells_from_json(data.get("roof", []))
	doors = _cells_from_json(data.get("door", []))
	for cell in walls.keys():
		if not floors.has(cell) or not _is_edge(cell):
			walls.erase(cell)
	for cell in roofs.keys():
		if not floors.has(cell):
			roofs.erase(cell)
	for cell in doors.keys():
		if not floors.has(cell) or not walls.has(cell):
			doors.erase(cell)
	var saved_anchor: Variant = data.get("anchor", [])
	if saved_anchor is Array and saved_anchor.size() == 2:
		anchor_cell = Vector2i(int(saved_anchor[0]), int(saved_anchor[1]))
	else:
		anchor_cell = INVALID_CELL
	if not floors.is_empty() and not floors.has(anchor_cell):
		anchor_cell = floors.keys()[0]
	if floors.is_empty():
		anchor_cell = INVALID_CELL
	var items: Variant = data.get("items", {})
	if items is Dictionary:
		var merged: Dictionary = inventory.get("counts").duplicate()
		for item_id in merged.keys():
			if items.has(item_id):
				merged[item_id] = clampi(int(items[item_id]), 0, 99)
		inventory.set("counts", merged)
		inventory.emit_signal("inventory_changed")
	history.clear()
	_update_rendering()
	_set_status("Casa carregada do save")

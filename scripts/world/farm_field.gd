extends Node2D
## Campo de cultivo: grade de células de 32 px. O [F] usa o item selecionado na
## barra rápida na célula à frente: enxada ara, regador rega, semente planta;
## qualquer item colhe uma cultura pronta.
## A terra arada é pixel art procedural na paleta dos solos PixelLab, com bordas
## arredondadas conforme as vizinhas; as culturas usam os sprites PixelLab prontos.

const FARM := preload("res://scripts/systems/farm_state.gd")
const CROPS := preload("res://scripts/systems/crop_catalog.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const ENERGY := preload("res://scripts/systems/energy_state.gd")
const PROGRESS := preload("res://scripts/systems/session_progress_session.gd")
const CELL := 32
## Alcance do [F]: célula à frente do jogador.
const REACH := 22.0
const DRY := [Color("#2c190e"), Color("#442a19"), Color("#503321"), Color("#5b3b26"), Color("#63412b"), Color("#705138")]
const WET := [Color("#0b0402"), Color("#23150e"), Color("#2c1c14"), Color("#321e13"), Color("#3c2619"), Color("#473123")]
const FACING := {"north": Vector2(0, -1), "south": Vector2(0, 1), "east": Vector2(1, 0), "west": Vector2(-1, 0),
	"north-east": Vector2(1, -1), "north-west": Vector2(-1, -1), "south-east": Vector2(1, 1), "south-west": Vector2(-1, 1)}

## Primeira célula (grade do mundo, em células de 32 px) e tamanho do campo.
@export var origin_cell := Vector2i(24, 12)
@export var size_cells := Vector2i(6, 4)
## Nome do campo no estado da sessão (cada mapa tem o seu).
@export var field_id := "vale"
## Campo livre (pedido do usuário, 2026-11-22): sem retângulo fixo; a enxada ara
## qualquer chão em que farmable(célula) for true (sem colisão, água nem casa).
var free_area := false
var farmable: Callable
## Ponto do mundo é água (lago, riacho)? Regador virado para ela enche.
var water_at: Callable
## Solta o produto colhido no chão (item, quantidade, ponto); vazio = direto na bolsa.
var drop: Callable

var last_action := ""
var player: Node2D
var _soil: Node2D
var _crop_nodes: Dictionary = {}
var _textures: Dictionary = {}
var _hidden_decor: Array[CanvasItem] = []


func _ready() -> void:
	name = "FarmField"
	y_sort_enabled = true
	_soil = Node2D.new()
	_soil.name = "Soil"
	# Abaixo do mato (z -2) e das sombras (z -1), acima do chão e dos caminhos.
	_soil.z_as_relative = false
	_soil.z_index = -3
	_soil.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_soil.draw.connect(_draw_soil)
	add_child(_soil)
	FARM.grant_starter_seeds(get_tree())
	if FARM.catch_up(get_tree(), GameClock.day_number) > 0:
		ENERGY.restore(get_tree())
	if not GameClock.day_changed.is_connected(_on_day_changed):
		GameClock.day_changed.connect(_on_day_changed)
	_clear_decor.call_deferred()
	refresh()


func _exit_tree() -> void:
	if GameClock.day_changed.is_connected(_on_day_changed):
		GameClock.day_changed.disconnect(_on_day_changed)
	for item in _hidden_decor:
		if is_instance_valid(item): item.show()


func world_rect() -> Rect2:
	return Rect2(Vector2(origin_cell * CELL), Vector2(size_cells * CELL))


func cell_at(world: Vector2) -> Vector2i:
	return Vector2i(floori(world.x / CELL), floori(world.y / CELL))


func contains(cell: Vector2i) -> bool:
	if free_area:
		if FARM.is_tilled(get_tree(), cell, field_id): return true
		_index_decor()
		return not _bush_cells.has(cell) and farmable.is_valid() and bool(farmable.call(cell))
	return Rect2i(origin_cell, size_cells).has_point(cell)


## O [F] desta célula é do campo? Terra arada, ou um item que age nela (enxada na
## grama, regador, semente). Grama sem ferramenta não toma o [F] (mato, árvores...).
func wants(actor: Node2D) -> bool:
	if can_fill(actor): return true
	var cell := target_cell(actor)
	if not contains(cell): return false
	return FARM.is_tilled(get_tree(), cell, field_id) or action_with(cell, HOTBAR.selected_item(get_tree())) != ""


## Célula à frente do jogador (ou sob ele, se não houver célula à frente).
func target_cell(actor: Node2D) -> Vector2i:
	var dir: Vector2 = FACING.get(str(actor.get("facing")), Vector2.DOWN).normalized()
	var ahead := cell_at(actor.global_position + dir * REACH)
	if contains(ahead):
		return ahead
	var under := cell_at(actor.global_position)
	return under if contains(under) else Vector2i(-99999, -99999)


func has_target(actor: Node2D) -> bool:
	return contains(target_cell(actor))


## Regador selecionado, olhando para a água à frente (e sem terra arada ali).
func can_fill(actor: Node2D) -> bool:
	if HOTBAR.selected_item(get_tree()) != "regador" or not water_at.is_valid(): return false
	var dir: Vector2 = FACING.get(str(actor.get("facing")), Vector2.DOWN).normalized()
	for reach in [24.0, 40.0, 56.0, 72.0]:  # a água pode começar depois da margem
		if bool(water_at.call(actor.global_position + dir * reach)): return true
	return false


## Ação do item na célula: harvest, till, water, plant ou "" (nada a fazer).
func action_with(cell: Vector2i, item: String) -> String:
	var tree := get_tree()
	if FARM.is_ready(tree, cell, field_id):
		return "harvest"
	match ITEMS.kind(item):
		"tool":
			if item == "enxada" and not FARM.is_tilled(tree, cell, field_id): return "till"
			if item == "regador" and FARM.is_tilled(tree, cell, field_id) and not FARM.is_watered(tree, cell, field_id): return "water"
		"seed":
			if FARM.is_tilled(tree, cell, field_id) and FARM.crop(tree, cell, field_id).is_empty() and BAG.count_item(tree, item) > 0: return "plant"
	return ""


func hint(actor: Node2D) -> String:
	if can_fill(actor):
		return "[F] Encher o regador (%d/%d)" % [FARM.can_water(get_tree()), FARM.CAN_MAX]
	var cell := target_cell(actor)
	var tree := get_tree()
	var item := HOTBAR.selected_item(tree)
	var crop_name := str(CROPS.get_crop(FARM.crop(tree, cell, field_id)).get("name", ""))
	match action_with(cell, item):
		"harvest": return "[F] Colher " + crop_name
		"till": return "[F] Arar com a enxada"
		"water":
			if FARM.can_water(tree) <= 0: return "Regador vazio · encha no lago ou no riacho"
			return "[F] Regar" + (" " + crop_name if not crop_name.is_empty() else " a terra") + " (água %d/%d)" % [FARM.can_water(tree), FARM.CAN_MAX]
		"plant": return "[F] Plantar " + str(ITEMS.info(item).name).to_lower()
	if not FARM.is_tilled(tree, cell, field_id): return "Grama · selecione a enxada"
	if not crop_name.is_empty():
		return crop_name + (" regada hoje · cresce amanhã" if FARM.is_watered(tree, cell, field_id) else " com sede · selecione o regador")
	return "Terra arada · selecione uma semente" if not FARM.is_watered(tree, cell, field_id) else "Terra arada e regada · selecione uma semente"


## Usa o item selecionado na célula à frente; devolve a mensagem para o jogador.
func interact(actor: Node2D) -> String:
	var tree := get_tree()
	if can_fill(actor):
		FARM.fill_can(tree)
		if actor.has_method("play_tool"): actor.play_tool("water")
		last_action = "Regador cheio (%d/%d)." % [FARM.CAN_MAX, FARM.CAN_MAX]
		return last_action
	var cell := target_cell(actor)
	var item := HOTBAR.selected_item(tree)
	var message := ""
	var action := action_with(cell, item)
	if action in ENERGY.COSTS and not ENERGY.spend(tree, action):
		last_action = preload("res://scripts/systems/protagonist.gd").tired_message(get_tree())
		return last_action
	match action:
		"harvest":
			var crop_info := CROPS.get_crop(FARM.crop(tree, cell, field_id))
			var harvested := str(crop_info.name)
			if FARM.harvest(tree, cell, field_id, not drop.is_valid()):
				if drop.is_valid(): drop.call(str(crop_info.harvest), 1, Vector2(cell * CELL) + Vector2(CELL, CELL) * 0.5)
				message = "%s colhida e guardada na bolsa!" % harvested
				PROGRESS.mark_event(tree, PROGRESS.GARDEN_HARVESTED)  # marco da sessão (antes: canteiros)
		"till":
			if FARM.till(tree, cell, field_id):
				message = "Terra arada."
				_clear_cell_decor(cell)
			if actor.has_method("play_tool"): actor.play_tool("hoe")
		"water":
			if FARM.can_water(tree) <= 0:
				last_action = "O regador está vazio. Encha no lago ou no riacho."
				return last_action
			if FARM.water(tree, cell, field_id):
				FARM.use_can(tree)
				message = "Terra regada (água %d/%d)." % [FARM.can_water(tree), FARM.CAN_MAX]
			if actor.has_method("play_tool"): actor.play_tool("water")
		"plant":
			var crop_id := str(ITEMS.info(item).crop)
			if FARM.plant(tree, cell, crop_id, field_id):
				message = "%s plantada. Regue todo dia para crescer." % CROPS.get_crop(crop_id).name
				PROGRESS.mark_event(tree, PROGRESS.GARDEN_PLANTED)
	last_action = message
	refresh()
	return message


func _on_day_changed(day: int) -> void:
	if FARM.catch_up(get_tree(), day) > 0:
		ENERGY.restore(get_tree())
	refresh()


func refresh() -> void:
	if is_instance_valid(_soil):
		_soil.queue_redraw()
	var cells: Dictionary = FARM.cells(get_tree(), field_id) if is_inside_tree() else {}
	for cell in _crop_nodes.keys():
		var crop_id := str(cells.get(cell, {}).get("crop", ""))
		if crop_id.is_empty() or not contains(cell):
			_crop_nodes[cell].queue_free()
			_crop_nodes.erase(cell)
	for cell in cells:
		if not contains(cell):
			continue
		var crop_id := str(cells[cell].get("crop", ""))
		if crop_id.is_empty():
			continue
		_show_crop(cell, CROPS.get_crop(crop_id).stages[int(cells[cell].get("stage", 0))])


func _show_crop(cell: Vector2i, path: String) -> void:
	var anchor: Node2D = _crop_nodes.get(cell)
	if not is_instance_valid(anchor):
		anchor = Node2D.new()
		anchor.name = "Crop_%d_%d" % [cell.x, cell.y]
		# Base da planta no meio da célula, um pouco abaixo do centro (ordem por Y).
		anchor.position = Vector2(cell * CELL) + Vector2(CELL * 0.5, CELL * 0.72)
		add_child(anchor)
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		anchor.add_child(sprite)
		_crop_nodes[cell] = anchor
	var sprite: Sprite2D = anchor.get_node("Sprite")
	var texture: Texture2D = load(path)
	if sprite.texture != texture:
		sprite.texture = texture
		var used := texture.get_image().get_used_rect()
		sprite.position = -Vector2(used.position.x + used.size.x * 0.5, used.end.y)


## Mato, flores e cogumelos decorativos dentro do campo dão lugar à terra (só em
## execução; o mapa não é alterado). Árvores, pedras e o que tem colisão ficam.
func _clear_decor() -> void:
	var region := get_parent()
	if not region:
		return
	if free_area:
		for cell in FARM.cells(get_tree(), field_id): _clear_cell_decor(cell)
		return
	var rect := world_rect().grow(4)
	for node in region.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if is_ancestor_of(sprite) or not sprite.visible or not sprite.texture:
			continue
		var path := sprite.texture.resource_path.to_lower()
		if not ("grass" in path or "flower" in path or "fern" in path or "mushroom" in path or "clover" in path):
			continue
		var holder: Node2D = sprite.get_parent() if sprite.name == &"Sprite" else sprite
		if not rect.has_point(holder.global_position) or not holder.find_children("*", "StaticBody2D", true, false).is_empty():
			continue
		holder.hide()
		_hidden_decor.append(holder)


var _decor_index := {}  # célula -> [nós de decoração] (campo livre)
var _bush_cells := {}  # células com arbusto: não se ara (campo livre)
var _decor_indexed := false


## Índice da decoração baixa por célula (uma vez): mato, flores, cogumelos e
## pedrinhas somem ao arar; arbusto bloqueia a célula.
func _index_decor() -> void:
	if _decor_indexed: return
	_decor_indexed = true
	var region := get_parent()
	if not region: return
	for node in region.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if is_ancestor_of(sprite) or not sprite.texture: continue
		var path := sprite.texture.resource_path.to_lower()
		var holder: Node2D = sprite.get_parent() if sprite.name == &"Sprite" else sprite
		if "bush" in path or "shrub" in path:
			var base := cell_at(holder.global_position)
			for dy in range(-1, 1):  # a copa cobre a célula de cima também
				for dx in range(-1, 2): _bush_cells[base + Vector2i(dx, dy)] = true
			continue
		if not ("grass" in path or "flower" in path or "fern" in path or "mushroom" in path or "clover" in path or "pebble" in path): continue
		if not holder.find_children("*", "StaticBody2D", true, false).is_empty(): continue
		var key := cell_at(holder.global_position)
		if not _decor_index.has(key): _decor_index[key] = []
		_decor_index[key].append(holder)


## Mato, flores e cogumelos da célula arada somem (e o tile de mato da camada baixa).
func _clear_cell_decor(cell: Vector2i) -> void:
	var region := get_parent()
	if not region: return
	_index_decor()
	for holder in _decor_index.get(cell, []):
		if is_instance_valid(holder) and holder.visible:
			holder.hide()
			_hidden_decor.append(holder)
	var low := region.get_node_or_null("VegetationLow") as TileMapLayer
	if low:
		var tile := low.local_to_map(low.to_local(Vector2(cell * CELL) + Vector2(CELL, CELL) * 0.5))
		if low.get_cell_source_id(tile) != -1: low.erase_cell(tile)


## Terra arada: tilesets PixelLab (seca e molhada) em dual-grid — cada tile fica num
## vértice e escolhe a peça pelos 4 cantos (células) arados em volta; a molhada vai
## por cima da seca. Sem os PNGs, cai no desenho procedural antigo.
const SOIL_SHEETS := {"dry": "res://assets/tilesets/farm/soil_dry", "wet": "res://assets/tilesets/farm/soil_wet"}
var _soil_atlas := {}


func _soil_sheet(kind: String) -> Dictionary:
	if not _soil_atlas.has(kind):
		var base: String = SOIL_SHEETS[kind]
		if ResourceLoader.exists(base + ".png") and FileAccess.file_exists(base + ".json"):
			_soil_atlas[kind] = {"texture": load(base + ".png"),
				"tiles": JSON.parse_string(FileAccess.get_file_as_string(base + ".json")).tiles}
		else:
			_soil_atlas[kind] = {}
	return _soil_atlas[kind]


func _draw_soil() -> void:
	var cells: Dictionary = FARM.cells(get_tree(), field_id)
	var dry := _soil_sheet("dry")
	if dry.is_empty():
		_draw_soil_procedural(cells)
		return
	var tilled := {}
	var wet := {}
	for cell in cells:
		if not contains(cell): continue
		tilled[cell] = true
		if bool(cells[cell].get("watered", false)): wet[cell] = true
	_draw_dual(dry, tilled)
	var wet_sheet := _soil_sheet("wet")
	if not wet_sheet.is_empty(): _draw_dual(wet_sheet, wet)


func _draw_dual(sheet: Dictionary, on: Dictionary) -> void:
	var done := {}
	for cell in on:
		for dy in 2:
			for dx in 2:
				var v: Vector2i = cell + Vector2i(dx, dy)
				if done.has(v): continue
				done[v] = true
				var corners: PackedStringArray = []
				for o in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
					corners.append("m" if on.has(v + o) else "e")
				var key := ",".join(corners)
				var at: Array = sheet.tiles.get(key, [])
				if at.is_empty(): continue
				_soil.draw_texture_rect_region(sheet.texture, Rect2(Vector2(v * CELL) - Vector2(CELL, CELL) * 0.5, Vector2(CELL, CELL)),
					Rect2(at[0], at[1], CELL, CELL))


func _draw_soil_procedural(cells: Dictionary) -> void:
	for cell in cells:
		if not contains(cell):
			continue
		var mask := 0
		for bit in 4:
			var offset: Vector2i = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)][bit]
			if cells.has(cell + offset): mask |= 1 << bit
		var wet := bool(cells[cell].get("watered", false))
		_soil.draw_texture(soil_texture(mask, wet), Vector2(cell * CELL))


func soil_texture(mask: int, wet: bool) -> ImageTexture:
	var key := mask + (16 if wet else 0)
	if not _textures.has(key):
		_textures[key] = ImageTexture.create_from_image(soil_image(mask, wet))
	return _textures[key]


## Terra arada 32×32: sulcos horizontais (crista clara, sulco escuro), grãos
## espalhados por hash e borda escura arredondada nos lados sem vizinha arada
## (bits de mask: 1 norte, 2 leste, 4 sul, 8 oeste).
static func soil_image(mask: int, wet: bool) -> Image:
	var pal: Array = WET if wet else DRY
	var image := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	var open_n := mask & 1 == 0
	var open_e := mask & 2 == 0
	var open_s := mask & 4 == 0
	var open_w := mask & 8 == 0
	for y in CELL:
		for x in CELL:
			# Distância até a borda "aberta" mais próxima (onde não há terra vizinha).
			var edge := 99
			if open_n: edge = mini(edge, y)
			if open_s: edge = mini(edge, CELL - 1 - y)
			if open_w: edge = mini(edge, x)
			if open_e: edge = mini(edge, CELL - 1 - x)
			# Cantos arredondados quando os dois lados do canto estão abertos.
			var corner := 99
			for c in [[open_n and open_w, x, y], [open_n and open_e, CELL - 1 - x, y], [open_s and open_w, x, CELL - 1 - y], [open_s and open_e, CELL - 1 - x, CELL - 1 - y]]:
				if c[0]:
					var d := Vector2(maxf(0.0, 4.0 - c[1]), maxf(0.0, 4.0 - c[2])).length()
					corner = mini(corner, int(round(4.0 - d)))
			edge = mini(edge, corner)
			if edge < 1:
				continue  # transparente: o gramado aparece
			var color: Color
			if edge == 1:
				color = pal[0]  # contorno
			else:
				var wobble := int(hash(Vector2i(x / 4, 7)) % 3) - 1
				var row := posmod(y + wobble, 8)
				color = pal[4] if row <= 1 else (pal[1] if row >= 6 else pal[3 if (x + y) % 5 else 2])
				var grain := hash(Vector2i(x, y)) % 53
				if grain == 0: color = pal[5]
				elif grain == 1: color = pal[0]
				if edge == 2 and open_s and y >= CELL - 3: color = pal[1]  # borda de baixo em sombra
			image.set_pixel(x, y, color)
	return image

extends Node2D
## Campo de cultivo: grade de células de 32 px onde o jogador ara, planta, rega e
## colhe com [E] (ação conforme o estado da célula) e troca a semente com [R].
## A terra arada é pixel art procedural na paleta dos solos PixelLab, com bordas
## arredondadas conforme as vizinhas; as culturas usam os sprites PixelLab prontos.

const FARM := preload("res://scripts/systems/farm_state.gd")
const CROPS := preload("res://scripts/systems/crop_catalog.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const CELL := 32
## Alcance do [E]: célula à frente do jogador.
const REACH := 22.0
const DRY := [Color("#2c190e"), Color("#442a19"), Color("#503321"), Color("#5b3b26"), Color("#63412b"), Color("#705138")]
const WET := [Color("#0b0402"), Color("#23150e"), Color("#2c1c14"), Color("#321e13"), Color("#3c2619"), Color("#473123")]
const FACING := {"north": Vector2(0, -1), "south": Vector2(0, 1), "east": Vector2(1, 0), "west": Vector2(-1, 0),
	"north-east": Vector2(1, -1), "north-west": Vector2(-1, -1), "south-east": Vector2(1, 1), "south-west": Vector2(-1, 1)}

## Primeira célula (grade do mundo, em células de 32 px) e tamanho do campo.
@export var origin_cell := Vector2i(24, 12)
@export var size_cells := Vector2i(6, 4)

var selected_crop := "cenoura"
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
	return Rect2i(origin_cell, size_cells).has_point(cell)


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


func cycle_seed() -> void:
	var order := CROPS.ids()
	for step in order.size():
		selected_crop = order[(order.find(selected_crop) + 1) % order.size()]
		if BAG.count_item(get_tree(), str(CROPS.get_crop(selected_crop).seed)) > 0:
			return


func seed_count(crop_id: String) -> int:
	return BAG.count_item(get_tree(), str(CROPS.get_crop(crop_id).seed))


func hint(actor: Node2D) -> String:
	var cell := target_cell(actor)
	var tree := get_tree()
	var seed_text := "%s (%d)" % [CROPS.get_crop(selected_crop).name, seed_count(selected_crop)]
	match FARM.action_for(tree, cell, selected_crop):
		"till": return "[E] Arar a terra   •   [R] Semente: " + seed_text
		"plant": return ("[E] Plantar " + seed_text if seed_count(selected_crop) > 0 else "Sem sementes de " + CROPS.get_crop(selected_crop).name) + "   •   [R] Trocar semente"
		"water": return "[E] Regar " + str(CROPS.get_crop(FARM.crop(tree, cell)).name)
		"harvest": return "[E] Colher " + str(CROPS.get_crop(FARM.crop(tree, cell)).name)
		_: return str(CROPS.get_crop(FARM.crop(tree, cell)).name) + " regada hoje · cresce amanhã"


## Executa a ação da célula à frente; devolve a mensagem para o jogador.
func interact(actor: Node2D) -> String:
	var cell := target_cell(actor)
	var tree := get_tree()
	var message := ""
	match FARM.action_for(tree, cell, selected_crop):
		"till":
			if FARM.till(tree, cell): message = "Terra arada."
		"plant":
			var name_text: String = CROPS.get_crop(selected_crop).name
			message = ("%s plantada. Regue todo dia para crescer." % name_text) if FARM.plant(tree, cell, selected_crop) else "Sem sementes de %s." % name_text
		"water":
			if FARM.water(tree, cell): message = "Terra regada."
		"harvest":
			var harvested: String = CROPS.get_crop(FARM.crop(tree, cell)).name
			if FARM.harvest(tree, cell): message = "%s colhida e guardada na bolsa!" % harvested
		_:
			message = "Já foi regada hoje."
	refresh()
	return message


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_R and is_instance_valid(player) and has_target(player):
		cycle_seed()
		get_viewport().set_input_as_handled()


func _on_day_changed(_day: int) -> void:
	FARM.advance_day(get_tree())
	refresh()


func refresh() -> void:
	if is_instance_valid(_soil):
		_soil.queue_redraw()
	var cells: Dictionary = get_tree().get_meta(FARM.KEY, {}) if is_inside_tree() else {}
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


func _draw_soil() -> void:
	var cells: Dictionary = get_tree().get_meta(FARM.KEY, {})
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

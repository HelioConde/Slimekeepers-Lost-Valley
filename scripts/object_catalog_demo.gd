extends Node2D
<<<<<<< HEAD

const Scales = preload("res://scripts/world_object_scales.gd")
=======
>>>>>>> d8e6de3 (Adiciona exportacao completa dos objetos PixelLab)
## Cenario-vitrine com comparacao individual de escala para todos os PNGs.
## O player 0.40 e mostrado ao lado de cada objeto como referencia visual.
## O personagem de verdade continua movendo com a Camera2D.

const EXPORT_ROOT: String = "res://sprites/objects/pixellab_exports"
const COLS: int = 8
const CELL_W: float = 170.0
const CELL_H: float = 160.0
const SIDE_PADDING: float = 130.0
const HEADER_HEIGHT: float = 115.0
const SECTION_GAP: float = 105.0
const FOOTER_HEIGHT: float = 55.0
const SECTOR_ORDER = [
	"Floresta", "Mineracao", "Fazenda", "Construcoes",
	"Ruinas e Magia", "Efeitos", "Diversos"
]
const SECTOR_COLORS = [
	"314e35", "41454b", "645637", "574738",
	"423954", "573f42", "394947"
]

@export var show_object_names: bool = true
<<<<<<< HEAD
=======
@export_range(0.6, 3.0, 0.05) var maximum_preview_scale: float = 1.5
@export_range(0.40, 1.40, 0.05) var non_tree_scale: float = 1.0
>>>>>>> d8e6de3 (Adiciona exportacao completa dos objetos PixelLab)
@export var show_player_reference: bool = true
@export var show_height_comparison: bool = true
@export_range(0.5, 2.0, 0.05) var initial_camera_zoom: float = 1.1

@onready var catalog_objects: Node2D = $CatalogObjects
@onready var player: CharacterBody2D = $CatalogObjects/Player
@onready var player_camera: Camera2D = $CatalogObjects/Player/Camera2D
@onready var help_label: Label = $HUD/HelpLabel

var _sectors: Array[Dictionary] = []
var _labels: Array[Dictionary] = []
var _last_sector_index: int = -1
var _total_items: int = 0
var _character_height: float = 42.0
var _bounds: Rect2 = Rect2()


func _ready() -> void:
	var items: Array[Dictionary] = _read_exported_objects()
	_total_items = items.size()
<<<<<<< HEAD
	_character_height = Scales.REFERENCE_PLAYER_HEIGHT
=======
	_character_height = _get_player_visual_height()
>>>>>>> d8e6de3 (Adiciona exportacao completa dos objetos PixelLab)
	_build_sector_layout(items)
	_create_object_displays()
	_configure_player_camera()
	_create_border_colliders()
	_refresh_hud(true)
	queue_redraw()


func _process(_delta: float) -> void:
	_refresh_hud(false)


func _draw() -> void:
	# Piso por setor, faixas das fileiras e caminho aberto para explorar andando.
	for i in range(_sectors.size()):
		var sector: Dictionary = _sectors[i]
		var rect: Rect2 = sector["rect"]
		var color: Color = sector["color"]
		draw_rect(rect, color, true)
		draw_rect(rect, color.lightened(0.13), false, 3.0)
		var path_rect := Rect2(rect.position + Vector2(24.0, HEADER_HEIGHT), Vector2(82.0, rect.size.y - HEADER_HEIGHT - 15.0))
		draw_rect(path_rect, color.lightened(0.06), true)
		_draw_text(String(sector["title"]), rect.position + Vector2(22.0, 38.0), 27, Color.WHITE)
		_draw_text("%d objetos  |  SETOR %d" % [int(sector["count"]), i + 1], rect.position + Vector2(24.0, 64.0), 15, Color(0.85, 0.94, 0.86))
		draw_line(rect.position + Vector2(20.0, 79.0), Vector2(rect.end.x - 20.0, rect.position.y + 79.0), Color(1, 1, 1, 0.18), 2.0)
		# Marcadores discretos das fileiras.
		for row in range(int(sector["rows"])):
			var marker_y: float = rect.position.y + HEADER_HEIGHT + float(row) * CELL_H + 62.0
			draw_circle(Vector2(rect.position.x + 64.0, marker_y), 4.0, Color(0.94, 0.90, 0.72, 0.65))

	if show_object_names:
		for entry in _labels:
			var label_pos: Vector2 = entry["position"]
			var label_text: String = entry["text"]
			_draw_text(label_text, label_pos, 12, Color(0.96, 0.97, 0.93), CELL_W - 15.0)
			if show_height_comparison:
				_draw_text(String(entry["comparison"]), label_pos + Vector2(0.0, 16.0), 10, Color(0.8, 0.9, 0.8, 0.8), CELL_W - 15.0)


func _draw_text(message: String, pos: Vector2, font_size: int, color: Color, max_width: float = -1.0) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	draw_string(font, pos, message, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, color)


func _read_exported_objects() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(EXPORT_ROOT)
	if dir == null:
		push_warning("PixelLab: pasta de objetos ausente: %s" % EXPORT_ROOT)
		return items

	var folders: Array[String] = []
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if not name.begins_with(".") and dir.current_is_dir():
			folders.append(name)
	dir.list_dir_end()
	folders.sort()

	for folder_name in folders:
		var folder: String = "%s/%s" % [EXPORT_ROOT, folder_name]
<<<<<<< HEAD
		var texture: Texture2D = Scales.preview_texture(folder)
		if texture == null:
			continue
=======
		var png_path: String = _find_file(folder, "png")
		if png_path.is_empty():
			continue
		var atlas: Texture2D = load(png_path) as Texture2D
		if atlas == null:
			continue
		var texture: Texture2D = _preview_from_spritesheet(atlas, _find_file(folder, "json"))
>>>>>>> d8e6de3 (Adiciona exportacao completa dos objetos PixelLab)
		items.append({
			"id": folder_name,
			"name": _friendly_name(folder_name),
			"sector": _sector_for_name(folder_name),
			"texture": texture,
		})
	return items


<<<<<<< HEAD
=======
func _find_file(folder: String, ext: String) -> String:
	var files: PackedStringArray = DirAccess.get_files_at(folder)
	files.sort()
	for filename in files:
		if filename.to_lower().ends_with("." + ext):
			return folder.path_join(filename)
	return ""


func _preview_from_spritesheet(atlas: Texture2D, json_path: String) -> Texture2D:
	# A exportacao da API pode conter diversas direcoes na mesma imagem.
	# Exibimos a PRIMEIRA CELULA, nao a folha inteira reduzida.
	if json_path.is_empty():
		return atlas
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		return atlas
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return atlas
	var metadata: Dictionary = parsed
	var sheet: Dictionary = metadata.get("spritesheet", {})
	var cell: Dictionary = sheet.get("cell_size", {})
	var cw: int = int(cell.get("width", 0))
	var ch: int = int(cell.get("height", 0))
	if cw <= 0 or ch <= 0:
		return atlas
	var tex_size: Vector2 = atlas.get_size()
	if cw > int(tex_size.x) or ch > int(tex_size.y):
		return atlas
	var preview := AtlasTexture.new()
	preview.atlas = atlas
	preview.region = Rect2(0.0, 0.0, float(cw), float(ch))
	return preview


>>>>>>> d8e6de3 (Adiciona exportacao completa dos objetos PixelLab)
func _friendly_name(folder_name: String) -> String:
	var parts: PackedStringArray = folder_name.split("_")
	if parts.size() >= 2:
		var tail: String = parts[parts.size() - 1]
		if tail.length() == 8 and tail.is_valid_hex_number(false):
			parts.remove_at(parts.size() - 1)
	var label: String = " ".join(parts)
	if label.length() > 25:
		label = label.substr(0, 24) + "…"
	return label


func _sector_for_name(folder_name: String) -> int:
	var name: String = folder_name.to_lower()
	# Construcoes primeiro para impedir "stone" em house_floor_stone ir para Mineracao.
	if _has_keyword(name, ["house", "roof", "wall", "door", "window", "floor", "fence", "bench", "barrel", "crate", "bridge", "well", "furnace", "workbench", "gate", "cart", "shed", "table", "chair"]):
		return 3
	if _has_keyword(name, ["ancient", "altar", "ruins", "ruin", "statue", "portal", "rune", "magic", "shrine", "totem", "monument", "temple"]):
		return 4
	if _has_keyword(name, ["tree", "oak", "pine", "bush", "flower", "grass", "mushroom", "stump", "log", "leaf", "plant", "vine", "shrub", "fern"]):
		return 0
	if _has_keyword(name, ["rock", "ore", "crystal", "mineral", "stone", "boulder", "cave", "gem"]):
		return 1
	if _has_keyword(name, ["farm", "crop", "seed", "soil", "plot", "sprout", "wheat", "corn", "pumpkin", "watering", "field", "hay"]):
		return 2
	if _has_keyword(name, ["fire", "torch", "ember", "waterfall", "ripple", "fountain", "wisp", "flame", "glow", "spark", "fireball", "fx", "effect", "smoke"]):
		return 5
	return 6


func _has_keyword(haystack: String, keywords: Array) -> bool:
	for keyword in keywords:
		if haystack.contains(keyword):
			return true
	return false


func _build_sector_layout(items: Array[Dictionary]) -> void:
	_sectors.clear()
	var groups: Array = []
	for i in range(SECTOR_ORDER.size()):
		groups.append([])
	for item in items:
		var category: int = item["sector"]
		groups[category].append(item)

	var world_y: float = 0.0
	var world_width: float = SIDE_PADDING * 2.0 + float(COLS) * CELL_W
	for i in range(SECTOR_ORDER.size()):
		var entries: Array = groups[i]
		if entries.is_empty():
			continue
		entries.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a["name"]) < String(b["name"]))
		var rows: int = ceili(float(entries.size()) / float(COLS))
		var sector_height: float = HEADER_HEIGHT + float(rows) * CELL_H + FOOTER_HEIGHT
		var sector_rect := Rect2(0.0, world_y, world_width, sector_height)
		_sectors.append({
			"title": SECTOR_ORDER[i],
			"color": Color(SECTOR_COLORS[i]),
			"rect": sector_rect,
			"rows": rows,
			"count": entries.size(),
			"items": entries,
		})
		world_y += sector_height + SECTION_GAP
	if not _sectors.is_empty():
		var final_rect: Rect2 = _sectors[_sectors.size() - 1]["rect"]
		_bounds = Rect2(Vector2.ZERO, Vector2(world_width, final_rect.end.y))
	else:
		_bounds = Rect2(Vector2.ZERO, Vector2(1280.0, 800.0))


<<<<<<< HEAD
## Cada sprite usa a mesma escala persistente do mundo.
func _preview_scale(item: Dictionary, texture: Texture2D) -> Vector2:
	var id: String = String(item["id"])
	return Vector2.ONE * Scales.scale_for(id, texture, _character_height)
=======
## Referencia real: altura visivel do personagem, ja com visual_scale = 0.40.
## Evita comparar os objetos com o tamanho (128x128) da folha original.
func _get_player_visual_height() -> float:
	var character_sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if character_sprite == null:
		return 42.0
	var frames: SpriteFrames = character_sprite.sprite_frames
	if frames == null or not frames.has_animation(character_sprite.animation):
		return 42.0
	if frames.get_frame_count(character_sprite.animation) == 0:
		return 42.0
	var character_tex: Texture2D = frames.get_frame_texture(character_sprite.animation, 0)
	if character_tex == null:
		return 42.0
	var image: Image = character_tex.get_image()
	if image == null or image.is_empty():
		return 42.0
	var used: Rect2i = image.get_used_rect()
	if used.size.y == 0:
		return 42.0
	return clampf(float(used.size.y) * absf(character_sprite.scale.y), 28.0, 70.0)


## Somente arvores em pe preservam a escala atual, que ja foi aprovada.
## Tocos e troncos sao recursos baixos e devem ser menores que o personagem.
func _is_standing_tree(object_id: String) -> bool:
	var name: String = object_id.to_lower()
	if _has_keyword(name, ["stump", "log", "fallen", "firewood", "branch", "house", "roof", "woodpile"]):
		return false
	return _has_keyword(name, ["tree", "oak", "pine", "palm", "willow", "birch", "spruce", "fir_"])


## Medidas relativas a ALTURA VISIVEL do protagonista (visual_scale=0.40).
## Ajustes baseados nas capturas do catalogo: as arvores em pe ficam INTACTAS.
## A prioridade dos testes importa (canteiro antes de crop; tronco antes de tree).
func _object_height_ratio(object_id: String) -> float:
	var name: String = object_id.to_lower()
	# Troncos caidos e tocos: aproximadamente 15 a 25% menores que antes.
	if _has_keyword(name, ["fallen_log", "fallen_trunk", "fallen_tree", "timber_log", "woodpile", "firewood"]):
		return 0.42
	if _has_keyword(name, ["stump", "tree_stump", "trunk", "log", "branch"]):
		return 0.48
	# Terra, canteiros e fases de plantio: abaixo da altura do joelho.
	if _has_keyword(name, ["farm_plot_ground", "tilled_soil", "soil_patch", "dirt_patch", "ground_v2", "floor_tile", "house_floor"]):
		return 0.33
	if _has_keyword(name, ["farm_plot", "planting_bed", "garden_bed", "raised_bed"]):
		return 0.44
	if _has_keyword(name, ["crop_growth", "crop_stage", "seedling", "sprout", "seed_", "seedbed"]):
		return 0.27
	if _has_keyword(name, ["crop", "wheat", "corn", "pumpkin", "vegetable", "fruit_bush"]):
		return 0.38
	if _has_keyword(name, ["grass", "flower", "wildflower", "fern", "weed", "herb"]):
		return 0.40
	if _has_keyword(name, ["mushroom", "fungus"]):
		return 0.34
	if _has_keyword(name, ["bush_small", "shrub_small", "flower_bush"]):
		return 0.48
	if _has_keyword(name, ["bush", "shrub", "hedge", "plant"]):
		return 0.66
	# Objetos pequenos de uso/interacao, comparados diretamente a cintura do heroi.
	if _has_keyword(name, ["campfire", "bonfire", "firepit", "fire_place"]):
		return 0.42
	if _has_keyword(name, ["flame", "fireball", "smoke", "spark"]):
		return 0.40
	if _has_keyword(name, ["storage_crate", "crate", "barrel", "chest", "box", "bucket", "pot", "sign", "lantern"]):
		return 0.58
	if _has_keyword(name, ["fence", "bench", "chair", "table", "cart", "wooden_bridge"]):
		return 0.60
	if _has_keyword(name, ["rock_small", "pebble", "gem_small", "ore_small"]):
		return 0.48
	if _has_keyword(name, ["rock_large", "boulder", "crystal_large"]):
		return 0.97
	if _has_keyword(name, ["rock", "ore", "mineral", "gem", "crystal", "stone"]):
		return 0.60
	# Componentes de construcoes, sem encolher portais/edificios completos.
	if _has_keyword(name, ["house_window", "house_floor", "house_wall", "floor", "tile", "path", "soil", "plot", "cobble"]):
		return 0.50
	if _has_keyword(name, ["house_door", "door", "gate"]):
		return 0.82
	if _has_keyword(name, ["house_roof", "roof", "wall", "bridge", "shed", "well", "furnace", "workbench"]):
		return 0.97
	if _has_keyword(name, ["house", "building", "temple"]):
		return 1.90
	if _has_keyword(name, ["altar", "statue", "ruin", "portal", "monument", "shrine", "totem"]):
		return 1.22
	return 0.67


## Largura permitida como multiplo da ALTURA DO OBJETO, para troncos compridos
## manterem o formato sem ficarem desproporcionalmente largos.
func _object_width_ratio(object_id: String) -> float:
	var name: String = object_id.to_lower()
	if _has_keyword(name, ["fallen_log", "fallen_trunk", "fallen_tree", "timber_log", "firewood", "woodpile"]):
		return 2.75
	if _has_keyword(name, ["farm_plot", "soil", "floor", "ground", "crop"]):
		return 2.0
	if _has_keyword(name, ["bridge", "fence", "wall", "roof", "house", "bench", "table"]):
		return 2.55
	if _has_keyword(name, ["bush", "shrub", "flower", "grass", "plant", "campfire", "firepit", "rock"]):
		return 1.85
	return 1.95


func _visible_rect(texture: Texture2D) -> Rect2i:
	# Uma textura pode ter uma area transparente extensa; use os pixels
	# ocupados, em vez das dimensoes da imagem original.
	var size: Vector2 = texture.get_size()
	var fallback := Rect2i(Vector2i.ZERO, Vector2i(int(size.x), int(size.y)))
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return fallback
	var used: Rect2i = image.get_used_rect()
	return fallback if used.size.x == 0 or used.size.y == 0 else used


func _preview_scale(item: Dictionary, texture: Texture2D) -> Vector2:
	var size: Vector2 = texture.get_size()
	var fit: float = minf((CELL_W - 28.0) / maxf(1.0, size.x), (CELL_H - 58.0) / maxf(1.0, size.y))
	var scale_factor: float = minf(maximum_preview_scale, fit)
	var object_id: String = String(item["id"])
	if not _is_standing_tree(object_id):
		var used: Rect2i = _visible_rect(texture)
		var visible_size := Vector2(used.size)
		var budget_height: float = _character_height * _object_height_ratio(object_id)
		var budget_width: float = budget_height * _object_width_ratio(object_id)
		scale_factor = minf(scale_factor, budget_height / maxf(1.0, visible_size.y))
		scale_factor = minf(scale_factor, budget_width / maxf(1.0, visible_size.x))
		scale_factor *= non_tree_scale
	return Vector2.ONE * maxf(0.03, scale_factor)
>>>>>>> d8e6de3 (Adiciona exportacao completa dos objetos PixelLab)


func _add_player_reference(holder: Node2D) -> void:
	if not show_player_reference:
		return
	var original: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if original == null or original.sprite_frames == null:
		return
	var animation: StringName = &"idle_south"
	if not original.sprite_frames.has_animation(animation):
		animation = original.animation
	if not original.sprite_frames.has_animation(animation):
		return
	var reference_texture: Texture2D = original.sprite_frames.get_frame_texture(animation, 0)
	if reference_texture == null:
		return
	var reference: Sprite2D = Sprite2D.new()
	reference.name = "ComparacaoPlayer40"
	reference.texture = reference_texture
	reference.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	reference.scale = original.scale
	reference.offset = original.offset
	reference.position = Vector2(-54.0, 0.0)
	reference.modulate = Color(0.87, 1.0, 0.9, 0.54)
	holder.add_child(reference)


func _create_object_displays() -> void:
	_labels.clear()
	for sector in _sectors:
		var entries: Array = sector["items"]
		var rect: Rect2 = sector["rect"]
		for i in range(entries.size()):
			var item: Dictionary = entries[i]
			var col: int = i % COLS
			var row: int = i / COLS
			var position: Vector2 = Vector2(
				SIDE_PADDING + float(col) * CELL_W + CELL_W * 0.5,
				rect.position.y + HEADER_HEIGHT + float(row) * CELL_H + 82.0
			)
			var holder: Node2D = Node2D.new()
			holder.name = String(item["id"])
			holder.position = position
			catalog_objects.add_child(holder)
			# O player duplicado e somente uma referencia VISUAL, sem colisao
			# ou scripts de movimento. O verdadeiro Player segue exploravel.
			_add_player_reference(holder)

			var sprite: Sprite2D = Sprite2D.new()
			var texture: Texture2D = item["texture"] as Texture2D
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = _preview_scale(item, texture)
			# Ajusta o ponto de apoio real em vez do fundo transparente do PNG.
<<<<<<< HEAD
			var used: Rect2i = Scales.visible_rect(texture)
			sprite.offset = Scales.anchor_offset(texture)
=======
			var tex_size: Vector2 = texture.get_size()
			var used: Rect2i = _visible_rect(texture)
			sprite.offset = Vector2(
				tex_size.x * 0.5 - (float(used.position.x) + float(used.size.x) * 0.5),
				tex_size.y * 0.5 - float(used.end.y)
			)
>>>>>>> d8e6de3 (Adiciona exportacao completa dos objetos PixelLab)
			sprite.position = Vector2(26.0, 0.0)
			holder.add_child(sprite)
			var scaled_height: float = float(used.size.y) * sprite.scale.y
			var pct: int = roundi(100.0 * scaled_height / maxf(1.0, _character_height))
			_labels.append({
				"text": String(item["name"]),
				"comparison": "Altura %d%% do player" % pct,
				"position": position + Vector2(-CELL_W * 0.45, 29.0),
			})


func _configure_player_camera() -> void:
	# Esses limites substituem os limites pequenos herdados do mapa da floresta.
	player_camera.enabled = true
	player_camera.zoom = Vector2.ONE * initial_camera_zoom
	player_camera.position_smoothing_enabled = true
	player_camera.position_smoothing_speed = 9.0
	player_camera.limit_left = int(_bounds.position.x)
	player_camera.limit_top = int(_bounds.position.y)
	player_camera.limit_right = int(_bounds.end.x)
	player_camera.limit_bottom = int(_bounds.end.y)
	player_camera.make_current()
	if not _sectors.is_empty():
		_teleport_to_sector(0)


func _create_border_colliders() -> void:
	# Sem colisao nos expositores: o player caminha livremente para observar.
	# Barreiras invisiveis somente nos limites externos para nao sair do mapa.
	var w: float = _bounds.size.x
	var h: float = _bounds.size.y
	_add_border(Vector2(-24.0, h * 0.5), Vector2(48.0, h + 96.0))
	_add_border(Vector2(w + 24.0, h * 0.5), Vector2(48.0, h + 96.0))
	_add_border(Vector2(w * 0.5, -24.0), Vector2(w + 96.0, 48.0))
	_add_border(Vector2(w * 0.5, h + 24.0), Vector2(w + 96.0, 48.0))


func _add_border(center: Vector2, extent: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = extent
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(0.1)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(-0.1)
	elif event is InputEventKey:
		var key_event: InputEventKey = event
		if not key_event.pressed or key_event.echo:
			return
		var key_code: int = key_event.physical_keycode
		if key_code >= KEY_1 and key_code <= KEY_7:
			_teleport_to_sector(key_code - KEY_1)
		elif key_code == KEY_PAGEUP:
			_teleport_to_sector(maxi(0, _find_current_sector() - 1))
		elif key_code == KEY_PAGEDOWN:
			_teleport_to_sector(mini(_sectors.size() - 1, _find_current_sector() + 1))
		elif key_code == KEY_EQUAL or key_code == KEY_KP_ADD:
			_adjust_zoom(0.1)
		elif key_code == KEY_MINUS or key_code == KEY_KP_SUBTRACT:
			_adjust_zoom(-0.1)


func _adjust_zoom(diff: float) -> void:
	var next_zoom: float = clampf(player_camera.zoom.x + diff, 0.6, 2.0)
	player_camera.zoom = Vector2.ONE * next_zoom
	_refresh_hud(true)


func _teleport_to_sector(index: int) -> void:
	if index < 0 or index >= _sectors.size():
		return
	var sector_rect: Rect2 = _sectors[index]["rect"]
	player.global_position = Vector2(71.0, sector_rect.position.y + HEADER_HEIGHT + 85.0)
	player.velocity = Vector2.ZERO
	player_camera.reset_smoothing()
	_refresh_hud(true)


func _find_current_sector() -> int:
	if _sectors.is_empty():
		return -1
	var y: float = player.global_position.y
	for i in range(_sectors.size()):
		var sector_rect: Rect2 = _sectors[i]["rect"]
		if y <= sector_rect.end.y + SECTION_GAP * 0.5:
			return i
	return _sectors.size() - 1


func _refresh_hud(force: bool) -> void:
	var current: int = _find_current_sector()
	if current == _last_sector_index and not force:
		return
	_last_sector_index = current
	var name: String = "Catalogo vazio"
	var count: int = 0
	if current >= 0:
		name = String(_sectors[current]["title"])
		count = int(_sectors[current]["count"])
	help_label.text = "CATALOGO PIXELLAB  |  %d objetos  |  Setor %d/%d: %s (%d)\n" % [_total_items, current + 1, _sectors.size(), name, count]
<<<<<<< HEAD
	help_label.text += "WASD/SETAS mover  •  SHIFT correr  •  ESPACO dash  •  1–7 setor  •  PgUp/PgDn proximo  •  Roda/+/- zoom"
=======
	help_label.text += "WASD/SETAS mover  •  SHIFT correr  •  ESPACO dash  •  1–7 setor  •  PgUp/PgDn proximo  •  Roda/+/- zoom"
>>>>>>> d8e6de3 (Adiciona exportacao completa dos objetos PixelLab)

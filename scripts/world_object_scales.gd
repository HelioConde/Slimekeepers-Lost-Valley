extends RefCounted
## Fonte unica de proporcoes do mundo e do catalogo (player visual_scale = 0.40).
## Tamanhos das arvores em pe foram preservados das capturas aprovadas.
const REFERENCE_PLAYER_HEIGHT: float = 42.0
const ROOT: String = "res://sprites/objects/pixellab_exports"
const TILE_PIXELS: float = 32.0
const TREE_FRAME_WIDTH: float = 142.0
const TREE_FRAME_HEIGHT: float = 102.0
const TREE_MAX_SCALE: float = 1.5

static func _has(name: String, keys: Array) -> bool:
	for key in keys:
		if name.contains(String(key)):
			return true
	return false

static func is_standing_tree(id: String) -> bool:
	var n: String = id.to_lower()
	if _has(n, ["stump", "log", "fallen", "trunk", "firewood", "branch", "house", "roof", "woodpile"]):
		return false
	return _has(n, ["tree", "oak", "pine", "palm", "willow", "birch", "spruce", "fir_"])

## Altura maxima de cada grupo em proporcao ao personagem.
## Ordem dos testes importa: grupos especificos antes dos genericos.
static func height_ratio(id: String) -> float:
	var n: String = id.to_lower()
	if _has(n, ["fallen_log", "fallen_trunk", "fallen_tree", "timber_log", "firewood", "woodpile"]):
		return 0.37
	if _has(n, ["stump", "tree_stump", "trunk", "log", "branch"]):
		return 0.43
	if _has(n, ["farm_plot_ground", "tilled_soil", "soil_patch", "dirt_patch", "ground_v2"]):
		return 0.29
	if _has(n, ["farm_plot", "planting_bed", "garden_bed", "raised_bed"]):
		return 0.37
	if _has(n, ["crop_growth", "crop_stage", "seedling", "sprout", "seed_", "seedbed"]):
		return 0.27
	if _has(n, ["crop", "wheat", "corn", "pumpkin", "vegetable", "fruit_bush"]):
		return 0.38
	if _has(n, ["wildflower", "flower", "grass", "fern", "weed", "herb"]):
		return 0.40
	if _has(n, ["mushroom", "fungus"]):
		return 0.34
	if _has(n, ["bush_small", "shrub_small", "flower_bush"]):
		return 0.46
	if _has(n, ["bush_large", "shrub_large", "hedge_large"]):
		return 0.58
	if _has(n, ["bush", "shrub", "hedge", "plant"]):
		return 0.52
	if _has(n, ["campfire", "bonfire", "firepit", "fire_place"]):
		return 0.42
	if _has(n, ["flame", "fireball", "smoke", "spark"]):
		return 0.40
	if _has(n, ["rock_small", "pebble", "gem_small", "ore_small"]):
		return 0.44
	if _has(n, ["rock_large", "boulder", "crystal_large"]):
		return 0.82
	if _has(n, ["copper_ore", "iron_ore", "ore_", "mineral"]):
		return 0.57
	if _has(n, ["magic_crystal", "crystal", "gem"]):
		return 0.65
	if _has(n, ["stone_ruins", "ruins_small", "ruin_floor", "rubble"]):
		return 0.70
	if _has(n, ["rock", "stone"]):
		return 0.60
	if _has(n, ["storage_crate", "crate", "box", "chest"]):
		return 0.52
	if _has(n, ["barrel", "bucket", "pot"]):
		return 0.50
	if _has(n, ["sign", "lantern"]):
		return 0.50
	if _has(n, ["fence", "wooden_bridge", "bridge"]):
		return 0.58
	if _has(n, ["bench", "chair", "table", "cart", "workbench"]):
		return 0.57
	if _has(n, ["furnace", "water_well", "well"]):
		return 0.84
	if _has(n, ["house_floor", "floor", "tile", "path", "cobble"]):
		return 0.32
	if _has(n, ["house_window", "window"]):
		return 0.53
	if _has(n, ["house_door", "door", "gate"]):
		return 0.84
	if _has(n, ["house_wall", "house_roof", "roof", "wall"]):
		return 0.50
	if _has(n, ["house", "building", "shed"]):
		return 1.90
	if _has(n, ["ancient_statue", "statue", "totem", "monument"]):
		return 1.75
	if _has(n, ["portal"]):
		return 1.25
	if _has(n, ["altar", "ruin", "shrine", "temple"]):
		return 1.05
	return 0.67

static func is_modular_tile(id: String) -> bool:
	return _has(id.to_lower(), ["house_floor", "house_wall", "house_roof", "floor_tile", "wall_tile", "roof_tile"])

static func width_ratio(id: String) -> float:
	var n: String = id.to_lower()
	if _has(n, ["fallen_log", "fallen_trunk", "fallen_tree", "timber_log", "firewood", "woodpile"]):
		return 2.75
	if _has(n, ["farm_plot", "soil", "floor", "ground", "crop"]):
		return 2.0
	if _has(n, ["bridge", "fence", "wall", "roof", "house", "bench", "table"]):
		return 2.55
	if _has(n, ["bush", "shrub", "flower", "grass", "plant", "campfire", "rock"]):
		return 1.85
	return 1.95

static func visible_rect(texture: Texture2D) -> Rect2i:
	if texture == null:
		return Rect2i()
	var size: Vector2 = texture.get_size()
	var fallback := Rect2i(0, 0, int(size.x), int(size.y))
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return fallback
	var used: Rect2i = image.get_used_rect()
	return fallback if used.size == Vector2i.ZERO else used

static func anchor_offset(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var tex_size: Vector2 = texture.get_size()
	var rect: Rect2i = visible_rect(texture)
	var center_x: float = float(rect.position.x) + float(rect.size.x) * 0.5
	return Vector2(tex_size.x * 0.5 - center_x, tex_size.y * 0.5 - float(rect.end.y))

## Escala em pixels de mundo, independente da camera ou do mapa.
static func scale_for(id: String, texture: Texture2D, player_height: float = REFERENCE_PLAYER_HEIGHT) -> float:
	if texture == null:
		return 1.0
	var size: Vector2 = texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return 1.0
	if is_standing_tree(id):
		return minf(TREE_MAX_SCALE, minf(TREE_FRAME_WIDTH / size.x, TREE_FRAME_HEIGHT / size.y))
	if is_modular_tile(id):
		# Pecas de edificacao devem alinhar no grid 32x32; nao encolher por altura do jogador.
		return TILE_PIXELS / maxf(size.x, size.y)
	var visible: Rect2i = visible_rect(texture)
	var budget_height: float = player_height * height_ratio(id)
	var budget_width: float = budget_height * width_ratio(id)
	var height_scale: float = budget_height / maxf(1.0, float(visible.size.y))
	var width_scale: float = budget_width / maxf(1.0, float(visible.size.x))
	return clampf(minf(height_scale, width_scale), 0.03, 2.0)

static func find_file(folder: String, extension: String) -> String:
	var files: PackedStringArray = DirAccess.get_files_at(folder)
	files.sort()
	for filename in files:
		if filename.to_lower().ends_with("." + extension):
			return folder.path_join(filename)
	return ""

static func preview_texture(folder: String) -> Texture2D:
	if not DirAccess.dir_exists_absolute(folder):
		return null
	var png: String = find_file(folder, "png")
	if png.is_empty():
		return null
	var atlas: Texture2D = load(png) as Texture2D
	if atlas == null:
		return null
	var json_path: String = find_file(folder, "json")
	if json_path.is_empty():
		return atlas
	var f: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if f == null:
		return atlas
	var payload: Variant = JSON.parse_string(f.get_as_text())
	if not (payload is Dictionary):
		return atlas
	var metadata: Dictionary = payload
	var sheet: Dictionary = metadata.get("spritesheet", {})
	var cell: Dictionary = sheet.get("cell_size", {})
	var cw: int = int(cell.get("width", 0))
	var ch: int = int(cell.get("height", 0))
	if cw <= 0 or ch <= 0 or cw > atlas.get_width() or ch > atlas.get_height():
		return atlas
	if cw == atlas.get_width() and ch == atlas.get_height():
		return atlas
	var first_cell := AtlasTexture.new()
	first_cell.atlas = atlas
	first_cell.region = Rect2(0.0, 0.0, float(cw), float(ch))
	return first_cell

static func folder_path(folder_or_id: String) -> String:
	if folder_or_id.begins_with("res://"):
		return folder_or_id
	return ROOT.path_join(folder_or_id)

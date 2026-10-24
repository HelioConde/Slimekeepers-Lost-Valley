extends RefCounted
## Tamanho unico PixelLab: catalogo, mundo e editor usam estas regras.
const REFERENCE_PLAYER_HEIGHT: float = 42.0 # Player visual_scale=0.40
const ROOT: String = "res://sprites/objects/pixellab_exports"
const TILE_PIXELS: float = 32.0

static func match_any(n: String, keywords: Array[String]) -> bool:
	for k in keywords:
		if n.contains(k):
			return true
	return false

static func is_standing_tree(id: String) -> bool:
	var n: String = id.to_lower()
	if match_any(n, ["stump", "log", "fallen", "firewood", "branch", "house", "roof", "woodpile"]):
		return false
	return match_any(n, ["tree", "oak", "pine", "palm", "willow", "birch", "spruce", "fir_"])

static func height_ratio(id: String) -> float:
	var n: String = id.to_lower()
	# Ordem especifica antes de generica.
	if match_any(n, ["fallen_log", "fallen_trunk", "fallen_tree", "timber_log", "woodpile", "firewood"]):
		return 0.37
	if match_any(n, ["tree_stump", "stump", "trunk", "branch"]):
		return 0.43
	if match_any(n, ["farm_plot_ground", "tilled_soil", "soil_patch", "dirt_patch", "ground_v2"]):
		return 0.29
	if match_any(n, ["farm_plot", "planting_bed", "garden_bed"]):
		return 0.37
	if match_any(n, ["crop_growth", "crop_stage", "seedling", "sprout", "seed_"]):
		return 0.27
	if match_any(n, ["mushroom", "fungus"]):
		return 0.34
	if match_any(n, ["wildflower", "flower", "grass", "fern", "weed", "herb"]):
		return 0.40
	if match_any(n, ["bush_small", "shrub_small"]):
		return 0.46
	if match_any(n, ["bush_large", "shrub_large", "hedge_large"]):
		return 0.58
	if match_any(n, ["bush", "shrub", "plant", "crop"]):
		return 0.52
	if match_any(n, ["campfire", "firepit", "bonfire"]):
		return 0.42
	if match_any(n, ["fireball", "flame", "smoke", "spark"]):
		return 0.40
	if match_any(n, ["storage_crate", "crate", "box"]):
		return 0.52
	if match_any(n, ["chest"]):
		return 0.53
	if match_any(n, ["barrel"]):
		return 0.50
	if match_any(n, ["workbench", "bench", "chair", "table"]):
		return 0.56
	if match_any(n, ["fence", "bridge", "cart"]):
		return 0.58
	if match_any(n, ["sign"]):
		return 0.50
	if match_any(n, ["rock_small", "pebble"]):
		return 0.44
	if match_any(n, ["rock_large", "boulder"]):
		return 0.81
	if match_any(n, ["magic_crystal", "crystal", "gem"]):
		return 0.65
	if match_any(n, ["ore", "rock", "stone", "mineral"]):
		return 0.57
	if match_any(n, ["furnace", "well"]):
		return 0.84
	if match_any(n, ["door", "gate"]):
		return 0.84
	if match_any(n, ["window"]):
		return 0.53
	if match_any(n, ["portal"]):
		return 1.25
	if match_any(n, ["statue", "totem", "monument"]):
		return 1.75
	if match_any(n, ["stone_ruins", "ruins", "ruin"]):
		return 0.70
	if match_any(n, ["altar", "shrine", "temple"]):
		return 1.05
	if match_any(n, ["house", "building", "shed"]):
		return 1.90
	return 0.62

static func is_modular_tile(id: String) -> bool:
	return match_any(id.to_lower(), ["house_floor", "house_wall", "house_roof", "floor_tile", "wall_tile", "roof_tile"])

static func width_ratio(id: String) -> float:
	var n: String = id.to_lower()
	if match_any(n, ["fallen_log", "fallen_trunk", "woodpile"]):
		return 2.75
	if match_any(n, ["farm_plot", "soil", "floor", "ground", "crop"]):
		return 2.0
	if match_any(n, ["bridge", "fence", "wall", "roof", "house", "bench"]):
		return 2.55
	return 1.95

static func visible_rect(texture: Texture2D) -> Rect2i:
	if texture == null:
		return Rect2i()
	var size: Vector2 = texture.get_size()
	var fallback := Rect2i(0, 0, int(size.x), int(size.y))
	var img: Image = texture.get_image()
	if img == null or img.is_empty():
		return fallback
	var used: Rect2i = img.get_used_rect()
	return fallback if used.size == Vector2i.ZERO else used

static func scale_for(id: String, texture: Texture2D, player_h: float = REFERENCE_PLAYER_HEIGHT) -> float:
	if texture == null:
		return 1.0
	var size: Vector2 = texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return 1.0
	if is_standing_tree(id):
		# Mantem as arvores exatamente como eram na vitrine.
		return minf(1.5, minf(142.0 / size.x, 102.0 / size.y))
	if is_modular_tile(id):
		# Modulos de construcao respeitam o tile 32px.
		return TILE_PIXELS / maxf(size.x, size.y)
	var used: Rect2i = visible_rect(texture)
	var h: float = player_h * height_ratio(id)
	var w: float = h * width_ratio(id)
	return clampf(minf(h / maxf(1.0, float(used.size.y)), w / maxf(1.0, float(used.size.x))), 0.03, 2.0)

static func anchor_offset(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var size: Vector2 = texture.get_size()
	var area: Rect2i = visible_rect(texture)
	var center: float = float(area.position.x) + float(area.size.x) * 0.5
	return Vector2(size.x * 0.5 - center, size.y * 0.5 - float(area.end.y))

static func find_file(folder: String, ext: String) -> String:
	if not DirAccess.dir_exists_absolute(folder):
		return ""
	var files: PackedStringArray = DirAccess.get_files_at(folder)
	files.sort()
	for name in files:
		if name.to_lower().ends_with("." + ext):
			return folder.path_join(name)
	return ""

static func preview_texture(folder: String) -> Texture2D:
	var png: String = find_file(folder, "png")
	if png.is_empty():
		return null
	var atlas: Texture2D = load(png) as Texture2D
	if atlas == null:
		return null
	var path: String = find_file(folder, "json")
	if path.is_empty():
		return atlas
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return atlas
	var meta_value: Variant = JSON.parse_string(file.get_as_text())
	if not (meta_value is Dictionary):
		return atlas
	var meta: Dictionary = meta_value
	var sheet: Dictionary = meta.get("spritesheet", {})
	var cell: Dictionary = sheet.get("cell_size", {})
	var cw: int = int(cell.get("width", 0))
	var ch: int = int(cell.get("height", 0))
	if cw <= 0 or ch <= 0 or cw > int(atlas.get_width()) or ch > int(atlas.get_height()):
		return atlas
	if cw == int(atlas.get_width()) and ch == int(atlas.get_height()):
		return atlas
	var preview := AtlasTexture.new()
	preview.atlas = atlas
	preview.region = Rect2(0, 0, cw, ch)
	return preview

static func folder_path(id: String) -> String:
	return id if id.begins_with("res://") else ROOT.path_join(id)

extends RefCounted
## Chão V8: grama pintada e chão de mata (musgo, folhas) com transições Wang
## desenhadas pelo PixelLab, sem repintar o mapa. O tilemap Ground continua com
## o tile único de grama; o shader escolhe, por célula, o tile Wang pelos quatro
## cantos de uma máscara:
## - R: canto com árvores em volta = chão de mata (0), área aberta = grama (1);
## - G: terra gasta (1). Vem dos traçados de trilha, mas num mundo sem gente as
##   trilhas são passagens de bicho quase engolidas pela grama: só o miolo do
##   traçado, e só em manchas onde o ruído deixa.
## Os polígonos antigos de trilha e de grama saem de cena.

const WANG := preload("res://assets/tilesets/v8/forest_grass_wang.png")
const DIRT_WANG := preload("res://assets/tilesets/v8/dirt_grass_wang.png")
const TILE := 32.0
const FOREST_RADIUS := 84.0  # raio em volta de um canto onde se contam troncos
const FOREST_TREES := 2      # a partir de quantos troncos o canto é chão de mata
const TRAIL_CORE := 6        # de 8 vizinhos, quantos precisam estar no traçado
const TRAIL_WEAR := -0.15    # limiar do ruído (maior = menos terra)


## Máscara de cantos (R). `open_test(local) -> bool` força grama em clareiras.
static func corner_mask(size_cells: Vector2i, tree_feet: Array[Vector2], open_test: Callable, min_trees: int = FOREST_TREES) -> Image:
	var buckets := {}
	for foot in tree_feet:
		var key := Vector2i(foot / FOREST_RADIUS)
		if not buckets.has(key): buckets[key] = []
		buckets[key].append(foot)
	var image := Image.create(size_cells.x + 1, size_cells.y + 1, false, Image.FORMAT_L8)
	for y in size_cells.y + 1:
		for x in size_cells.x + 1:
			var at := Vector2(x, y) * TILE
			var grass := true
			if not (open_test.is_valid() and open_test.call(at)):
				var key := Vector2i(at / FOREST_RADIUS)
				var count := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						for foot: Vector2 in buckets.get(key + Vector2i(dx, dy), []):
							if foot.distance_to(at) < FOREST_RADIUS: count += 1
				grass = count < min_trees
			image.set_pixel(x, y, Color.WHITE if grass else Color.BLACK)
	return smooth(smooth(image))


## Filtro de maioria 3x3: tira ilhas de um canto (grama solta no meio da mata e
## vice-versa), que virariam pintas no chão.
static func smooth(image: Image) -> Image:
	var out := image.duplicate() as Image
	for y in range(1, image.get_height() - 1):
		for x in range(1, image.get_width() - 1):
			var grass := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if image.get_pixel(x + dx, y + dy).r > 0.5: grass += 1
			out.set_pixel(x, y, Color.WHITE if grass >= 5 else Color.BLACK)
	return out


## Canal G = 1 onde o chão é de terra gasta; R fica intacto. Devolve RGB8.
static func add_trail_wear(mask: Image, trails: Array[PackedVector2Array], seed: int = 4121) -> Image:
	var out := mask.duplicate() as Image
	out.convert(Image.FORMAT_RGB8)
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			out.set_pixel(x, y, Color(c.r, 0.0, 0.0))
	if trails.is_empty(): return out
	var w := out.get_width()
	var h := out.get_height()
	var inside := PackedByteArray()
	inside.resize(w * h)
	for points in trails:
		if points.size() < 3: continue
		var box := Rect2(points[0], Vector2.ZERO)
		for point in points: box = box.expand(point)
		var from := Vector2i((box.position / TILE).floor()).clamp(Vector2i.ZERO, Vector2i(w - 1, h - 1))
		var to := Vector2i((box.end / TILE).ceil()).clamp(Vector2i.ZERO, Vector2i(w - 1, h - 1))
		for y in range(from.y, to.y + 1):
			for x in range(from.x, to.x + 1):
				if inside[y * w + x] == 0 and Geometry2D.is_point_in_polygon(Vector2(x, y) * TILE, points):
					inside[y * w + x] = 1
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.09
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if inside[y * w + x] == 0: continue
			var around := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if (dx != 0 or dy != 0) and inside[(y + dy) * w + x + dx] == 1: around += 1
			if around >= TRAIL_CORE and noise.get_noise_2d(x, y) > TRAIL_WEAR:
				out.set_pixel(x, y, Color(out.get_pixel(x, y).r, 1.0, 0.0))
	return out


static func apply(region: Node2D, tree_groups: Array, open_test: Callable, min_trees: int = FOREST_TREES) -> void:
	var ground := region.get_node_or_null("Ground") as TileMapLayer
	if ground == null: return
	var material := ground.material as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = preload("res://scripts/world/forest_ground.gdshader")
	var feet: Array[Vector2] = []
	for group: Node in tree_groups:
		if group == null: continue
		for prop in group.get_children():
			var sprite := prop.get_node_or_null("Sprite") as Sprite2D if prop is Node2D else null
			var path := sprite.texture.resource_path.to_lower() if sprite and sprite.texture else ""
			if prop.visible and ("oak" in path or "pine" in path or "tree" in path):
				feet.append((prop as Node2D).global_position - ground.global_position)
	# Polígonos texturizados de chão: os de terra viram traçado de trilha; todos saem.
	var trails: Array[PackedVector2Array] = []
	for surface in region.find_children("*", "Polygon2D", true, false):
		var surface_material := (surface as Polygon2D).material as ShaderMaterial
		if surface_material == null or surface_material.get_shader_parameter("terrain_atlas") == null: continue
		var origin: Vector2 = surface_material.get_shader_parameter("atlas_origin")
		if origin != Vector2.ZERO:
			var polygon := surface as Polygon2D
			var points := PackedVector2Array()
			for point in polygon.polygon:
				points.append(polygon.global_transform * point - ground.global_position)
			trails.append(points)
		surface.visible = false
	var opening := func(at: Vector2) -> bool: return open_test.is_valid() and open_test.call(at + ground.global_position)
	var mask := add_trail_wear(corner_mask(ground.get_used_rect().end, feet, opening, min_trees), trails)
	material = material.duplicate() as ShaderMaterial
	material.set_shader_parameter("wang_atlas", WANG)
	material.set_shader_parameter("dirt_wang_atlas", DIRT_WANG)
	var mask_texture := ImageTexture.create_from_image(mask)
	material.set_shader_parameter("corner_mask", mask_texture)
	material.set_shader_parameter("corner_mask_soft", mask_texture)
	material.set_shader_parameter("use_wang", 1.0)
	material.set_shader_parameter("canopy_shade", 1.0)
	ground.material = material
	ground.add_to_group("v8_ground")
	region.set_meta("ground_corner_mask", mask)
	# Margens de água (Vale): a mesma grama pintada do chão.
	var banks := region.get_node_or_null("WaterBankTiles") as TileMapLayer
	if banks and banks.material is ShaderMaterial:
		banks.material.set_shader_parameter("grass_atlas", WANG)
		banks.material.set_shader_parameter("grass_origin", Vector2(96, 96))
		banks.material.set_shader_parameter("grass_tile", 1.0)
	var elevations := region.get_node_or_null("Elevations")
	if elevations:
		for level in elevations.get_children():
			if level is CanvasItem and level.material is ShaderMaterial:
				level.material.set_shader_parameter("grass_atlas", WANG)
				level.material.set_shader_parameter("use_grass", 1.0)

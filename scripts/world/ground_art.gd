extends RefCounted
## Chão V8: grama pintada e chão de mata (musgo, folhas) com transições Wang
## desenhadas pelo PixelLab, sem repintar o mapa. O tilemap Ground continua com
## o tile único de grama; o shader escolhe, por célula, o tile Wang pelos quatro
## cantos de uma máscara: canto com árvores em volta = chão de mata, canto em
## área aberta = grama. Manchas de terra e trilhas (polígonos) ganham a terra nova.

const WANG := preload("res://assets/tilesets/v8/forest_grass_wang.png")
const DIRT := preload("res://assets/tilesets/v8/dirt_tile.png")
const TILE := 32.0
const FOREST_RADIUS := 84.0  # raio em volta de um canto onde se contam troncos
const FOREST_TREES := 2      # a partir de quantos troncos o canto é chão de mata
const OPEN_MARGIN := 24.0


## Máscara de cantos: 1 = grama, 0 = chão de mata. `open_test(global) -> bool`
## força grama em clareiras e áreas de interesse.
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
	var used := ground.get_used_rect()
	var size := used.end
	var opening := func(at: Vector2) -> bool: return open_test.is_valid() and open_test.call(at + ground.global_position)
	var mask := corner_mask(size, feet, opening, min_trees)
	material = material.duplicate() as ShaderMaterial
	material.set_shader_parameter("wang_atlas", WANG)
	material.set_shader_parameter("corner_mask", ImageTexture.create_from_image(mask))
	material.set_shader_parameter("use_wang", 1.0)
	ground.material = material
	ground.add_to_group("v8_ground")
	region.set_meta("ground_corner_mask", mask)
	# Manchas de terra e trilhas: terra nova; polígonos "de grama" deixam o chão Wang aparecer.
	for surface in region.find_children("*", "Polygon2D", true, false):
		var surface_material := (surface as Polygon2D).material as ShaderMaterial
		if surface_material == null or surface_material.get_shader_parameter("terrain_atlas") == null: continue
		var origin: Vector2 = surface_material.get_shader_parameter("atlas_origin")
		if origin == Vector2.ZERO:
			surface.visible = false
		else:
			surface_material.set_shader_parameter("dirt_texture", DIRT)
			surface_material.set_shader_parameter("use_dirt_texture", 1.0)

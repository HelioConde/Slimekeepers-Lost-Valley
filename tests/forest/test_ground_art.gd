extends GdUnitTestSuite

## Chão V8: máscara de cantos (mata × grama) que escolhe os tiles Wang do PixelLab.

const Art := preload("res://scripts/world/ground_art.gd")


func _grass(mask: Image, x: int, y: int) -> bool:
	return mask.get_pixel(x, y).r > 0.5


func test_dense_trees_make_forest_floor_and_open_areas_stay_grass() -> void:
	var feet: Array[Vector2] = []
	# Mata fechada em volta de (320, 320).
	for i in 12:
		feet.append(Vector2(320, 320) + Vector2.from_angle(i * TAU / 12.0) * 40.0)
	var mask := Art.corner_mask(Vector2i(30, 30), feet, Callable())
	assert_bool(_grass(mask, 10, 10)).is_false()   # (320, 320): chão de mata
	assert_bool(_grass(mask, 25, 25)).is_true()    # longe das árvores: grama
	# Uma área aberta declarada (clareira) vence a densidade de árvores.
	var open := func(at: Vector2) -> bool: return at.distance_to(Vector2(320, 320)) < 100.0
	var opened := Art.corner_mask(Vector2i(30, 30), feet, open)
	assert_bool(_grass(opened, 10, 10)).is_true()


func test_single_tree_counts_only_when_asked() -> void:
	var feet: Array[Vector2] = [Vector2(320, 320)]
	assert_bool(_grass(Art.corner_mask(Vector2i(20, 20), feet, Callable()), 10, 10)).is_true()
	assert_bool(_grass(Art.corner_mask(Vector2i(20, 20), feet, Callable(), 1), 10, 10)).is_false()


func test_smoothing_removes_one_corner_islands() -> void:
	var image := Image.create(9, 9, false, Image.FORMAT_L8)
	image.fill(Color.BLACK)
	image.set_pixel(4, 4, Color.WHITE)  # um canto de grama solto no meio da mata
	var smooth := Art.smooth(image)
	assert_bool(_grass(smooth, 4, 4)).is_false()


func test_wang_atlas_is_canonical_full_tiles_at_corners() -> void:
	var atlas: Image = Art.WANG.get_image()
	assert_vector(Vector2(atlas.get_size())).is_equal(Vector2(128, 128))
	# Índice 0 (só mata, canto superior esquerdo) é escuro; 15 (só grama) é claro.
	var forest := atlas.get_region(Rect2i(0, 0, 32, 32))
	var grass := atlas.get_region(Rect2i(96, 96, 32, 32))
	assert_float(_mean_luma(forest)).is_less(_mean_luma(grass) - 0.15)


func _mean_luma(image: Image) -> float:
	var total := 0.0
	for y in image.get_height():
		for x in image.get_width():
			total += image.get_pixel(x, y).get_luminance()
	return total / (image.get_width() * image.get_height())

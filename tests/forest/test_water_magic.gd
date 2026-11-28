extends GdUnitTestSuite

## Água encantada (V11): máscara de distância à margem da geometria real.

const Magic := preload("res://scripts/world/water_magic.gd")


func test_edge_distance_zero_outside_grows_inside() -> void:
	var water: Polygon2D = auto_free(Polygon2D.new())
	water.polygon = PackedVector2Array([Vector2(0, 0), Vector2(200, 0), Vector2(200, 100), Vector2(0, 100)])
	var map: Dictionary = Magic.edge_map(water)
	var image: Image = map.image
	var rect: Rect2 = map.rect
	var at := func(world: Vector2) -> float:
		var c := ((world - rect.position) / Magic.CELL).floor()
		return image.get_pixel(int(c.x), int(c.y)).r * Magic.EDGE_SCALE
	assert_float(at.call(Vector2(-4, 50))).is_equal(0.0)          # fora
	assert_float(at.call(Vector2(6, 50))).is_between(2.0, 12.0)    # colado à margem
	assert_float(at.call(Vector2(100, 50))).is_greater(40.0)       # centro
	assert_float(at.call(Vector2(100, 50))).is_greater(at.call(Vector2(100, 20)))


func test_overlay_is_additive_and_world_anchored() -> void:
	var water: Polygon2D = auto_free(Polygon2D.new())
	water.polygon = PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)])
	var overlay := Magic.make_overlay(water, Vector2(0, 1))
	var code: String = (overlay.material as ShaderMaterial).shader.code
	assert_bool(code.contains("blend_add")).is_true()
	assert_bool(code.contains("MODEL_MATRIX")).is_true()
	assert_bool(code.contains("SCREEN_UV")).is_false()
	assert_bool(overlay.has_meta("no_shadow")).is_true()

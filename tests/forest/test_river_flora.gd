extends GdUnitTestSuite

## Vegetação aquática do rio (V11): juncos na beira, vitórias-régias na água rasa,
## nada sobre pontes, posições determinísticas.

const Flora := preload("res://scripts/world/river_flora.gd")


func _build() -> Node2D:
	var root: Node2D = auto_free(Node2D.new())
	add_child(root)
	var water := Polygon2D.new()
	water.polygon = PackedVector2Array([Vector2(0, 0), Vector2(600, 0), Vector2(600, 2000), Vector2(0, 2000)])
	root.add_child(water)
	var deco := Node2D.new()
	var wdeco := Node2D.new()
	root.add_child(deco)
	root.add_child(wdeco)
	var flora: Node2D = Flora.new()
	flora.setup([water], [Rect2(0, 900, 600, 100)], deco, wdeco)
	root.add_child(flora)
	return flora


func test_reeds_on_shore_lilies_inside_and_none_on_bridge() -> void:
	var flora := _build()
	var reeds: Array = flora.placed.filter(func(p): return p.kind == "reeds")
	var lilies: Array = flora.placed.filter(func(p): return p.kind == "lily")
	assert_int(reeds.size()).is_greater(3)
	assert_int(lilies.size()).is_greater(0)
	for p in flora.placed:
		var at: Vector2 = p.at
		assert_bool(Rect2(0, 900, 600, 100).grow(36.0).has_point(at)).is_false()
	for p in reeds:
		var at: Vector2 = p.at
		assert_bool(at.x < Flora.SHORE or at.x > 600.0 - Flora.SHORE or at.y < Flora.SHORE or at.y > 2000.0 - Flora.SHORE).is_true()


func test_deterministic() -> void:
	var a := _build()
	var b := _build()
	assert_int(a.placed.size()).is_equal(b.placed.size())
	for i in a.placed.size(): assert_vector(a.placed[i].at).is_equal(b.placed[i].at)

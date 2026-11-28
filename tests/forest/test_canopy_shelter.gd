extends GdUnitTestSuite

## Árvores protegidas (muitas vizinhas) ficam mais escuras e frias; expostas
## mantêm a luz do sol.

const Living := preload("res://scripts/world/living_region.gd")


func _tree(parent: Node2D, at: Vector2) -> Sprite2D:
	var holder := Node2D.new()
	holder.position = at
	parent.add_child(holder)
	var sprite := Sprite2D.new()
	holder.add_child(sprite)
	return sprite


func test_sheltered_tree_is_darker_and_cooler_than_exposed() -> void:
	var root: Node2D = auto_free(Node2D.new())
	add_child(root)
	var sprites: Array[Sprite2D] = []
	var lonely := _tree(root, Vector2(-2000, 0))
	sprites.append(lonely)
	var center := _tree(root, Vector2(0, 0))
	sprites.append(center)
	for i in 8:
		sprites.append(_tree(root, Vector2.from_angle(i * TAU / 8.0) * 70.0))
	Living.shade_sheltered_trees(sprites)
	assert_float(lonely.modulate.r).is_equal(1.0)
	assert_float(center.modulate.r).is_less(0.95)
	assert_float(center.modulate.b).is_greater(center.modulate.r)


func test_shelter_factor_is_bounded() -> void:
	assert_float(Living.shelter_factor(0)).is_equal(0.0)
	assert_float(Living.shelter_factor(30)).is_equal(1.0)

extends GdUnitTestSuite
## Queda da árvore (playtest ID 29): cortando pela esquerda cai à direita e vice-versa;
## por cima ou por baixo, sorteia entre os dois lados.

const Chop := preload("res://scripts/world/choppable_trees.gd")


func test_fall_side_is_opposite_to_the_cutter() -> void:
	var tree := Vector2(500, 500)
	assert_int(Chop.fall_side(tree, Vector2(470, 505))).is_equal(1)   # pela esquerda → direita
	assert_int(Chop.fall_side(tree, Vector2(530, 505))).is_equal(-1)  # pela direita → esquerda
	var seen := {}
	for i in 60: seen[Chop.fall_side(tree, Vector2(500, 540))] = true  # por baixo: sorteio
	assert_bool(seen.has(1) and seen.has(-1)).is_true()

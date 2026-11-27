extends GdUnitTestSuite
## Golpe de outro jogador (playtest ID 36): balanço e queda aparecem para todos.

const Chop := preload("res://scripts/world/choppable_trees.gd")


func _forest() -> Array:
	var root: Node2D = auto_free(Node2D.new())
	add_child(root)
	var group := Node2D.new()
	group.name = "Trees"
	root.add_child(group)
	var tree := Node2D.new()
	tree.name = "Oak"
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.GREEN)
	sprite.texture = ImageTexture.create_from_image(image)
	tree.add_child(sprite)
	group.add_child(tree)
	var chop: Node = Chop.new()
	root.add_child(chop)
	chop.setup([group], func(_at: Vector2) -> bool: return false, "", true)
	return [chop, tree, group]


func test_remote_final_hit_makes_the_tree_fall() -> void:
	var parts := _forest()
	var key: String = parts[0].trees.keys()[0]
	parts[0].remote_fx({"t": "chop_fx", "key": key, "kind": "tree", "side": -1})
	assert_bool((parts[1].get_node("Sprite") as Sprite2D).visible).is_false()
	assert_object(parts[2].get_node_or_null("Falling")).is_not_null()


func test_remote_hit_only_shakes_and_unknown_tree_is_ignored() -> void:
	var parts := _forest()
	var key: String = parts[0].trees.keys()[0]
	parts[0].remote_fx({"t": "chop_fx", "key": key, "kind": "tree", "side": 0})
	assert_bool((parts[1].get_node("Sprite") as Sprite2D).visible).is_true()
	assert_object(parts[2].get_node_or_null("Falling")).is_null()
	parts[0].remote_fx({"t": "chop_fx", "key": "OutroMapa/Pinheiro", "kind": "tree", "side": 1})
	assert_object(parts[2].get_node_or_null("Falling")).is_null()

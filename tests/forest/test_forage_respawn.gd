extends GdUnitTestSuite
## Reposição por tipo (playtest ID 34): mato 1 dia, graveto 2, pedrinha 4.

const Forage := preload("res://scripts/world/forage_spots.gd")


func after_test() -> void:
	if get_tree().has_meta(Forage.FORAGE_KEY): get_tree().remove_meta(Forage.FORAGE_KEY)


func test_each_kind_returns_after_its_days() -> void:
	var forage: Node2D = auto_free(Forage.new())
	add_child(forage)
	for item in ["fibra", "graveto", "pedra_pequena"]:
		forage._add_spot("t_" + item, item, Vector2.ZERO)
	for spot: Dictionary in forage.spots:
		forage.take(spot, 10)
	var tree := get_tree()
	assert_bool(Forage.is_taken(tree, "t_fibra", 10)).is_true()
	assert_bool(Forage.is_taken(tree, "t_fibra", 11)).is_false()
	assert_bool(Forage.is_taken(tree, "t_graveto", 11)).is_true()
	assert_bool(Forage.is_taken(tree, "t_graveto", 12)).is_false()
	assert_bool(Forage.is_taken(tree, "t_pedra_pequena", 13)).is_true()
	assert_bool(Forage.is_taken(tree, "t_pedra_pequena", 14)).is_false()

extends GdUnitTestSuite
## Benchmark 2026-11-27: o [F] pegava o mato (fibra) em vez do graveto ao lado. Graveto e
## pedrinha alcançam mais longe e ganham do mato a distâncias parecidas; o alvo acende.

const Forage := preload("res://scripts/world/forage_spots.gd")


func after_test() -> void:
	if get_tree().has_meta(Forage.FORAGE_KEY): get_tree().remove_meta(Forage.FORAGE_KEY)


func _forage() -> Node2D:
	var forage: Node2D = auto_free(Forage.new())
	add_child(forage)
	return forage


func test_twig_wins_over_slightly_closer_weed() -> void:
	var forage := _forage()
	forage._add_spot("mato", "fibra", Vector2(20, 0))
	forage._add_spot("galho", "graveto", Vector2(0, 30))
	assert_str(str(forage.nearest(Vector2.ZERO, 1).get("item", ""))).is_equal("graveto")


func test_weed_still_taken_when_alone_or_much_closer() -> void:
	var forage := _forage()
	forage._add_spot("mato", "fibra", Vector2(5, 0))
	forage._add_spot("galho", "graveto", Vector2(0, 45))
	assert_str(str(forage.nearest(Vector2.ZERO, 1).get("item", ""))).is_equal("fibra")
	var only_weed := _forage()
	only_weed._add_spot("mato", "fibra", Vector2(30, 0))
	assert_str(str(only_weed.nearest(Vector2.ZERO, 1).get("item", ""))).is_equal("fibra")


func test_reach_is_longer_for_small_items_than_for_weed() -> void:
	var forage := _forage()
	forage._add_spot("mato", "fibra", Vector2(40, 0))
	assert_bool(forage.nearest(Vector2.ZERO, 1).is_empty()).is_true()
	forage._add_spot("pedra", "pedra_pequena", Vector2(0, 44))
	assert_str(str(forage.nearest(Vector2.ZERO, 1).get("item", ""))).is_equal("pedra_pequena")


func test_highlight_lights_one_target_at_a_time() -> void:
	var forage := _forage()
	forage._add_spot("a", "graveto", Vector2.ZERO)
	forage._add_spot("b", "graveto", Vector2(100, 0))
	var a: Sprite2D = forage.spots[0].sprite
	var b: Sprite2D = forage.spots[1].sprite
	forage.highlight(forage.spots[0])
	assert_object(a.self_modulate).is_equal(Forage.LIT)
	forage.highlight(forage.spots[1])
	assert_object(a.self_modulate).is_equal(Color.WHITE)
	assert_object(b.self_modulate).is_equal(Forage.LIT)
	forage.highlight({})
	assert_object(b.self_modulate).is_equal(Color.WHITE)

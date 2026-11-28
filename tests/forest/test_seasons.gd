extends GdUnitTestSuite
## Estações: 28 dias cada; cultura fora da estação não cresce (nem morre).

const SEASONS := preload("res://scripts/systems/seasons.gd")
const Farm := preload("res://scripts/systems/farm_state.gd")
const F := "teste_estacao"


func before_test() -> void:
	if get_tree().has_meta(Farm.KEY): get_tree().remove_meta(Farm.KEY)


func test_season_by_day() -> void:
	assert_str(SEASONS.of(1)).is_equal("primavera")
	assert_str(SEASONS.of(28)).is_equal("primavera")
	assert_str(SEASONS.of(29)).is_equal("verao")
	assert_str(SEASONS.of(57)).is_equal("outono")
	assert_str(SEASONS.of(85)).is_equal("inverno")
	assert_str(SEASONS.of(113)).is_equal("primavera")
	assert_int(SEASONS.day_in(30)).is_equal(2)


func test_out_of_season_does_not_grow() -> void:
	var tree := get_tree()
	var cell := Vector2i(0, 0)
	preload("res://scripts/systems/forest_bag.gd").add_item(tree, "semente_beterraba", 1)
	Farm.till(tree, cell, F)
	assert_bool(Farm.plant(tree, cell, "beterraba", F)).is_true()  # outono
	Farm.water(tree, cell, F)
	Farm.advance_day(tree, 5)  # primavera
	assert_int(Farm.stage(tree, cell, F)).is_equal(0)
	assert_str(Farm.crop(tree, cell, F)).is_equal("beterraba")  # não morreu
	Farm.water(tree, cell, F)
	Farm.advance_day(tree, 60)  # outono
	assert_int(Farm.stage(tree, cell, F)).is_equal(1)

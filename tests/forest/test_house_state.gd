extends GdUnitTestSuite

## Casa construída pelo jogador: casa inicial, regras de construção, colisão.

const House := preload("res://scripts/systems/house_state.gd")


func before_test() -> void:
	if get_tree().has_meta(House.KEY): get_tree().remove_meta(House.KEY)


func test_starter_house_has_walls_door_and_bed() -> void:
	var tree := get_tree()
	var data := House.data(tree)
	assert_bool(data.wall.has(House.STARTER_DOOR)).is_false()  # porta aberta
	assert_bool(data.floor.has(House.STARTER_DOOR)).is_true()
	assert_bool(data.wall.has(Vector2i(12, 5))).is_true()
	assert_str(House.furniture_at(tree, Vector2i(14, 8))).is_equal("cama")  # cama ocupa 2 células
	assert_bool(House.is_inside(tree, Vector2i(16, 8))).is_true()
	assert_bool(House.is_inside(tree, Vector2i(30, 30))).is_false()


func test_building_rules() -> void:
	var tree := get_tree()
	assert_bool(House.place(tree, "floor", Vector2i(20, 8))).is_false()  # já tem piso (parede)
	assert_bool(House.place(tree, "floor", Vector2i(21, 8))).is_true()
	assert_bool(House.place(tree, "furniture", Vector2i(21, 8), "estante")).is_true()
	assert_bool(House.place(tree, "wall", Vector2i(21, 8))).is_false()  # móvel no lugar
	assert_bool(House.place(tree, "furniture", Vector2i(40, 40), "mesa")).is_false()  # fora do piso
	assert_bool(House.place(tree, "wall", Vector2i(22, 8), "", [Vector2i(22, 8)])).is_false()  # jogador ali
	assert_bool(House.erase(tree, "floor", Vector2i(21, 8))).is_false()  # tem móvel em cima
	assert_bool(House.erase(tree, "furniture", Vector2i(21, 8))).is_true()
	assert_bool(House.erase(tree, "floor", Vector2i(21, 8))).is_true()
	assert_bool(House.erase(tree, "wall", House.STARTER_DOOR + Vector2i(1, 0))).is_true()


func test_wall_face_below_is_solid() -> void:
	var tree := get_tree()
	var solid := House.solid_cells(tree)
	assert_bool(solid.has(Vector2i(16, 5))).is_true()  # parede norte
	assert_bool(solid.has(Vector2i(16, 6))).is_true()  # face dela, dentro da casa
	assert_bool(solid.has(House.STARTER_DOOR)).is_false()
	assert_bool(solid.has(Vector2i(16, 8))).is_false()

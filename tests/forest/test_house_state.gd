extends GdUnitTestSuite

## Casa do jogador: sem casa inicial; arrastar um retângulo constrói (custa mais
## quanto maior); só uma no jogo; mobília paga; demolir devolve tudo.

const House := preload("res://scripts/systems/house_state.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")


func before_test() -> void:
	for key in [House.KEY, Bag.INVENTORY_KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func _give(items: Dictionary) -> void:
	for item in items: Bag.add_item(get_tree(), item, int(items[item]))


func test_starts_without_house() -> void:
	assert_bool(House.exists(get_tree())).is_false()
	assert_str(House.region_of(get_tree())).is_equal("")


func test_bigger_house_costs_more() -> void:
	var small := House.rect_cost(Rect2i(0, 0, 4, 4))
	var big := House.rect_cost(Rect2i(0, 0, 8, 6))
	assert_int(int(big.madeira)).is_greater(int(small.madeira))
	assert_int(int(big.pedra_pequena)).is_greater(int(small.pedra_pequena))
	# 4×4: 11 paredes (perímetro 12 menos a porta) e 5 pisos (4 de dentro + porta).
	assert_dict(House.rect_counts(Rect2i(0, 0, 4, 4))).is_equal({"walls": 11, "floors": 5})


func test_drag_builds_walls_door_and_pays() -> void:
	var tree := get_tree()
	var rect := House.drag_rect(Vector2i(16, 10), Vector2i(10, 6))  # arrastou de baixo/direita
	assert_object(rect).is_equal(Rect2i(10, 6, 7, 5))
	assert_str(House.build(tree, "floresta", rect)).starts_with("Falta")  # sem material
	assert_bool(House.exists(tree)).is_false()
	var cost := House.rect_cost(rect)
	_give(cost)
	assert_str(House.build(tree, "floresta", rect)).is_empty()
	for item in cost: assert_int(Bag.count_item(tree, item)).is_equal(0)  # pagou tudo
	var door := House.door_of(rect)
	assert_bool(House.has(tree, "wall", door)).is_false()  # porta aberta
	assert_bool(House.has(tree, "floor", door)).is_true()
	assert_bool(House.has(tree, "wall", Vector2i(10, 6))).is_true()
	assert_bool(House.is_inside(tree, Vector2i(13, 8))).is_true()
	assert_str(House.region_of(tree)).is_equal("floresta")


func test_only_one_house_in_the_game() -> void:
	var tree := get_tree()
	_give({"madeira": 99, "pedra_pequena": 99})  # bolsa guarda até 99
	assert_str(House.build(tree, "vale", Rect2i(0, 0, 5, 5))).is_empty()
	assert_str(House.build(tree, "floresta", Rect2i(20, 20, 5, 5))).contains("já tem uma casa")
	assert_bool(House.view(tree, "floresta").floor.is_empty()).is_true()  # a Floresta não vê a casa do Vale
	assert_bool(House.view(tree, "vale").floor.is_empty()).is_false()


func test_size_limits_and_blocked_ground() -> void:
	var tree := get_tree()
	_give({"madeira": 99, "pedra_pequena": 99})
	assert_str(House.build(tree, "vale", Rect2i(0, 0, 3, 6))).contains("Pequena")
	assert_str(House.build(tree, "vale", Rect2i(0, 0, 20, 6))).contains("Grande")
	var tree_at := func(cell: Vector2i) -> bool: return cell == Vector2i(2, 2)
	assert_str(House.build(tree, "vale", Rect2i(0, 0, 5, 5), tree_at)).contains("ocupado")
	assert_str(House.build(tree, "vale", Rect2i(0, 0, 5, 5), Callable(), Vector2i(1, 1))).contains("Saia")


func test_minimum_size_refused_without_spending_and_minimum_accepted() -> void:
	var tree := get_tree()
	var stock := {"madeira": 99, "pedra_pequena": 99}
	_give(stock)
	for size in [Vector2i(4, 4), Vector2i(4, 8), Vector2i(8, 4), Vector2i(1, 1)]:
		assert_str(House.build(tree, "vale", Rect2i(Vector2i.ZERO, size))).contains("Pequena demais (mínimo 5×5)")
	assert_bool(House.exists(tree)).is_false()
	for item in stock: assert_int(Bag.count_item(tree, item)).is_equal(99)  # nada gasto
	var rect := Rect2i(Vector2i.ZERO, House.MIN_SIZE)
	assert_str(House.build(tree, "vale", rect)).is_empty()
	_give({"fibra": 6})
	# Cama 1×2 numa coluna interna e ainda sobra um corredor até a porta (meio da parede de baixo).
	assert_str(House.place_furniture(tree, Vector2i(1, 1), "cama")).is_empty()
	assert_bool(House.is_inside(tree, House.door_of(rect) + Vector2i(0, -1))).is_true()


func test_furniture_costs_and_refunds() -> void:
	var tree := get_tree()
	var rect := Rect2i(10, 6, 7, 5)
	_give(House.rect_cost(rect))
	House.build(tree, "floresta", rect)
	assert_str(House.place_furniture(tree, Vector2i(11, 7), "cama")).starts_with("Falta")
	_give(House.FURNITURE_COSTS.cama)
	assert_str(House.place_furniture(tree, Vector2i(11, 7), "cama")).is_empty()
	assert_str(House.furniture_at(tree, Vector2i(11, 8))).is_equal("cama")  # ocupa 2 células
	assert_int(Bag.count_item(tree, "madeira")).is_equal(0)
	assert_str(House.place_furniture(tree, Vector2i(40, 40), "mesa")).contains("dentro da casa")
	assert_bool(House.remove_furniture(tree, Vector2i(11, 8))).is_true()
	assert_int(Bag.count_item(tree, "madeira")).is_equal(int(House.FURNITURE_COSTS.cama.madeira))


func test_demolish_refunds_everything() -> void:
	var tree := get_tree()
	var rect := Rect2i(10, 6, 7, 5)
	var total := House.rect_cost(rect)
	_give(total)
	_give(House.FURNITURE_COSTS.mesa)
	House.build(tree, "vale", rect)
	House.place_furniture(tree, Vector2i(12, 8), "mesa")
	assert_bool(House.demolish(tree)).is_true()
	assert_bool(House.exists(tree)).is_false()
	assert_int(Bag.count_item(tree, "madeira")).is_equal(int(total.madeira) + int(House.FURNITURE_COSTS.mesa.madeira))
	assert_int(Bag.count_item(tree, "pedra_pequena")).is_equal(int(total.pedra_pequena))


func test_wall_face_below_is_solid() -> void:
	var tree := get_tree()
	var rect := Rect2i(10, 6, 7, 5)
	_give(House.rect_cost(rect))
	House.build(tree, "floresta", rect)
	var solid := House.solid_cells(tree)
	assert_bool(solid.has(Vector2i(13, 6))).is_true()  # parede norte
	assert_bool(solid.has(Vector2i(13, 7))).is_true()  # face dela, dentro da casa
	assert_bool(solid.has(House.door_of(rect))).is_false()
	assert_bool(solid.has(Vector2i(13, 9))).is_false()

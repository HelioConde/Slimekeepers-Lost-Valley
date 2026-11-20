extends GdUnitTestSuite

const BOND := preload("res://scripts/systems/slime_food_bond.gd")
# IDs de fixture, sem definir alimentos ou preferências do jogo.
const A := "teste/H01/0"
const B := "teste/H01/1"
const X := "comida_teste_x"
const Y := "comida_teste_y"

func test_valid_offer_is_bound_to_one_instance() -> void:
	var bond := BOND.new([A, B], [X])
	assert_bool(bond.offer(A, X)).is_true()
	assert_str(bond.first_food_for(A)).is_equal(X)
	assert_str(bond.first_food_for(B)).is_equal("")

func test_invalid_ids_do_not_record_progress() -> void:
	var bond := BOND.new([A, ""], [X, " "])
	assert_bool(bond.offer("", X)).is_false()
	assert_bool(bond.offer(B, X)).is_false()
	assert_bool(bond.offer(A, " ")).is_false()
	assert_bool(bond.offer(A, Y)).is_false()
	assert_int(bond.save_state().size()).is_equal(0)

func test_duplicate_offer_does_not_replace_first_food() -> void:
	var bond := BOND.new([A], [X, Y])
	assert_bool(bond.offer(A, X)).is_true()
	assert_bool(bond.offer(A, X)).is_false()
	assert_bool(bond.offer(A, Y)).is_false()
	assert_str(bond.first_food_for(A)).is_equal(X)
	assert_int(bond.save_state().size()).is_equal(1)

func test_load_replaces_state_and_save_is_ordered_and_detached() -> void:
	var bond := BOND.new([A, B], [X, Y])
	bond.offer(A, Y)
	var rows := [{"slime_id": B, "food_id": Y}, {"slime_id": A, "food_id": X}]
	assert_bool(bond.load_state(rows)).is_true()
	var saved := bond.save_state()
	assert_array(saved).is_equal([rows[1], rows[0]])
	var copy := BOND.new([A, B], [X, Y])
	assert_bool(copy.load_state(saved)).is_true()
	saved[0]["food_id"] = Y
	assert_str(copy.first_food_for(A)).is_equal(X)
	assert_str(bond.first_food_for(A)).is_equal(X)
	assert_bool(copy.offer(B, X)).is_false()
	assert_bool(copy.load_state([])).is_true()
	assert_int(copy.save_state().size()).is_equal(0)

func test_invalid_load_is_atomic() -> void:
	var bond := BOND.new([A, B], [X])
	bond.offer(A, X)
	var before := bond.save_state()
	var valid := {"slime_id": B, "food_id": X}
	for bad in [valid, {"slime_id": A}, {"slime_id": A, "food_id": Y}, null]:
		assert_bool(bond.load_state([valid, bad])).is_false()
		assert_array(bond.save_state()).is_equal(before)

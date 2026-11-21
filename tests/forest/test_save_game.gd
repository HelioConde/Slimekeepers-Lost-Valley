extends GdUnitTestSuite

## Save em disco: grava sessão + relógio + região, restaura igual, recusa lixo.

const Save := preload("res://scripts/systems/save_game.gd")
const Farm := preload("res://scripts/systems/farm_state.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
const Ship := preload("res://scripts/systems/shipping_state.gd")
const Session := preload("res://scripts/systems/session_state.gd")
const Clock := preload("res://scripts/systems/game_clock.gd")
const FARM_SCENE := "res://scenes/regions/Fazenda.tscn"


func before_test() -> void:
	Save.path = "user://test_save_%d.txt" % Time.get_ticks_usec()
	Session.clear_session(get_tree())


func after_test() -> void:
	Save.delete()
	Save.path = Save.DEFAULT_PATH
	Session.clear_session(get_tree())


func test_round_trip_keeps_farm_bag_money_and_clock() -> void:
	var tree := get_tree()
	var clock: Node = auto_free(Clock.new())
	clock.set_time(19, 30)
	Farm.till(tree, Vector2i(21, 14), "fazenda")
	Bag.add_item(tree, "semente_cenoura", 1)
	Farm.plant(tree, Vector2i(21, 14), "cenoura", "fazenda")
	Bag.add_item(tree, "repolho", 2)
	Ship.add_money(tree, 55)
	assert_bool(Save.save(tree, clock, FARM_SCENE)).is_true()
	assert_bool(Save.has_save()).is_true()
	Session.clear_session(tree)
	clock.set_time(8, 0)
	assert_str(Farm.crop(tree, Vector2i(21, 14), "fazenda")).is_empty()
	assert_str(Save.restore(tree, clock)).is_equal(FARM_SCENE)
	assert_str(Farm.crop(tree, Vector2i(21, 14), "fazenda")).is_equal("cenoura")
	assert_int(Bag.count_item(tree, "repolho")).is_equal(2)
	assert_int(Ship.money(tree)).is_equal(Ship.STARTING_MONEY + 55)
	assert_int(clock.get_hour()).is_equal(19)


func test_corrupt_save_changes_nothing() -> void:
	var tree := get_tree()
	var file := FileAccess.open(Save.path, FileAccess.WRITE)
	file.store_string("isto não é um save")
	file.close()
	Bag.add_item(tree, "cenoura", 4)
	var clock: Node = auto_free(Clock.new())
	assert_str(Save.restore(tree, clock)).is_empty()
	assert_int(Bag.count_item(tree, "cenoura")).is_equal(4)


func test_no_save_by_default_in_tests() -> void:
	assert_bool(Save.has_save()).is_false()


func test_menu_continue_restores_saved_farm() -> void:
	var tree := get_tree()
	var clock: Node = auto_free(Clock.new())
	Ship.add_money(tree, 10)
	Save.save(tree, clock, FARM_SCENE)
	Session.clear_session(tree)
	var menu: Control = auto_free(load("res://scenes/start_menu.tscn").instantiate())
	add_child(menu)
	await await_idle_frame()
	var continue_button: Button = menu.get_node("Actions/Continuar")
	assert_bool(continue_button.disabled).is_false()
	menu.get_node("Actions").free()  # evita trocar de cena no teste
	assert_str(Save.restore(tree, clock)).is_equal(FARM_SCENE)
	assert_int(Ship.money(tree)).is_equal(Ship.STARTING_MONEY + 10)

extends GdUnitTestSuite

## Save em disco: grava sessão + relógio + região, restaura igual, recusa lixo.

const Save := preload("res://scripts/systems/save_game.gd")
const Farm := preload("res://scripts/systems/farm_state.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
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


func test_round_trip_keeps_farm_bag_and_clock() -> void:
	var tree := get_tree()
	var clock: Node = auto_free(Clock.new())
	clock.set_time(19, 30)
	Farm.till(tree, Vector2i(21, 14), "fazenda")
	Bag.add_item(tree, "semente_cenoura", 1)
	Farm.plant(tree, Vector2i(21, 14), "cenoura", "fazenda")
	Bag.add_item(tree, "repolho", 2)
	assert_bool(Save.save(tree, clock, FARM_SCENE)).is_true()
	assert_bool(Save.has_save()).is_true()
	Session.clear_session(tree)
	clock.set_time(8, 0)
	assert_str(Farm.crop(tree, Vector2i(21, 14), "fazenda")).is_empty()
	assert_str(Save.restore(tree, clock)).is_equal(FARM_SCENE)
	assert_str(Farm.crop(tree, Vector2i(21, 14), "fazenda")).is_equal("cenoura")
	assert_int(Bag.count_item(tree, "repolho")).is_equal(2)
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
	Bag.add_item(tree, "beterraba", 3)
	Save.save(tree, clock, FARM_SCENE)
	Session.clear_session(tree)
	var menu: Control = auto_free(load("res://scenes/start_menu.tscn").instantiate())
	add_child(menu)
	await await_idle_frame()
	var continue_button: Button = menu.get_node("Actions/Continuar")
	assert_bool(continue_button.disabled).is_false()
	menu.get_node("Actions").free()  # evita trocar de cena no teste
	assert_str(Save.restore(tree, clock)).is_equal(FARM_SCENE)
	assert_int(Bag.count_item(tree, "beterraba")).is_equal(3)


## Saves de antes da fabricação (CRIACAO.md) tinham enxada e regador de graça:
## ao carregar, ganham as duas para a fazenda não travar.
func test_legacy_save_gets_starter_tools() -> void:
	var tree := get_tree()
	var clock: Node = auto_free(Clock.new())
	var old := {"version": Save.VERSION, "region": FARM_SCENE, "clock": clock.get_save_data(), "metas": {}}
	var file := FileAccess.open(Save.path, FileAccess.WRITE)
	file.store_string(var_to_str(old))
	file.close()
	assert_str(Save.restore(tree, clock)).is_equal(FARM_SCENE)
	assert_int(Bag.count_item(tree, "enxada")).is_equal(1)
	assert_int(Bag.count_item(tree, "regador")).is_equal(1)


func test_new_save_does_not_grant_tools() -> void:
	var tree := get_tree()
	var clock: Node = auto_free(Clock.new())
	Bag.add_item(tree, "fibra", 3)
	assert_bool(Save.save(tree, clock, FARM_SCENE)).is_true()
	Session.clear_session(tree)
	assert_str(Save.restore(tree, clock)).is_equal(FARM_SCENE)
	assert_int(Bag.count_item(tree, "enxada")).is_equal(0)
	assert_int(Bag.count_item(tree, "fibra")).is_equal(3)


## Espaços independentes (relatório de playtest ID 58): gravar um não mexe no outro, e
## "Continuar" escolhe o mais recente.
func test_slots_are_independent_and_latest_wins() -> void:
	var tree := get_tree()
	var clock: Node = auto_free(Clock.new())
	Save.path = ""
	Save.prefix = "user://test_slots_%d_" % Time.get_ticks_usec()
	Save.use_slot(1)
	Bag.add_item(tree, "repolho", 1)
	assert_bool(Save.save(tree, clock, FARM_SCENE)).is_true()
	Session.clear_session(tree)
	Save.use_slot(2)
	Bag.add_item(tree, "cenoura", 3)
	clock.advance_minutes(1440.0)
	assert_bool(Save.save(tree, clock, FARM_SCENE)).is_true()
	assert_array(Save.used_slots()).contains_exactly([1, 2])
	assert_int(Save.info(2).day).is_greater(int(Save.info(1).day))
	Save.use_slot(1)
	Session.clear_session(tree)
	Save.restore(tree, clock)
	assert_int(Bag.count_item(tree, "repolho")).is_equal(1)
	assert_int(Bag.count_item(tree, "cenoura")).is_equal(0)  # espaço 2 não vazou
	for n in [1, 2]:
		Save.use_slot(n)
		Save.delete()
	Save.prefix = Save.DEFAULT_PREFIX
	Save.use_slot(1)


## Gravação atômica (ID 57): arquivo principal estragado → a leitura usa o .bak.
func test_corrupt_main_falls_back_to_backup() -> void:
	var tree := get_tree()
	var clock: Node = auto_free(Clock.new())
	Bag.add_item(tree, "repolho", 4)
	assert_bool(Save.save(tree, clock, FARM_SCENE)).is_true()
	assert_bool(Save.save(tree, clock, FARM_SCENE)).is_true()  # o primeiro vira .bak
	var file := FileAccess.open(Save.path, FileAccess.WRITE)
	file.store_string("lixo")
	file.close()
	Session.clear_session(tree)
	assert_str(Save.restore(tree, clock)).is_equal(FARM_SCENE)
	assert_int(Bag.count_item(tree, "repolho")).is_equal(4)

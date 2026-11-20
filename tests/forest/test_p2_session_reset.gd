extends GdUnitTestSuite

## p2-session-reset-qa: Novo Jogo limpa todo estado de sessão guardado em metas do
## SceneTree; viagens não limpam nada. A varredura impede que um sistema novo
## grave uma chave que o reset esqueceria.

const SessionState := preload("res://scripts/systems/session_state.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
const Progress := preload("res://scripts/systems/session_progress_session.gd")
const Garden := preload("res://scripts/systems/valley_starter_garden.gd")
const ClockScript := preload("res://scripts/systems/game_clock.gd")

const KEY_PATTERNS := [
	"(?:get_tree\\(\\)|tree)\\.(?:set_meta|get_meta|has_meta)\\(\\s*\"([a-z_]+)\"",
	"const\\s+[A-Z_]*KEY\\s*:?=\\s*\"([a-z_]+)\"",
	"session_key\"?\\s*[:=]+\\s*\"([a-z_]+)\"",
]
const SCAN_EXCLUDE := ["res://scripts/menu/start_menu.gd", "res://scripts/systems/session_state.gd"]

var _saved: Dictionary = {}


func before_test() -> void:
	_saved.clear()
	for key in SessionState.SESSION_META_KEYS:
		if get_tree().has_meta(key):
			_saved[key] = get_tree().get_meta(key)
			get_tree().remove_meta(key)


func after_test() -> void:
	SessionState.clear_session(get_tree())
	for key in _saved:
		get_tree().set_meta(key, _saved[key])


func test_clear_session_removes_bag_garden_and_progress_written_by_real_systems() -> void:
	var tree := get_tree()
	var clock: Node = auto_free(ClockScript.new())
	assert_bool(Bag.add_item(tree, Bag.ITEM_ID, 2)).is_true()
	assert_bool(Progress.mark_event(tree, Progress.SEEDS_COLLECTED)).is_true()
	assert_bool(Garden.plant(tree, clock, "norte")).is_true()
	assert_bool(tree.has_meta(Bag.INVENTORY_KEY)).is_true()
	assert_bool(tree.has_meta(Garden.KEY)).is_true()
	assert_bool(tree.has_meta(Progress.KEY)).is_true()

	SessionState.clear_session(tree)

	for key in SessionState.SESSION_META_KEYS:
		assert_bool(tree.has_meta(key)).override_failure_message(key).is_false()
	assert_int(Bag.count_item(tree, Bag.ITEM_ID)).is_equal(0)
	assert_bool(Progress.is_marked(tree, Progress.SEEDS_COLLECTED)).is_false()


func test_clear_session_removes_every_listed_key_and_keeps_unrelated_metas() -> void:
	var tree := get_tree()
	for key in SessionState.SESSION_META_KEYS:
		tree.set_meta(key, {"stale": true})
	tree.set_meta("p2_reset_unrelated_probe", 7)

	SessionState.clear_session(tree)

	for key in SessionState.SESSION_META_KEYS:
		assert_bool(tree.has_meta(key)).override_failure_message(key).is_false()
	assert_int(tree.get_meta("p2_reset_unrelated_probe", 0)).is_equal(7)
	tree.remove_meta("p2_reset_unrelated_probe")


func test_session_state_survives_until_explicit_reset() -> void:
	var tree := get_tree()
	assert_bool(Bag.add_item(tree, Bag.ITEM_ID, 3)).is_true()
	# Viagem entre regiões troca a cena atual, mas metas ficam no SceneTree.
	var scene_stand_in: Node = auto_free(Node.new())
	add_child(scene_stand_in)
	scene_stand_in.queue_free()
	await await_idle_frame()
	assert_int(Bag.count_item(tree, Bag.ITEM_ID)).is_equal(3)


func test_every_session_key_used_by_scripts_is_cleared_on_new_game() -> void:
	var found := _scan_session_keys("res://scripts")
	assert_array(found.keys()).is_not_empty()
	for key in found:
		assert_bool(SessionState.SESSION_META_KEYS.has(key)) \
			.override_failure_message("chave '%s' (%s) não é limpa no Novo Jogo" % [key, found[key]]).is_true()


func test_reset_list_has_no_dead_entries() -> void:
	var found := _scan_session_keys("res://scripts")
	for key in SessionState.SESSION_META_KEYS:
		assert_bool(found.has(key)).override_failure_message("'%s' listada mas não usada" % key).is_true()


func test_start_menu_delegates_new_game_reset() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/menu/start_menu.gd")
	assert_str(source).contains("clear_session(get_tree())")


func _scan_session_keys(root: String) -> Dictionary:
	var regexes: Array[RegEx] = []
	for pattern in KEY_PATTERNS:
		regexes.append(RegEx.create_from_string(pattern))
	var found := {}
	for path in _gd_files(root):
		if SCAN_EXCLUDE.has(path):
			continue
		var source := FileAccess.get_file_as_string(path)
		for regex in regexes:
			for match in regex.search_all(source):
				found[match.get_string(1)] = path
	return found


func _gd_files(dir_path: String) -> PackedStringArray:
	var files := PackedStringArray()
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".gd"):
			files.append(dir_path.path_join(file))
	for sub in DirAccess.get_directories_at(dir_path):
		files.append_array(_gd_files(dir_path.path_join(sub)))
	return files

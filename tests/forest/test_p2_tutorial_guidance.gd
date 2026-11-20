extends GdUnitTestSuite

## p2-tutorial-guidance: dica breve do ciclo coletar → plantar → colher → preparar,
## derivada do estado real da sessão; some ao concluir e nunca bloqueia o jogador.

const Guidance := preload("res://scripts/systems/cooking_guidance.gd")
const GuidanceHud := preload("res://scripts/ui/cooking_guidance_hud.gd")
const SessionKeys := [
	"forest_bag_items", "forest_seed_patches_collected", "valley_starter_garden",
	"valley_starter_garden_harvests", "valley_cooking_ledger", "session_progress_flags",
]
const Bag := preload("res://scripts/systems/forest_bag.gd")
const Progress := preload("res://scripts/systems/session_progress_session.gd")
const Garden := preload("res://scripts/systems/valley_starter_garden.gd")
const Cooking := preload("res://scripts/systems/valley_cooking.gd")
const ClockScript := preload("res://scripts/systems/game_clock.gd")

var _saved: Dictionary = {}


func before_test() -> void:
	_saved.clear()
	for key in SessionKeys:
		if get_tree().has_meta(key):
			_saved[key] = get_tree().get_meta(key)
			get_tree().remove_meta(key)


func after_test() -> void:
	for key in SessionKeys:
		if get_tree().has_meta(key):
			get_tree().remove_meta(key)
	for key in _saved:
		get_tree().set_meta(key, _saved[key])


func test_steps_follow_the_real_cooking_cycle_and_end_empty() -> void:
	var tree := get_tree()
	var clock: Node = auto_free(ClockScript.new())
	assert_str(Guidance.next_step(tree)).contains("sementes")

	assert_bool(Bag.add_item(tree, Bag.ITEM_ID, 1)).is_true()
	assert_str(Guidance.next_step(tree)).contains("plante")

	assert_bool(Garden.plant(tree, clock, "norte")).is_true()
	assert_str(Guidance.next_step(tree)).contains("colha")

	clock.advance_minutes(Garden.GROWTH_MINUTES + 1.0)
	assert_bool(Garden.harvest(tree, clock, "norte")).is_true()
	assert_str(Guidance.next_step(tree)).contains("prepare")

	assert_str(Cooking.prepare(tree)).is_equal("prepared")
	assert_str(Guidance.next_step(tree)).is_empty()


func test_every_step_is_brief_and_mechanical() -> void:
	for text in Guidance.STEP_TEXTS.values():
		assert_int(text.length()).override_failure_message(text).is_less_equal(64)
		assert_str(text).starts_with("Próximo passo:")


func test_hud_shows_step_hides_when_done_and_ignores_mouse() -> void:
	var tree := get_tree()
	var hud: Control = auto_free(GuidanceHud.new())
	add_child(hud)
	hud.refresh()
	assert_bool(hud.visible).is_true()
	assert_str(hud.label.text).is_equal(Guidance.next_step(tree))
	assert_int(hud.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)

	assert_bool(Progress.mark_event(tree, Progress.FOOD_PREPARED)).is_true()
	hud.refresh()
	assert_bool(hud.visible).is_false()


func test_forest_and_valley_install_the_guidance_hud() -> void:
	for path in ["res://scripts/world/forest_region.gd", "res://scripts/world/valley_region.gd"]:
		assert_str(FileAccess.get_file_as_string(path)).override_failure_message(path).contains("GUIDANCE_HUD.new()")

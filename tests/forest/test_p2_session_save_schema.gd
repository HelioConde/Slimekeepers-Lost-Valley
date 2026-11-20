extends GdUnitTestSuite
## Schemas sao read-only; nunca escrevem em user:// nem ativam o botao Continuar.
const SAVE := preload("res://scripts/systems/session_save_schema.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const GARDEN := preload("res://scripts/systems/valley_starter_garden.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
const FOOD := preload("res://scripts/systems/slime_food_session.gd")
const PROGRESS := preload("res://scripts/systems/session_progress_session.gd")
var clock: Node

func before_test() -> void:
	clock = get_tree().root.get_node("GameClock")
	clock.reset_new_game()
	_clear()

func after_test() -> void:
	_clear()
	clock.reset_new_game()

func _clear() -> void:
	var tree := get_tree()
	for key in [BAG.INVENTORY_KEY, BAG.PATCHES_KEY, BAG.FRIENDS_KEY, GARDEN.KEY, GARDEN.LEDGER_KEY, COOKING.LEDGER_KEY, FOOD.OFFERS_KEY, PROGRESS.KEY, "valley_slime_friends"]:
		if tree.has_meta(key):
			tree.remove_meta(key)

func test_empty_snapshot_json_round_trip_is_valid_and_independent() -> void:
	var tree := get_tree()
	var captured: Dictionary = SAVE.capture(tree, clock)
	assert_bool(SAVE.validate(captured)).is_true()
	assert_int(captured["version"]).is_equal(SAVE.VERSION)
	assert_int(captured["clock"]["day"]).is_equal(1)
	assert_dict(captured["bag"]).is_empty()
	assert_dict(captured["progress"]).is_empty()
	assert_array(captured["harvests"]).is_empty()
	var encoded: String = JSON.stringify(captured)
	var decoded: Variant = JSON.parse_string(encoded)
	assert_bool(SAVE.validate(decoded)).is_true()
	assert_int(int(decoded["version"])).is_equal(SAVE.VERSION)
	assert_int(int(decoded["clock"]["day"])).is_equal(1)
	assert_bool(tree.has_meta(BAG.INVENTORY_KEY)).is_false()

func test_capture_real_foraging_garden_cooking_and_offer() -> void:
	var tree := get_tree()
	tree.set_meta(BAG.FRIENDS_KEY, {"brotinho/H01/0": true})
	assert_bool(BAG.harvest(tree, "bosque_cogumelos")).is_true()
	assert_bool(GARDEN.plant(tree, clock, "norte")).is_true()
	clock.advance_minutes(121.0)
	assert_bool(GARDEN.harvest(tree, clock, "norte")).is_true()
	assert_str(COOKING.prepare(tree)).is_equal("prepared")
	assert_str(FOOD.offer(tree, "brotinho/H01/0", true)).is_equal("offered")
	var captured: Dictionary = SAVE.capture(tree, clock)
	assert_bool(SAVE.validate(captured)).is_true()
	assert_int(captured["meals_prepared"]).is_equal(1)
	assert_int(captured["harvests"].size()).is_equal(1)
	assert_int(captured["food_offers"].size()).is_equal(1)
	assert_int(captured["progress"].size()).is_equal(4)
	assert_dict(captured["bag"]).is_empty()
	var decoded: Variant = JSON.parse_string(JSON.stringify(captured))
	assert_bool(SAVE.validate(decoded)).is_true()
	assert_int(decoded["harvests"].size()).is_equal(1)
	assert_int(decoded["progress"].size()).is_equal(4)
	assert_int(COOKING.portions(tree)).is_equal(1)

func test_wrong_version_object_and_nonfinite_data_are_rejected() -> void:
	var snapshot: Dictionary = SAVE.capture(get_tree(), clock)
	var wrong: Dictionary = snapshot.duplicate(true)
	wrong["version"] = 2
	assert_bool(SAVE.validate(wrong)).is_false()
	wrong = snapshot.duplicate(true)
	wrong["clock"]["minutes"] = INF
	assert_bool(SAVE.validate(wrong)).is_false()
	wrong = snapshot.duplicate(true)
	wrong["bag"] = {"unsafe": RefCounted.new()}
	assert_bool(SAVE.validate(wrong)).is_false()
	wrong = snapshot.duplicate(true)
	wrong["unexpected_key"] = "not allowed"
	assert_bool(SAVE.validate(wrong)).is_false()

func test_corrupt_source_meta_rejected_without_mutation() -> void:
	var tree := get_tree()
	tree.set_meta(BAG.INVENTORY_KEY, {BAG.LEAVES_ID: -3})
	assert_dict(SAVE.capture(tree, clock)).is_empty()
	assert_int(tree.get_meta(BAG.INVENTORY_KEY)[BAG.LEAVES_ID]).is_equal(-3)
	tree.remove_meta(BAG.INVENTORY_KEY)
	tree.set_meta(GARDEN.KEY, "malformed")
	assert_dict(SAVE.capture(tree, clock)).is_empty()
	assert_str(tree.get_meta(GARDEN.KEY)).is_equal("malformed")
	tree.remove_meta(GARDEN.KEY)
	tree.set_meta(PROGRESS.KEY, {"unknown.event": true})
	assert_dict(SAVE.capture(tree, clock)).is_empty()
	assert_bool(tree.get_meta(PROGRESS.KEY)["unknown.event"]).is_true()

func test_duplicate_harvest_and_offer_are_invalid_json_states() -> void:
	var snapshot: Dictionary = SAVE.capture(get_tree(), clock)
	var harvested: Dictionary = snapshot.duplicate(true)
	harvested["harvests"] = [
		{"cycle": 0, "bed_id": "norte", "resources": {BAG.LEAVES_ID: 1}},
		{"cycle": 0, "bed_id": "norte", "resources": {BAG.LEAVES_ID: 1}}
	]
	assert_bool(SAVE.validate(harvested)).is_false()
	var offered: Dictionary = snapshot.duplicate(true)
	offered["food_offers"] = [
		{"slime_id": "brotinho/H01/0", "food_id": COOKING.RECIPE_ID},
		{"slime_id": "brotinho/H01/0", "food_id": COOKING.RECIPE_ID}
	]
	assert_bool(SAVE.validate(offered)).is_false()

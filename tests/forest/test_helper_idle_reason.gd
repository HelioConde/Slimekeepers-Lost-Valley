extends GdUnitTestSuite
## O ajudante parado diz por quê (benchmark e pesquisa Palworld, 2026-11-27).

const Helpers := preload("res://scripts/world/farm_helpers.gd")
const KEYS := ["slime_work_off", "farm_helpers_done", "forest_bag_inventory"]


func after_test() -> void:
	for key in ["slime_work_off", Helpers.KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func test_night_comes_first() -> void:
	assert_str(Helpers.idle_reason(get_tree(), "bolhinha", 1, false)).is_equal("night")


func test_time_off_from_the_disc() -> void:
	get_tree().set_meta("slime_work_off", {"bolhinha": true})
	assert_str(Helpers.idle_reason(get_tree(), "bolhinha", 1, true)).is_equal("off")


func test_no_energy() -> void:
	get_tree().set_meta(Helpers.KEY, {"bolhinha": {"day": 1, "energy": 0}})
	assert_str(Helpers.idle_reason(get_tree(), "bolhinha", 1, true)).is_equal("tired")


func test_no_work_has_a_text_per_role() -> void:
	assert_str(Helpers.idle_reason(get_tree(), "bolhinha", 1, true)).is_equal("no_work")
	for species in ["brotinho", "bolhinha", "musguinho", "colhita"]:
		assert_str(Helpers.reason_text("no_work", species)).is_not_empty()
	for reason in ["night", "off", "tired", "no_seed"]:
		assert_str(Helpers.reason_text(reason, "brotinho")).is_not_empty()

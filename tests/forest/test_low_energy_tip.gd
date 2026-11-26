extends GdUnitTestSuite
## Dica de pouca energia (playtest IDs 47/48): sem cama sugere construir; com cama, dormir.

const House := preload("res://scripts/systems/house_state.gd")
const Hud := preload("res://scripts/ui/player_status_hud.gd")


func after_test() -> void:
	if get_tree().has_meta(House.KEY): get_tree().remove_meta(House.KEY)


func test_tip_follows_the_bed() -> void:
	var tree := get_tree()
	tree.set_meta(House.KEY, House.empty())
	assert_str(Hud.low_energy_tip(tree)).contains("Construa uma cama")
	var house := House.empty()
	house.furniture = {Vector2i(2, 2): "cama"}
	tree.set_meta(House.KEY, house)
	assert_str(Hud.low_energy_tip(tree)).contains("dormir")

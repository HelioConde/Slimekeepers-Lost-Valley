extends GdUnitTestSuite

## Fazenda: arar -> plantar -> regar -> crescer por dia regado -> colher.

const Farm := preload("res://scripts/systems/farm_state.gd")
const Crops := preload("res://scripts/systems/crop_catalog.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")


func before_test() -> void:
	var tree := get_tree()
	for key in [Farm.KEY, Bag.INVENTORY_KEY, Farm.STARTER_KEY]:
		if tree.has_meta(key): tree.remove_meta(key)


func test_catalog_has_crops_with_existing_art() -> void:
	assert_int(Crops.ids().size()).is_greater_equal(4)
	for id in Crops.ids():
		var crop: Dictionary = Crops.get_crop(id)
		assert_int((crop.stages as Array).size()).is_greater_equal(4)
		for path in crop.stages:
			assert_bool(ResourceLoader.exists(path)).override_failure_message(path).is_true()
		assert_str(crop.seed).is_not_empty()
		assert_str(crop.harvest).is_not_empty()
	# Sementes silvestres da Floresta viram folhas frescas (alimentam a culinária).
	assert_str(Crops.crop_for_seed(Bag.ITEM_ID)).is_equal("folhas_silvestres")
	assert_str(Crops.get_crop("folhas_silvestres").harvest).is_equal(Bag.LEAVES_ID)


func test_full_cycle_till_plant_water_grow_harvest() -> void:
	var tree := get_tree()
	var cell := Vector2i(3, 2)
	assert_str(Farm.action_for(tree, cell, "cenoura")).is_equal("till")
	assert_bool(Farm.till(tree, cell)).is_true()
	assert_bool(Bag.add_item(tree, "semente_cenoura", 2)).is_true()
	assert_str(Farm.action_for(tree, cell, "cenoura")).is_equal("plant")
	assert_bool(Farm.plant(tree, cell, "cenoura")).is_true()
	assert_int(Bag.count_item(tree, "semente_cenoura")).is_equal(1)
	assert_str(Farm.action_for(tree, cell, "cenoura")).is_equal("water")
	var days: int = (Crops.get_crop("cenoura").stages as Array).size() - 1
	for day in days:
		assert_bool(Farm.water(tree, cell)).is_true()
		assert_bool(Farm.is_watered(tree, cell)).is_true()
		Farm.advance_day(tree)
		assert_bool(Farm.is_watered(tree, cell)).is_false()  # a terra seca a cada dia
	assert_int(Farm.stage(tree, cell)).is_equal(days)
	assert_str(Farm.action_for(tree, cell, "cenoura")).is_equal("harvest")
	assert_bool(Farm.harvest(tree, cell)).is_true()
	assert_int(Bag.count_item(tree, "cenoura")).is_equal(1)
	# Depois da colheita a terra continua arada e vazia.
	assert_str(Farm.action_for(tree, cell, "cenoura")).is_equal("plant")


func test_crop_only_grows_on_watered_days() -> void:
	var tree := get_tree()
	var cell := Vector2i(0, 0)
	Farm.till(tree, cell)
	Bag.add_item(tree, "semente_beterraba", 1)
	Farm.plant(tree, cell, "beterraba")
	Farm.advance_day(tree)
	assert_int(Farm.stage(tree, cell)).is_equal(0)
	Farm.water(tree, cell)
	Farm.advance_day(tree)
	assert_int(Farm.stage(tree, cell)).is_equal(1)


func test_cannot_plant_without_seed_or_on_grass_or_twice() -> void:
	var tree := get_tree()
	var cell := Vector2i(1, 1)
	assert_bool(Farm.plant(tree, cell, "repolho")).is_false()  # não arada
	Farm.till(tree, cell)
	assert_bool(Farm.plant(tree, cell, "repolho")).is_false()  # sem semente
	Bag.add_item(tree, "semente_repolho", 2)
	assert_bool(Farm.plant(tree, cell, "repolho")).is_true()
	assert_bool(Farm.plant(tree, cell, "repolho")).is_false()  # já plantada
	assert_int(Bag.count_item(tree, "semente_repolho")).is_equal(1)
	assert_bool(Farm.harvest(tree, cell)).is_false()  # não está pronta


func test_starter_seed_pack_is_given_once() -> void:
	var tree := get_tree()
	assert_bool(Farm.grant_starter_seeds(tree)).is_true()
	var carrots := Bag.count_item(tree, "semente_cenoura")
	assert_int(carrots).is_greater(0)
	assert_bool(Farm.grant_starter_seeds(tree)).is_false()
	assert_int(Bag.count_item(tree, "semente_cenoura")).is_equal(carrots)


func test_days_passed_elsewhere_are_caught_up() -> void:
	var tree := get_tree()
	if tree.has_meta(Farm.LAST_DAY_KEY): tree.remove_meta(Farm.LAST_DAY_KEY)
	var cell := Vector2i(2, 2)
	Farm.till(tree, cell, "fazenda")
	Bag.add_item(tree, "semente_cenoura", 1)
	Farm.plant(tree, cell, "cenoura", "fazenda")
	Farm.water(tree, cell, "fazenda")
	assert_int(Farm.catch_up(tree, 3)).is_equal(0)  # primeira vez só marca o dia
	assert_int(Farm.catch_up(tree, 5)).is_equal(2)  # dias 4 e 5 passaram longe do campo
	assert_int(Farm.stage(tree, cell, "fazenda")).is_equal(1)  # só o dia regado conta
	assert_bool(Farm.is_watered(tree, cell, "fazenda")).is_false()
	assert_bool(Farm.is_tilled(tree, cell, "vale")).is_false()  # campos separados
	tree.remove_meta(Farm.LAST_DAY_KEY)

extends GdUnitTestSuite

## Energia: ferramentas gastam, sem energia não age, dormir/virada do dia recupera.

const Energy := preload("res://scripts/systems/energy_state.gd")
const Field := preload("res://scripts/world/farm_field.gd")
const Farm := preload("res://scripts/systems/farm_state.gd")
const Hotbar := preload("res://scripts/systems/hotbar_state.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")


func before_test() -> void:
	for key in [Energy.KEY, Farm.KEY, Bag.INVENTORY_KEY, Farm.STARTER_KEY, Hotbar.SELECTED_KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func test_spend_and_restore() -> void:
	var tree := get_tree()
	assert_int(Energy.current(tree)).is_equal(Energy.MAX)
	assert_bool(Energy.spend(tree, "till")).is_true()
	assert_int(Energy.current(tree)).is_equal(Energy.MAX - Energy.COSTS.till)
	tree.set_meta(Energy.KEY, 1)
	assert_bool(Energy.spend(tree, "water")).is_false()
	assert_int(Energy.current(tree)).is_equal(1)
	Energy.restore(tree)
	assert_int(Energy.current(tree)).is_equal(Energy.MAX)


func test_tired_player_cannot_till() -> void:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	var field: Node2D = Field.new()
	field.origin_cell = Vector2i(10, 10)
	field.size_cells = Vector2i(3, 3)
	region.add_child(field)
	var actor := Node2D.new()
	region.add_child(actor)
	actor.global_position = Vector2(11 * 32 + 16, 10 * 32 + 4)
	await await_idle_frame()
	Bag.add_item(get_tree(), "enxada")  # fabricada na bancada (CRIACAO.md)
	Hotbar.select(get_tree(), 0)  # enxada
	get_tree().set_meta(Energy.KEY, 2)
	assert_str(field.interact(actor)).contains("Cansado")  # Aren (padrão); Moni: "Cansada"
	assert_bool(Farm.is_tilled(get_tree(), field.target_cell(actor))).is_false()
	Energy.restore(get_tree())
	field.interact(actor)
	assert_bool(Farm.is_tilled(get_tree(), field.target_cell(actor))).is_true()
	assert_int(Energy.current(get_tree())).is_equal(Energy.MAX - Energy.COSTS.till)


func test_tired_message_matches_protagonist() -> void:
	# Aren é "Cansado", Moni é "Cansada" (aviso de energia esgotada).
	var Who := preload("res://scripts/systems/protagonist.gd")
	get_tree().set_meta(Who.KEY, "aren")
	assert_str(Who.tired_message(get_tree())).starts_with("Cansado ")
	get_tree().set_meta(Who.KEY, "moni")
	assert_str(Who.tired_message(get_tree())).starts_with("Cansada ")
	get_tree().remove_meta(Who.KEY)


func test_slime_likes_food_of_its_habitat() -> void:
	var feeding := preload("res://scripts/systems/slime_feeding.gd")
	assert_int(feeding.gain("cenoura", "brotinho")).is_equal(20)  # vegetal: preferido na floresta
	assert_int(feeding.gain("cenoura", "bolhinha")).is_equal(10)  # perto da água prefere marinha
	assert_int(feeding.gain("sopa_legumes", "musguinho")).is_equal(50)

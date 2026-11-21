extends GdUnitTestSuite

## Campo de cultivo na cena: alvo à frente do jogador, ciclo pelo [E], troca de
## semente, sprites das culturas e terra arada em pixel art.

const Field := preload("res://scripts/world/farm_field.gd")
const Farm := preload("res://scripts/systems/farm_state.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")


func before_test() -> void:
	for key in [Farm.KEY, Bag.INVENTORY_KEY, Farm.STARTER_KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func _rig() -> Array:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	var field: Node2D = Field.new()
	field.origin_cell = Vector2i(10, 10)
	field.size_cells = Vector2i(4, 3)
	region.add_child(field)
	var actor := Node2D.new()
	actor.set_script(GDScript.new())
	actor.set("facing", "south")
	region.add_child(actor)
	field.player = actor
	return [field, actor]


func _face(actor: Node2D) -> void:
	actor.set_meta("facing", "south")


func test_full_loop_through_interact() -> void:
	var parts := _rig()
	var field: Node2D = parts[0]
	var actor: Node2D = parts[1]
	actor.global_position = Vector2(11 * 32 + 16, 10 * 32 + 4)  # célula (11,10), olhando para (11,11)
	await await_idle_frame()
	assert_int(Bag.count_item(get_tree(), "semente_cenoura")).is_greater(0)  # kit inicial
	var cell: Vector2i = field.target_cell(actor)
	assert_bool(field.contains(cell)).is_true()
	assert_str(field.hint(actor)).contains("Arar")
	field.interact(actor)
	assert_bool(Farm.is_tilled(get_tree(), cell)).is_true()
	assert_str(field.hint(actor)).contains("Plantar")
	field.interact(actor)
	assert_str(Farm.crop(get_tree(), cell)).is_equal("cenoura")
	assert_object(field.get_node_or_null("Crop_%d_%d/Sprite" % [cell.x, cell.y])).is_not_null()
	field.interact(actor)
	assert_bool(Farm.is_watered(get_tree(), cell)).is_true()
	assert_str(field.hint(actor)).contains("regada")


func test_target_outside_field_is_invalid() -> void:
	var parts := _rig()
	var field: Node2D = parts[0]
	var actor: Node2D = parts[1]
	actor.global_position = Vector2(0, 0)
	await await_idle_frame()
	assert_bool(field.has_target(actor)).is_false()


func test_cycle_seed_skips_crops_without_seeds() -> void:
	var parts := _rig()
	var field: Node2D = parts[0]
	await await_idle_frame()
	assert_str(field.selected_crop).is_equal("cenoura")
	field.cycle_seed()
	assert_str(field.selected_crop).is_equal("beterraba")
	field.cycle_seed()
	assert_str(field.selected_crop).is_equal("repolho")
	field.cycle_seed()  # sem sementes silvestres: volta para cenoura
	assert_str(field.selected_crop).is_equal("cenoura")


func test_soil_tile_is_pixel_art_with_open_edges() -> void:
	var lone: Image = Field.soil_image(0, false)
	assert_float(lone.get_pixel(0, 0).a).is_equal(0.0)  # canto arredondado transparente
	assert_float(lone.get_pixel(16, 16).a).is_equal(1.0)
	var middle: Image = Field.soil_image(15, false)  # cercado de terra: sem borda
	assert_float(middle.get_pixel(0, 16).a).is_equal(1.0)
	var wet: Image = Field.soil_image(15, true)
	assert_float(wet.get_pixel(16, 16).get_luminance()).is_less(middle.get_pixel(16, 16).get_luminance())
	var colors := {}
	for y in 32:
		for x in 32:
			colors[middle.get_pixel(x, y).to_html()] = true
	assert_int(colors.size()).is_less_equal(6)  # paleta fechada, sem degradê

extends GdUnitTestSuite

## Fabricação (CRIACAO.md): receitas por dados, transação atômica, machado exigido
## na bancada, capacidade da bolsa e cadeia completa do início sem ferramentas.

const Crafting := preload("res://scripts/systems/crafting.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
const Items := preload("res://scripts/systems/item_catalog.gd")


func before_test() -> void:
	if get_tree().has_meta(Bag.INVENTORY_KEY): get_tree().remove_meta(Bag.INVENTORY_KEY)


func test_every_recipe_item_exists_with_icon() -> void:
	for r: Dictionary in Crafting.recipes():
		for item_id in (r.inputs.keys() + r.output.keys() + r.get("requires", [])):
			assert_bool(Items.ITEMS.has(item_id)).override_failure_message(item_id).is_true()
			assert_object(Items.icon(item_id)).override_failure_message(item_id).is_not_null()
	assert_int(Crafting.recipes("maos").size()).is_greater(0)
	assert_int(Crafting.recipes("bancada").size()).is_greater(0)


func test_rope_consumes_fiber_atomically() -> void:
	var tree := get_tree()
	Bag.add_item(tree, "fibra", 2)
	assert_str(Crafting.missing(tree, "corda")).contains("fibra")
	assert_bool(Crafting.craft(tree, "corda")).is_false()
	assert_int(Bag.count_item(tree, "fibra")).is_equal(2)  # falha não gasta nada
	Bag.add_item(tree, "fibra", 1)
	assert_bool(Crafting.craft(tree, "corda")).is_true()
	assert_int(Bag.count_item(tree, "fibra")).is_equal(0)
	assert_int(Bag.count_item(tree, "corda")).is_equal(1)


func test_only_one_axe() -> void:
	var tree := get_tree()
	Bag.add_item(tree, "machado")
	Bag.add_item(tree, "graveto", 4)
	Bag.add_item(tree, "pedra_pequena", 4)
	Bag.add_item(tree, "corda", 2)
	assert_str(Crafting.missing(tree, "machado")).contains("já tem")
	assert_bool(Bag.add_item(tree, "machado")).is_false()  # capacidade 1


func test_bench_tools_need_the_axe() -> void:
	var tree := get_tree()
	Bag.add_item(tree, "madeira", 10)
	Bag.add_item(tree, "pedra_pequena", 4)
	Bag.add_item(tree, "corda", 4)
	assert_str(Crafting.missing(tree, "enxada")).contains("machado")
	Bag.add_item(tree, "machado")
	assert_bool(Crafting.craft(tree, "enxada")).is_true()
	assert_int(Bag.count_item(tree, "machado")).is_equal(1)  # exigido, não gasto
	assert_int(Bag.count_item(tree, "enxada")).is_equal(1)


func test_stack_capacity() -> void:
	var tree := get_tree()
	assert_bool(Bag.add_item(tree, "fibra", Items.MAX_STACK)).is_true()
	assert_bool(Bag.add_item(tree, "fibra", 1)).is_false()
	assert_int(Bag.count_item(tree, "fibra")).is_equal(Items.MAX_STACK)


## Do zero às ferramentas iniciais, só com o que a coleta e o tronco dão.
func test_full_chain_from_nothing() -> void:
	var tree := get_tree()
	Bag.add_item(tree, "fibra", 3 * 6)  # 6 cordas: bancada 2, machado 1, enxada 1, regador 2
	Bag.add_item(tree, "graveto", 8)
	Bag.add_item(tree, "pedra_pequena", 8)
	for i in 6: assert_bool(Crafting.craft(tree, "corda")).is_true()
	assert_bool(Crafting.craft(tree, "bancada")).is_true()  # sem madeira (gravetos, pedras, corda)
	assert_bool(Crafting.craft(tree, "machado")).is_true()  # feito na bancada
	Bag.add_item(tree, "madeira", 7)  # vem das árvores cortadas com o machado
	assert_bool(Crafting.craft(tree, "enxada")).is_true()
	assert_bool(Crafting.craft(tree, "regador")).is_true()
	for tool in ["machado", "enxada", "regador", "bancada"]:
		assert_int(Bag.count_item(tree, tool)).override_failure_message(tool).is_equal(1)

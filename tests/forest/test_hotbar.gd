extends GdUnitTestSuite

## Barra rápida: ferramentas que o jogador tem, itens da bolsa na ordem, seleção e ícones.

const Hotbar := preload("res://scripts/systems/hotbar_state.gd")
const Items := preload("res://scripts/systems/item_catalog.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
const HotbarHud := preload("res://scripts/ui/hotbar_hud.gd")


func before_test() -> void:
	for key in [Bag.INVENTORY_KEY, Hotbar.SELECTED_KEY, Bag.LAYOUT_KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func test_crafted_tools_only_appear_when_owned() -> void:
	var slots: Array = Hotbar.slots(get_tree())
	for tool in Items.TOOLS:  # o jogo começa sem ferramentas
		assert_bool(slots.has(tool)).override_failure_message(tool).is_false()
	Bag.add_item(get_tree(), "machado")
	assert_bool(Hotbar.slots(get_tree()).has("machado")).is_true()


func test_tools_first_then_bag_items_in_order() -> void:
	var tree := get_tree()
	Bag.add_item(tree, "enxada")
	Bag.add_item(tree, "regador")
	Bag.add_item(tree, "cenoura", 3)
	Bag.add_item(tree, "semente_repolho", 2)
	var slots: Array = Hotbar.slots(tree)
	assert_int(slots.size()).is_equal(10)
	assert_str(slots[0]).is_equal("enxada")
	assert_str(slots[1]).is_equal("regador")
	assert_str(slots[2]).is_equal("cenoura")  # cada item fica onde entrou (ordem de chegada)
	assert_str(slots[3]).is_equal("semente_repolho")
	assert_str(slots[4]).is_empty()
	assert_int(Hotbar.count(tree, "cenoura")).is_equal(3)
	assert_int(Hotbar.count(tree, "enxada")).is_equal(0)  # ferramenta: sem número na barra


func test_selection_wraps_and_persists_in_session() -> void:
	var tree := get_tree()
	Hotbar.select(tree, 12)
	assert_int(Hotbar.selected_index(tree)).is_equal(2)
	Hotbar.select(tree, -1)
	assert_int(Hotbar.selected_index(tree)).is_equal(9)
	Bag.add_item(tree, "enxada")
	Bag.add_item(tree, "regador")
	Hotbar.select(tree, 1)
	assert_str(Hotbar.selected_item(tree)).is_equal("regador")


func test_every_item_has_an_icon() -> void:
	for item in Items.TOOLS + Items.ORDER:
		assert_object(Items.icon(item)).override_failure_message(item).is_not_null()
		assert_int(Items.icon(item).get_width()).is_less_equal(48)


func test_number_keys_select_slots() -> void:
	var hud: PanelContainer = auto_free(HotbarHud.new())
	add_child(hud)
	await await_idle_frame()
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_2
	hud._unhandled_input(key)
	assert_int(Hotbar.selected_index(get_tree())).is_equal(1)
	key.physical_keycode = KEY_0
	hud._unhandled_input(key)
	assert_int(Hotbar.selected_index(get_tree())).is_equal(9)


## Mochila (pedido do usuário 2026-11-27, item 42): barra cheia → mochila; trocar de lugar;
## item que acaba libera o espaço.
func test_overflow_goes_to_backpack_and_swap_moves_items() -> void:
	var tree := get_tree()
	var ids := ["fibra", "graveto", "pedra_pequena", "corda", "madeira", "cenoura", "beterraba", "repolho", "folhas_frescas", "semente_cenoura", "semente_beterraba"]
	for id in ids: assert_bool(Bag.add_item(tree, id, 1)).is_true()
	var layout: Array = Bag.layout(tree)
	assert_int(layout.size()).is_equal(Bag.SLOTS)
	assert_str(layout[9]).is_equal("semente_cenoura")
	assert_str(layout[10]).is_equal("semente_beterraba")  # barra cheia: foi para a mochila
	assert_bool(Hotbar.slots(tree).has("semente_beterraba")).is_false()
	Bag.swap_slots(tree, 0, 10)
	assert_str(Hotbar.slots(tree)[0]).is_equal("semente_beterraba")
	assert_str(Bag.layout(tree)[10]).is_equal("fibra")
	Bag.spend_item(tree, "semente_beterraba", 1)
	assert_str(Hotbar.slots(tree)[0]).is_empty()  # acabou: o espaço fica livre
	assert_bool(Bag.add_item(tree, "sementes_silvestres", 1)).is_true()
	assert_str(Hotbar.slots(tree)[0]).is_equal("sementes_silvestres")  # o próximo item ocupa a vaga da barra

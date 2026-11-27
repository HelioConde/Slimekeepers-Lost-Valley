extends GdUnitTestSuite

## Playtest ID 59: preferência por ingrediente (amado, gostado, neutro) muda o ganho de laço;
## pratos herdam a média dos ingredientes; a reação só fica conhecida depois de provar.

const Feeding := preload("res://scripts/systems/slime_feeding.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")
const SessionState := preload("res://scripts/systems/session_state.gd")
const ID := "brotinho/H01/0"


func before_test() -> void:
	for key in [Feeding.KEY, Feeding.FED_KEY, Feeding.KNOWN_KEY, Bag.INVENTORY_KEY]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)


func test_levels_change_gain() -> void:
	assert_str(Feeding.preference("cenoura", "brotinho")).is_equal("amado")
	assert_str(Feeding.preference("beterraba", "brotinho")).is_equal("gostado")
	assert_str(Feeding.preference("repolho", "brotinho")).is_equal("neutro")
	assert_int(Feeding.gain("cenoura", "brotinho")).is_equal(20)
	assert_int(Feeding.gain("beterraba", "brotinho")).is_equal(15)
	assert_int(Feeding.gain("repolho", "brotinho")).is_equal(10)
	# Cada espécie tem gosto próprio.
	assert_str(Feeding.preference("repolho", "bolhinha")).is_equal("amado")
	assert_str(Feeding.preference("folhas_frescas", "musguinho")).is_equal("amado")
	assert_str(Feeding.preference("cenoura", "musguinho")).is_equal("neutro")


func test_dish_follows_its_ingredients() -> void:
	# Cenoura assada = só cenoura: amada pelo Brotinho, neutra para o Musguinho.
	assert_str(Feeding.preference("cenoura_assada", "brotinho")).is_equal("amado")
	assert_int(Feeding.gain("cenoura_assada", "brotinho")).is_equal(50)
	assert_str(Feeding.preference("cenoura_assada", "musguinho")).is_equal("neutro")
	# Sopa (cenoura + beterraba + repolho): amado + gostado + neutro = gostado.
	assert_str(Feeding.preference("sopa_legumes", "brotinho")).is_equal("gostado")
	assert_int(Feeding.gain("sopa_legumes", "brotinho")).is_equal(38)
	assert_str(Feeding.preference("porcao_folhas_prototipo", "musguinho")).is_equal("amado")


func test_other_species_keep_habitat_rule() -> void:
	assert_bool(Feeding.is_favorite("cenoura", "construlim")).is_true()
	assert_bool(Feeding.is_favorite("sopa_legumes", "colhita")).is_true()
	assert_str(Feeding.preference("cenoura", "colhita")).is_equal("neutro")


func test_feeding_reveals_preference_and_spends_one() -> void:
	var tree := get_tree()
	Bag.add_item(tree, "beterraba", 2)
	assert_str(Feeding.known_preference(tree, "beterraba", "brotinho")).is_empty()
	assert_str(Feeding.feed(tree, ID, true, "beterraba", 1, "brotinho")).is_equal("fed")
	assert_int(Bag.count_item(tree, "beterraba")).is_equal(1)
	assert_int(Feeding.points(tree, ID)).is_equal(15)
	assert_str(Feeding.known_preference(tree, "beterraba", "brotinho")).is_equal("gostado")
	assert_str(Feeding.known_preference(tree, "cenoura", "brotinho")).is_empty()  # não provou
	assert_str(Feeding.known_preference(tree, "beterraba", "musguinho")).is_empty()  # outra espécie
	assert_bool(SessionState.SESSION_META_KEYS.has(Feeding.KNOWN_KEY)).is_true()


func test_reaction_text_per_level() -> void:
	assert_str(Feeding.reaction_text("amado")).contains("favorito")
	assert_str(Feeding.reaction_text("gostado")).is_equal("gostou")
	assert_str(Feeding.reaction_text("neutro")).contains("sem muita vontade")

extends GdUnitTestSuite
## Idioma (playtest ID 15): português padrão e inglês, pelas chaves em português.

const Language := preload("res://scripts/systems/language.gd")
var _before := ""


func before_test() -> void:
	_before = TranslationServer.get_locale()
	Language.apply_saved()


func after_test() -> void:
	TranslationServer.set_locale(_before)


func test_english_translates_menu_and_tips() -> void:
	TranslationServer.set_locale("en")
	assert_str(tr("Novo Jogo")).is_equal("New Game")
	assert_str(tr("Volume da música")).is_equal("Music volume")
	assert_str(tr("Gravetos %d/8") % 3).is_equal("Twigs 3/8")
	assert_str(tr("Junte 8 gravetos e 6 pedrinhas: chegue perto e aperte [F] ou [esq] (andar cancela)")).contains("[F]")


func test_portuguese_keeps_the_text_even_with_english_fallback() -> void:
	TranslationServer.set_locale("pt_BR")
	assert_str(tr("Novo Jogo")).is_equal("Novo Jogo")
	assert_str(tr("Volume da música")).is_equal("Volume da música")


func test_selector_lists_both_and_marks_current() -> void:
	TranslationServer.set_locale("en")
	var button: OptionButton = auto_free(Language.selector())
	assert_int(button.item_count).is_equal(2)
	assert_int(button.selected).is_equal(1)


func test_item_names_and_clock_follow_the_language() -> void:
	var items := preload("res://scripts/systems/item_catalog.gd")
	TranslationServer.set_locale("en")
	assert_str(str(items.info("graveto").name)).is_equal("Twig")
	assert_str(items.describe("cenoura")).contains("Crop")
	assert_str(tr("Manhã") + " · " + tr("Primavera")).is_equal("Morning · Spring")
	TranslationServer.set_locale("pt_BR")
	assert_str(str(items.info("graveto").name)).is_equal("Graveto")

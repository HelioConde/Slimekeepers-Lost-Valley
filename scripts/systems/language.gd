extends RefCounted
## Idioma da interface (playtest ID 15): português (padrão) e inglês. As chaves são o
## próprio texto em português (translations/ui.csv); Labels e Buttons traduzem sozinhos
## quando o texto bate com uma chave, e o código usa tr() nos textos montados.
## A escolha fica em presentation.cfg (ui/locale).

const PREFS := "user://presentation.cfg"
const DEFAULT := "pt_BR"
const LOCALES := [["pt_BR", "Português"], ["en", "English"]]
const FILES := ["res://translations/ui.pt_BR.translation", "res://translations/ui.en.translation"]


## Carrega as traduções (uma vez) e aplica o idioma salvo.
static func apply_saved() -> void:
	for path in FILES:
		var translation := load(path) as Translation
		if translation and not TranslationServer.get_loaded_locales().has(translation.locale):
			TranslationServer.add_translation(translation)
	var cfg := ConfigFile.new()
	cfg.load(PREFS)
	TranslationServer.set_locale(str(cfg.get_value("ui", "locale", DEFAULT)))


static func current() -> String:
	return TranslationServer.get_locale()


## Índice em LOCALES do idioma atual (pt_BR e variações caem no português).
static func index() -> int:
	return 1 if current().begins_with("en") else 0


static func set_language(code: String) -> void:
	TranslationServer.set_locale(code)
	var cfg := ConfigFile.new()
	cfg.load(PREFS)  # mantém as outras seções
	cfg.set_value("ui", "locale", code)
	cfg.save(PREFS)


## Seletor pronto para as telas de opções.
static func selector() -> OptionButton:
	var button := OptionButton.new()
	button.name = "Language"
	for entry: Array in LOCALES: button.add_item(str(entry[1]))
	button.selected = index()
	button.item_selected.connect(func(i: int) -> void: set_language(str(LOCALES[i][0])))
	return button

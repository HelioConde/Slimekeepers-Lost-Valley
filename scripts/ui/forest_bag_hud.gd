extends PanelContainer
## Exibe somente o inventario simples de sessao, em ambas as regioes.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const TOTAL_PATCHES := 3
var _counter: Label

func _ready() -> void:
	name = "ForagingBagPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Logo abaixo do painel da missão e só da largura do texto (antes: faixa de
	# 742 px atravessando o topo da tela).
	offset_left = 18
	offset_right = 18
	offset_top = 52
	offset_bottom = 52
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("#f6e8c2")
	skin.border_color = Color("#694657")
	skin.set_border_width_all(2)
	skin.set_corner_radius_all(4)
	skin.set_content_margin_all(4)
	skin.content_margin_left = 7
	skin.content_margin_right = 7
	add_theme_stylebox_override("panel", skin)
	_counter = Label.new()
	_counter.name = "InventoryCount"
	_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter.add_theme_font_override("font", FONT)
	_counter.add_theme_font_size_override("font_size", 13)
	_counter.add_theme_color_override("font_color", Color("#3e5c43"))
	add_child(_counter)
	refresh()

func refresh() -> void:
	if is_instance_valid(_counter):
		var text := "Bolsa · sementes %d/%d · folhas frescas %d · porções %d · preparos %d" % [BAG.seeds(get_tree()), TOTAL_PATCHES, BAG.leaves(get_tree()), BAG.count_item(get_tree(), COOKING.RECIPE_ID), COOKING.portions(get_tree())]
		# Colheitas da fazenda aparecem quando existem.
		for crop in ["cenoura", "beterraba", "repolho"]:
			var amount := BAG.count_item(get_tree(), crop)
			if amount > 0: text += " · %s %d" % [crop, amount]
		_counter.text = text

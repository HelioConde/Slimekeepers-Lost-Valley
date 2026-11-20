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
	offset_left = 18
	offset_right = 760
	offset_top = 100
	offset_bottom = 135
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("#f6e8c2")
	skin.border_color = Color("#694657")
	skin.set_border_width_all(2)
	skin.set_corner_radius_all(4)
	skin.set_content_margin_all(5)
	add_theme_stylebox_override("panel", skin)
	_counter = Label.new()
	_counter.name = "InventoryCount"
	_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter.add_theme_font_override("font", FONT)
	_counter.add_theme_font_size_override("font_size", 15)
	_counter.add_theme_color_override("font_color", Color("#3e5c43"))
	add_child(_counter)
	refresh()

func refresh() -> void:
	if is_instance_valid(_counter):
		_counter.text = "Bolsa · sementes %d/%d · folhas frescas %d · porcoes %d · preparos %d" % [BAG.seeds(get_tree()), TOTAL_PATCHES, BAG.leaves(get_tree()), BAG.count_item(get_tree(), COOKING.RECIPE_ID), COOKING.portions(get_tree())]

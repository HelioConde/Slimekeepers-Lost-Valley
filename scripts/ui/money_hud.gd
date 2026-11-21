extends PanelContainer
## Dinheiro do jogador sob a barra de energia (ícone de moeda + valor).

const SHIP := preload("res://scripts/systems/shipping_state.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const COIN := preload("res://assets/ui/items/moeda.png")

var label: Label


func _ready() -> void:
	name = "MoneyPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -18
	offset_right = -18
	offset_top = 154
	offset_bottom = 154
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("#f6e8c2")
	skin.border_color = Color("#694657")
	skin.set_border_width_all(2)
	skin.set_corner_radius_all(4)
	skin.set_content_margin_all(2)
	skin.content_margin_right = 8
	add_theme_stylebox_override("panel", skin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var icon := TextureRect.new()
	icon.texture = COIN
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	label = Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("#3e2a1c"))
	row.add_child(label)
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	if is_inside_tree():
		label.text = "%d" % SHIP.money(get_tree())

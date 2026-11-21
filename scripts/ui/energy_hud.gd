extends PanelContainer
## Barra de energia sob o relógio: verde cheia, amarela pela metade, vermelha baixa.

const ENERGY := preload("res://scripts/systems/energy_state.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")

var bar: ProgressBar
var _fill: StyleBoxFlat


func _ready() -> void:
	name = "EnergyBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -195
	offset_right = -18
	offset_top = 128
	offset_bottom = 150
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("#f6e8c2")
	skin.border_color = Color("#694657")
	skin.set_border_width_all(2)
	skin.set_corner_radius_all(4)
	skin.set_content_margin_all(4)
	add_theme_stylebox_override("panel", skin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var label := Label.new()
	label.text = "Energia"
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#3e5c43"))
	row.add_child(label)
	bar = ProgressBar.new()
	bar.max_value = ENERGY.MAX
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(0, 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color("#8a6d5a")
	bar.add_theme_stylebox_override("background", back)
	_fill = StyleBoxFlat.new()
	bar.add_theme_stylebox_override("fill", _fill)
	row.add_child(bar)
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	if not is_inside_tree():
		return
	var value := ENERGY.current(get_tree())
	bar.value = value
	var ratio := float(value) / ENERGY.MAX
	_fill.bg_color = Color("#6aa84f") if ratio > 0.5 else (Color("#e8b04a") if ratio > 0.2 else Color("#c0533f"))

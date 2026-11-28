extends PanelContainer
## Energia sob o relógio (exemplo do usuário, 2026-11-23): raio, "Energia" e barra
## verde em painel de madeira; amarela pela metade, vermelha quando está baixa.

const ENERGY := preload("res://scripts/systems/energy_state.gd")
const SKIN := preload("res://scripts/ui/hud_skin.gd")

var bar: ProgressBar
var _fill: StyleBoxFlat


func _ready() -> void:
	name = "EnergyBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -232
	offset_right = -18
	offset_top = 134
	offset_bottom = 198
	add_theme_stylebox_override("panel", SKIN.panel(16, 8))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	row.add_child(SKIN.icon("res://assets/ui/hud/icon_energy.png", 26))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(column)
	column.add_child(SKIN.label("Energia", 14))
	bar = ProgressBar.new()
	bar.max_value = ENERGY.MAX
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color("#4a3428")
	back.border_color = Color("#2b1d16")
	back.set_border_width_all(1)
	back.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", back)
	_fill = StyleBoxFlat.new()
	_fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", _fill)
	column.add_child(bar)
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	if not is_inside_tree():
		return
	var value := ENERGY.current(get_tree())
	bar.value = value
	var ratio := float(value) / ENERGY.MAX
	_fill.bg_color = Color("#7ed957") if ratio > 0.5 else (Color("#e8b04a") if ratio > 0.2 else Color("#c0533f"))

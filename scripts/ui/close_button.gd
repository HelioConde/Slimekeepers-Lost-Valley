extends RefCounted
## Botão X no canto superior direito das janelas fechadas por Esc (playtest ID 03).
## Fica como filho top_level do painel: o Container não o redimensiona e ele acompanha o
## painel (posição/tamanho). MOUSE_FILTER_STOP: o clique não chega ao mundo.

const FONT := preload("res://assets/fonts/ui_font.tres")  # dígitos legíveis (playtest ID 33)
const SIZE := Vector2(22, 22)
const INSET := 8.0


static func attach(panel: Control, on_close: Callable) -> Button:
	var button := Button.new()
	button.name = "CloseButton"
	button.text = "X"
	button.top_level = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.tooltip_text = "Fechar (Esc)"
	button.custom_minimum_size = SIZE
	button.size = SIZE
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#f2dcae"))
	button.add_theme_color_override("font_hover_color", Color("#f2c46d"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#2e2019")
	normal.border_color = Color("#8a5a36")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(3)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = Color("#f2c46d")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(on_close)
	panel.add_child(button)
	var place := func() -> void:
		button.global_position = panel.global_position + Vector2(panel.size.x - SIZE.x - INSET, INSET)
	panel.item_rect_changed.connect(place)
	panel.draw.connect(place)
	place.call()
	return button

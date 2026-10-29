extends RefCounted
## Paleta compartilhada: madeira, marfim, ameixa e menta.
const INK := Color("#49303b")
const CREAM := Color("#f5dfaa")
const MINT := Color("#a4d794")

static func font(bold: bool = false) -> Font:
	var base := load("res://assets/fonts/PixelifySans.ttf") as FontFile
	base.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	base.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	var variation := FontVariation.new()
	variation.base_font = base
	variation.variation_opentype = {"wght": 700.0 if bold else 400.0}
	return variation

static func panel(margin: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = INK
	style.set_border_width_all(4)
	style.border_width_bottom = 7
	style.set_corner_radius_all(8)
	style.anti_aliasing = false
	style.shadow_color = Color(0.12, 0.12, 0.14, 0.4)
	style.shadow_size = 4
	style.shadow_offset = Vector2(3, 5)
	style.set_content_margin_all(margin)
	return style

static func button(state: StringName) -> StyleBoxFlat:
	var style := panel(10)
	style.bg_color = Color("#9c693f")
	style.set_border_width_all(3)
	style.border_width_bottom = 6
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 4)
	if state == &"hover" or state == &"pressed":
		style.bg_color = Color("#a77445") if state == &"hover" else Color("#765037")
	elif state == &"focus":
		style.draw_center = false
		style.border_color = MINT
		style.shadow_color = Color(0.64, 0.88, 0.5, 0.23)
		style.shadow_size = 5
	elif state == &"disabled":
		style.bg_color = Color("#997956")
		style.border_color = Color("#664e49")
	return style

static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = font()
	theme.default_font_size = 24
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		theme.set_stylebox(state, "Button", button(state))
	for state in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color"]:
		theme.set_color(state, "Button", Color("#fff0d0"))
	theme.set_color("font_disabled_color", "Button", Color("#dac5a2"))
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "CheckButton", Color("#fff0d0"))
	theme.set_stylebox("panel", "PanelContainer", panel())
	theme.set_stylebox("panel", "TooltipPanel", panel(12))
	theme.set_color("font_color", "TooltipLabel", INK)
	theme.set_font_size("font_size", "TooltipLabel", 18)
	return theme

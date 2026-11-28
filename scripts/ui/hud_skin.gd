extends RefCounted
## Visual do HUD (exemplo do usuário, 2026-11-23): painéis de madeira com folhas e
## cogumelos nos cantos (PixelLab, assets/ui/hud/leafy_panel.png), texto marrom
## escuro, espaços escuros na barra com número e seleção dourada.

const FONT := preload("res://assets/fonts/ui_font.tres")  # dígitos legíveis (playtest ID 33)
const PANEL := "res://assets/ui/hud/leafy_panel.png"
const INK := Color("#3d2a1e")
const CREAM := Color("#f2dcae")
const GOLD := Color("#f2c46d")


## Painel de madeira (nine-slice: as folhas ficam nos cantos, o meio estica).
static func panel(content_x: float = 18.0, content_y: float = 12.0) -> StyleBox:
	if not ResourceLoader.exists(PANEL):
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color("#d89f68")
		flat.border_color = Color("#5a3a26")
		flat.set_border_width_all(3)
		flat.set_corner_radius_all(4)
		flat.set_content_margin_all(content_y)
		return flat
	var box := StyleBoxTexture.new()
	box.texture = load(PANEL)
	box.texture_margin_left = 50
	box.texture_margin_right = 50
	box.texture_margin_top = 30
	box.texture_margin_bottom = 34
	box.content_margin_left = content_x
	box.content_margin_right = content_x
	box.content_margin_top = content_y
	box.content_margin_bottom = content_y
	return box


## Plaqueta clara (ex.: "Manhã" sob o relógio).
static func plaque() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = CREAM
	box.border_color = Color("#7a5236")
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 1
	box.content_margin_bottom = 1
	return box


## Espaço da barra rápida: madeira escura com borda clara; o selecionado em dourado.
static func slot(selected: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#2e2019")
	box.border_color = GOLD if selected else Color("#8a5a36")
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 1
	return box


static func label(text: String, size: int, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func icon(path: String, size: int) -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture = load(path) if ResourceLoader.exists(path) else null
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(size, size)
	return rect


## Coração em pixel art (7×6), cheio ou só contorno.
static func heart(full: bool) -> ImageTexture:
	var rows := [".XX.XX.", "XOOXOOX", "XOOOOOX", ".XOOOX.", "..XOX..", "...X..."]
	var image := Image.create(7, 6, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 7:
			var c: String = rows[y][x]
			if c == "X": image.set_pixel(x, y, Color("#5c1a1f"))
			elif c == "O": image.set_pixel(x, y, Color("#e0393e") if full else Color("#f3e2c8"))
	if full: image.set_pixel(2, 1, Color("#ff9a8a"))  # brilho
	return ImageTexture.create_from_image(image)

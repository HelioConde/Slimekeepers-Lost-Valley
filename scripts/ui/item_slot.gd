extends PanelContainer
## Espaço de item em grade (mochila e fabricação): ícone, quantidade e uma dica
## que aparece ao passar o mouse (nome + detalhes). Clique esquerdo = `clicked`.

signal clicked
## Arrastar um espaço sobre outro (mochila e barra, item 42): de -> para.
signal swapped(from: int, to: int)

const FONT := preload("res://assets/fonts/ui_font.tres")  # dígitos legíveis (playtest ID 33)
const SIZE := Vector2(48, 48)  # igual à barra rápida

var info_title := ""
## Índice do espaço na bolsa (0-19) para arrastar; -1 = não arrasta (fabricação).
var slot_index := -1
var info_body := ""
var _icon: TextureRect
var _count: Label
var _ring: Panel


func _init() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", slot_style())
	_icon = TextureRect.new()
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # 32 px nativo, sem borrar
	_icon.custom_minimum_size = Vector2(32, 32)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_count = Label.new()
	_count.add_theme_font_override("font", FONT)
	_count.add_theme_font_size_override("font_size", 11)
	_count.add_theme_color_override("font_color", Color("#fff6dc"))
	_count.add_theme_color_override("font_outline_color", Color("#2b1d16"))
	_count.add_theme_constant_override("outline_size", 3)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count)
	_ring = Panel.new()
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = Color("#f2c46d")
	ring.set_border_width_all(2)
	ring.set_corner_radius_all(3)
	_ring.add_theme_stylebox_override("panel", ring)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ring)


## Moldura do espaço: igual à barra rápida (madeira escura, borda clara).
static func slot_style() -> StyleBox:
	var box := preload("res://scripts/ui/hud_skin.gd").slot(false)
	box.set_content_margin_all(6)
	return box


func setup(icon: Texture2D, count: int, selected: bool, title: String, body: String, dim: bool = false) -> void:
	_icon.texture = icon
	_icon.modulate = Color(1, 1, 1, 0.4) if dim else Color.WHITE
	_count.text = str(count) if count > 1 else ""
	_ring.visible = selected
	info_title = title
	info_body = body
	tooltip_text = title  # não vazio: liga a dica personalizada abaixo


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		accept_event()


func _get_drag_data(_at: Vector2) -> Variant:
	if slot_index < 0 or _icon.texture == null: return null
	var preview := TextureRect.new()
	preview.texture = _icon.texture
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.modulate.a = 0.85
	set_drag_preview(preview)
	return {"bag_slot": slot_index}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return slot_index >= 0 and data is Dictionary and (data as Dictionary).has("bag_slot")


func _drop_data(_at: Vector2, data: Variant) -> void:
	swapped.emit(int(data.bag_slot), slot_index)


func _make_custom_tooltip(_for_text: String) -> Object:
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2b1d16f0")
	style.border_color = Color("#a57a52")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	box.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	box.add_child(column)
	var head := Label.new()
	head.text = info_title
	head.add_theme_font_override("font", FONT)
	head.add_theme_font_size_override("font_size", 13)
	head.add_theme_color_override("font_color", Color("#f2c46d"))
	column.add_child(head)
	if not info_body.is_empty():
		var body := Label.new()
		body.text = info_body
		body.add_theme_font_override("font", FONT)
		body.add_theme_font_size_override("font_size", 11)
		body.add_theme_color_override("font_color", Color("#f6e8c2"))
		column.add_child(body)
	return box

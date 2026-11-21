extends PanelContainer
## Barra rápida na parte de baixo da tela: 10 espaços com ícone, quantidade e o
## selecionado destacado. Teclas 1–9 e 0 ou a roda do mouse escolhem o espaço.

const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const SLOT := 36
const REFRESH_SECONDS := 0.25

var _slots: Array[PanelContainer] = []
var _icons: Array[TextureRect] = []
var _counts: Array[Label] = []
var _name_label: Label
var _elapsed := 0.0
## Label de dica da região: quando traz uma ação ("[E] ..."), aparece no título.
var hint_source: Label


func _ready() -> void:
	name = "Hotbar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Centralizada, logo acima da linha de dicas (que ocupa os últimos 44 px).
	var width := HOTBAR.SLOTS * SLOT + (HOTBAR.SLOTS - 1) * 2 + 6
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -width * 0.5
	offset_right = width * 0.5
	offset_bottom = -8
	offset_top = -8 - (SLOT + 22)
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#694657")
	frame.set_corner_radius_all(4)
	frame.set_content_margin_all(3)
	add_theme_stylebox_override("panel", frame)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 1)
	add_child(column)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_override("font", FONT)
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color("#f6e8c2"))
	column.add_child(_name_label)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 2)
	column.add_child(row)
	for index in HOTBAR.SLOTS:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(SLOT, SLOT)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(slot)
		var icon := TextureRect.new()
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		var count := Label.new()
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count.add_theme_font_override("font", FONT)
		count.add_theme_font_size_override("font_size", 11)
		count.add_theme_color_override("font_color", Color("#3e2a1c"))
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(count)
		var key := Label.new()
		key.text = str((index + 1) % 10)
		key.add_theme_font_override("font", FONT)
		key.add_theme_font_size_override("font_size", 9)
		key.add_theme_color_override("font_color", Color("#8a6d5a"))
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(key)
		_slots.append(slot)
		_icons.append(icon)
		_counts.append(count)
	refresh()


func _process(delta: float) -> void:
	_update_title()
	_elapsed += delta
	if _elapsed >= REFRESH_SECONDS:
		_elapsed = 0.0
		refresh()


func _unhandled_input(event: InputEvent) -> void:
	var tree := get_tree()
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode >= KEY_0 and key.physical_keycode <= KEY_9:
		HOTBAR.select(tree, (key.physical_keycode - KEY_1) if key.physical_keycode != KEY_0 else 9)
		refresh()
		get_viewport().set_input_as_handled()
	var wheel := event as InputEventMouseButton
	if wheel and wheel.pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		HOTBAR.select(tree, HOTBAR.selected_index(tree) + (1 if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1))
		refresh()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var items := HOTBAR.slots(tree)
	var selected := HOTBAR.selected_index(tree)
	for index in items.size():
		var item := items[index]
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#f6e8c2") if index != selected else Color("#fff6d8")
		style.border_color = Color("#e8b04a") if index == selected else Color("#b99a7a")
		style.set_border_width_all(2 if index == selected else 1)
		style.set_corner_radius_all(3)
		_slots[index].add_theme_stylebox_override("panel", style)
		_icons[index].texture = ITEMS.icon(item) if not item.is_empty() else null
		var amount := HOTBAR.count(tree, item)
		_counts[index].text = str(amount) if amount > 0 else ""
	_update_title()


func _update_title() -> void:
	if not is_inside_tree():
		return
	var hint := hint_source.text if is_instance_valid(hint_source) else ""
	if hint.begins_with("["):
		_name_label.text = hint
		_name_label.add_theme_color_override("font_color", Color("#ffd98a"))
		return
	var current := HOTBAR.selected_item(get_tree())
	_name_label.text = str(ITEMS.info(current).name) if not current.is_empty() else "Mão livre"
	_name_label.add_theme_color_override("font_color", Color("#f6e8c2"))

extends PanelContainer
## Barra rápida na parte de baixo da tela: 10 espaços com ícone, quantidade e o
## selecionado destacado. Teclas 1–9 e 0 ou a roda do mouse escolhem o espaço.

const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const FONT := preload("res://assets/fonts/ui_font.tres")  # dígitos legíveis (playtest ID 33)
const SKIN := preload("res://scripts/ui/hud_skin.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const WINDOWS := preload("res://scripts/ui/inventory_panel.gd").WINDOWS
const WEAR_BAR := preload("res://scripts/ui/wear_bar.gd")
const SLOT := 48
const REFRESH_SECONDS := 0.25

var _slots: Array[PanelContainer] = []
var _icons: Array[TextureRect] = []
var _counts: Array[Label] = []
var _rings: Array[Panel] = []
var _wears: Array[WEAR_BAR] = []
var _name_label: Label
var _elapsed := 0.0
## Label de dica da região: quando traz uma ação ("[F] ..."), aparece no título.
var hint_source: Label


func _ready() -> void:
	name = "Hotbar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Centralizada, logo acima da linha de dicas (que ocupa os últimos 44 px).
	var width := HOTBAR.SLOTS * SLOT + (HOTBAR.SLOTS - 1) * 3 + 44
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -width * 0.5
	offset_right = width * 0.5
	offset_bottom = -8
	offset_top = -8 - (SLOT + 44)
	# Painel de madeira com folhas (exemplo do usuário, 2026-11-23).
	add_theme_stylebox_override("panel", SKIN.panel(22, 9))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 1)
	add_child(column)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_override("font", FONT)
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_color_override("font_color", SKIN.INK)
	# Texto longo (dica do modo construção) não alarga a barra: corta com "…"; a dica
	# inteira já aparece na linha de dicas abaixo (playtest ID 37).
	_name_label.clip_text = true
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.custom_minimum_size.x = width - 44
	column.add_child(_name_label)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 3)
	column.add_child(row)
	for index in HOTBAR.SLOTS:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(SLOT, SLOT)
		# Clique no espaço escolhe o item (além de 1–0 e da roda do mouse); o clique não vai
		# para o mundo (não golpeia nem pega nada por baixo da barra).
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot.gui_input.connect(func(event: InputEvent) -> void:
			var click := event as InputEventMouseButton
			if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
				HOTBAR.select(get_tree(), index)
				slot.accept_event())
		slot.add_theme_stylebox_override("panel", SKIN.slot(false))
		row.add_child(slot)
		var icon := TextureRect.new()
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Ícone no tamanho nativo (32 px), centrado: escala inteira, sem borrar.
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		var count := Label.new()
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count.add_theme_font_override("font", FONT)
		count.add_theme_font_size_override("font_size", 14)
		count.add_theme_color_override("font_color", Color("#fff6dc"))
		count.add_theme_color_override("font_outline_color", Color("#2b1d16"))
		count.add_theme_constant_override("outline_size", 3)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(count)
		var wear := WEAR_BAR.new()
		wear.name = "Wear"
		slot.add_child(wear)
		_wears.append(wear)
		# Número do espaço numa plaquinha clara no canto (como no exemplo).
		var badge := Label.new()
		badge.text = str((index + 1) % 10)  # 1–9 e 0, como as teclas (playtest ID 38)
		badge.add_theme_font_override("font", FONT)
		badge.add_theme_font_size_override("font_size", 10)
		badge.add_theme_color_override("font_color", SKIN.INK)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = SKIN.CREAM
		badge_style.border_color = Color("#7a5236")
		badge_style.set_border_width_all(1)
		badge_style.set_corner_radius_all(2)
		badge_style.content_margin_left = 2
		badge_style.content_margin_right = 2
		badge.add_theme_stylebox_override("normal", badge_style)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(badge)
		var ring := Panel.new()
		var ring_style := StyleBoxFlat.new()
		ring_style.draw_center = false
		ring_style.border_color = Color("#f2c46d")
		ring_style.set_border_width_all(2)
		ring_style.set_corner_radius_all(3)
		ring.add_theme_stylebox_override("panel", ring_style)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(ring)
		_rings.append(ring)
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
	if tree.get_meta("build_mode", false):
		return  # no modo construir, roda e teclas são da construção
	var key := event as InputEventKey
	# [Q] solta 1 do item escolhido; Shift+[Q], a pilha toda (playtest ID 21). Janela
	# aberta (mochila, fabricação, baú) usa o Q dela.
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_Q and _no_window_open():
		var item := HOTBAR.selected_item(tree)
		var drops := tree.get_first_node_in_group("item_drops")
		if drops and not item.is_empty():
			drops.call("drop_from_bag", item, BAG.count_item(tree, item) if key.shift_pressed else 1)
			refresh()
		get_viewport().set_input_as_handled()
		return
	if key and key.pressed and not key.echo and key.physical_keycode >= KEY_0 and key.physical_keycode <= KEY_9:
		HOTBAR.select(tree, (key.physical_keycode - KEY_1) if key.physical_keycode != KEY_0 else 9)
		refresh()
		get_viewport().set_input_as_handled()
	var wheel := event as InputEventMouseButton
	if wheel and wheel.pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		HOTBAR.select(tree, HOTBAR.selected_index(tree) + (1 if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1))
		refresh()
		get_viewport().set_input_as_handled()


func _no_window_open() -> bool:
	for sibling in get_parent().get_children():
		if sibling is Control and (sibling as Control).visible and str(sibling.name) in WINDOWS: return false
	return true


func refresh() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var items := HOTBAR.slots(tree)
	var selected := HOTBAR.selected_index(tree)
	for index in items.size():
		var item := items[index]
		_rings[index].visible = index == selected
		_slots[index].add_theme_stylebox_override("panel", SKIN.slot(index == selected))
		_icons[index].texture = ITEMS.icon(item) if not item.is_empty() else null
		var amount := HOTBAR.count(tree, item)
		_counts[index].text = str(amount) if amount > 0 else ""
		_wears[index].show_for(tree, item)
	_update_title()


func _update_title() -> void:
	if not is_inside_tree():
		return
	var hint := hint_source.text if is_instance_valid(hint_source) else ""
	if hint.begins_with("["):
		_name_label.text = hint
		_name_label.add_theme_color_override("font_color", Color("#7a2e12"))
		return
	var current := HOTBAR.selected_item(get_tree())
	_name_label.text = str(ITEMS.info(current).name) if not current.is_empty() else "Mão livre"
	_name_label.add_theme_color_override("font_color", SKIN.INK)

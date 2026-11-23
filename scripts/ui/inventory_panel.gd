extends PanelContainer
## Mochila (pedido do usuário, 2026-11-22): [E] abre/fecha. 10 espaços em grade
## (mesma ordem da barra rápida); passar o mouse mostra nome e detalhes do item;
## clicar num espaço o escolhe na barra. Esc também fecha.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const SLOT := preload("res://scripts/ui/item_slot.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const COLUMNS := 5
## Janelas que travam o jogador (só uma aberta por vez).
const WINDOWS := ["InventoryPanel", "CraftingPanel", "ChestPanel"]

signal changed

var player: Node
var _grid: GridContainer
var _status: Label


func _ready() -> void:
	name = "InventoryPanel"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_stylebox_override("panel", panel_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	column.add_child(_label("Mochila", 16, Color("#3d2a1e"), true))
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	column.add_child(_grid)
	_status = _label("", 11, Color("#5a3f2c"), true)
	column.add_child(_status)


## Fundo das janelas: arte do PixelLab (nine-slice) ou um quadro liso de reserva.
static func panel_style() -> StyleBox:
	var art := "res://assets/ui/hud/panel.png"
	if ResourceLoader.exists(art):
		var box := StyleBoxTexture.new()
		box.texture = load(art)
		box.set_texture_margin_all(24)
		box.set_content_margin_all(18)
		return box
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color("#e8d3a8")
	flat.border_color = Color("#7a5236")
	flat.set_border_width_all(3)
	flat.set_corner_radius_all(4)
	flat.set_content_margin_all(12)
	return flat


func open() -> void:
	visible = true
	_freeze(true)
	refresh()


func close() -> void:
	visible = false
	_freeze(false)


func _freeze(on: bool) -> void:
	if is_instance_valid(player):
		player.set_physics_process(not on)
		if on and "velocity" in player: player.velocity = Vector2.ZERO


func refresh() -> void:
	for child in _grid.get_children(): child.queue_free()
	var slots := HOTBAR.slots(get_tree())
	var current := HOTBAR.selected_index(get_tree())
	for i in slots.size():
		var item: String = slots[i]
		var slot := SLOT.new()
		if item.is_empty():
			slot.setup(null, 0, i == current, "Espaço vazio", "")
		else:
			var amount := BAG.count_item(get_tree(), item)
			var body := ITEMS.describe(item) + ("" if amount <= 1 else "\nQuantidade: %d" % amount)
			slot.setup(ITEMS.icon(item), amount, i == current, str(ITEMS.info(item).name), body)
		slot.clicked.connect(_pick.bind(i))
		_grid.add_child(slot)
	_status.text = "Espaços: %d/%d   ·   E / Esc fechar" % [BAG.used_slots(get_tree()), BAG.SLOTS]
	_center.call_deferred()


func _pick(index: int) -> void:
	HOTBAR.select(get_tree(), index)
	refresh()
	changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not event.is_echo():
		if visible: close()
		elif _others_closed(): open()
		else: return
		get_viewport().set_input_as_handled()
	elif visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


## Não abre por cima de outra janela (fabricação, baú).
func _others_closed() -> bool:
	for sibling in get_parent().get_children():
		if sibling != self and sibling is PanelContainer and sibling.visible and str(sibling.name) in WINDOWS:
			return false
	return true


## Centraliza na tela depois que a grade muda de tamanho.
func _center() -> void:
	reset_size()
	position = ((get_parent_area_size() - size) * 0.5).round()


func _label(text: String, size: int, color: Color, center: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if center: label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

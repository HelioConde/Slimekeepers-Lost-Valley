extends PanelContainer
## Mochila (pedido do usuário, 2026-11-22 e 2026-11-27): só [E] abre/fecha. Em cima, os
## 10 espaços da mochila; embaixo, os 10 da barra rápida. Passar o mouse mostra nome e
## detalhes; clicar escolhe (na barra, também seleciona na mão); arrastar troca de lugar
## (playtest ID 42). Esc também fecha.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const SLOT := preload("res://scripts/ui/item_slot.gd")
const FONT := preload("res://assets/fonts/ui_font.tres")  # dígitos legíveis (playtest ID 33)
const COLUMNS := 5
const CLOSE_BUTTON := preload("res://scripts/ui/close_button.gd")
## Janelas que travam o jogador (só uma aberta por vez).
const WINDOWS := ["InventoryPanel", "CraftingPanel", "ChestPanel"]

signal changed

var player: Node
var _grid: GridContainer  ## mochila (espaços 11-20)
var _bar_grid: GridContainer  ## barra rápida (espaços 1-10)
var _picked := -1  ## espaço escolhido na janela (0-19)
var _status: Label
var _amount: SpinBox
var _drop_button: Button


func _ready() -> void:
	name = "InventoryPanel"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_stylebox_override("panel", panel_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	column.add_child(_label("Mochila", 16, Color("#3d2a1e"), true))
	_grid = _new_grid(COLUMNS)
	column.add_child(_grid)
	column.add_child(_label("Barra rápida", 13, Color("#3d2a1e"), true))
	_bar_grid = _new_grid(HOTBAR.SLOTS)
	column.add_child(_bar_grid)
	# Soltar no chão o item escolhido, na quantidade escolhida (playtest ID 21).
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	_amount = SpinBox.new()
	_amount.min_value = 1
	_amount.get_line_edit().focus_mode = Control.FOCUS_NONE  # [E]/[Q] não viram texto
	row.add_child(_amount)
	_drop_button = Button.new()
	_drop_button.name = "DropButton"
	_drop_button.text = "Soltar no chão"
	_drop_button.focus_mode = Control.FOCUS_NONE
	_drop_button.add_theme_font_override("font", FONT)
	_drop_button.pressed.connect(drop_selected)
	row.add_child(_drop_button)
	_status = _label("", 11, Color("#5a3f2c"), true)
	column.add_child(_status)
	CLOSE_BUTTON.attach(self, close)


## Fundo das janelas: o mesmo painel de madeira com folhas do HUD (referência do
## usuário, 2026-11-23), com mais margem para a grade.
static func panel_style() -> StyleBox:
	return preload("res://scripts/ui/hud_skin.gd").panel(30, 22)


func _new_grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	return grid


func open() -> void:
	_picked = HOTBAR.selected_index(get_tree())
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
	for grid in [_grid, _bar_grid]:
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
	var slots := BAG.layout(get_tree())
	if _picked < 0: _picked = HOTBAR.selected_index(get_tree())
	for i in slots.size():
		var item: String = slots[i]
		var slot := SLOT.new()
		slot.name = "Slot%d" % i
		slot.slot_index = i
		if item.is_empty():
			slot.setup(null, 0, i == _picked, "Espaço vazio", "")
		else:
			var amount := BAG.count_item(get_tree(), item)
			var body := ITEMS.describe(item) + ("" if amount <= 1 else "
Quantidade: %d" % amount)
			slot.setup(ITEMS.icon(item), amount, i == _picked, str(ITEMS.info(item).name), body)
		slot.clicked.connect(_pick.bind(i))
		slot.swapped.connect(_swap)
		(_bar_grid if i < HOTBAR.SLOTS else _grid).add_child(slot)
	var have := BAG.count_item(get_tree(), picked_item())
	_amount.max_value = maxi(1, have)
	_amount.editable = have > 1
	_drop_button.disabled = have <= 0
	_status.text = "Espaços: %d/%d   ·   arraste para trocar   ·   Q soltar   ·   E / Esc fechar" % [BAG.used_slots(get_tree()), BAG.SLOTS]
	_center.call_deferred()


## Item do espaço escolhido na janela (mochila ou barra).
func picked_item() -> String:
	var slots := BAG.layout(get_tree())
	return slots[_picked] if _picked >= 0 and _picked < slots.size() else ""


func _pick(index: int) -> void:
	_picked = index
	if index < HOTBAR.SLOTS: HOTBAR.select(get_tree(), index)
	_amount.value = 1
	refresh()
	changed.emit()


## Solta no chão (item_drops.drop_from_bag) a quantidade escolhida do item selecionado.
func drop_selected() -> void:
	var drops := get_tree().get_first_node_in_group("item_drops")
	if drops and drops.call("drop_from_bag", picked_item(), int(_amount.value)):
		_amount.value = 1
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
	elif visible and event is InputEventKey and event.pressed and not event.is_echo() and (event as InputEventKey).physical_keycode == KEY_Q:
		drop_selected()
		get_viewport().set_input_as_handled()


## Arrastar e soltar: troca os dois espaços; a escolha acompanha o item arrastado.
func _swap(from: int, to: int) -> void:
	BAG.swap_slots(get_tree(), from, to)
	if _picked == from: _picked = to
	elif _picked == to: _picked = from
	if _picked < HOTBAR.SLOTS: HOTBAR.select(get_tree(), _picked)
	refresh()
	changed.emit()


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

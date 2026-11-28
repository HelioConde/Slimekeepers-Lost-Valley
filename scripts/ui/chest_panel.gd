extends PanelContainer
## Janela do baú (BACKLOG P2; playtest ID 45): duas colunas, bolsa do jogador à esquerda
## (barra rápida e mochila, na ordem de forest_bag.layout) e baú à direita.
## Mouse: arrastar move a pilha para a outra coluna (dentro da bolsa troca de lugar);
## clique = 1 unidade, Shift+clique = metade, Ctrl+clique = tudo.
## Teclado: ← → trocam o lado, ↑ ↓ escolhem o item, F move a pilha, E / Esc / Q fecham.

const CHEST := preload("res://scripts/systems/chest_storage.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const SLOT := preload("res://scripts/ui/item_slot.gd")
const FONT := preload("res://assets/fonts/ui_font.tres")  # dígitos legíveis (playtest ID 33)
const CLOSE_BUTTON := preload("res://scripts/ui/close_button.gd")
const COLUMNS := 5
const CHEST_ROWS := 4  ## altura visível da coluna do baú; mais itens rolam
const HELP := "Arraste para mover · clique: 1 · Shift+clique: metade · Ctrl+clique: tudo · E / Esc fechar"

signal changed

var player: Node
var side := 0  # 0 bolsa, 1 baú
var selected := 0
## "" = baú da casa; senão o id de um baú colocado no chão (station_placer).
var chest_id := ""
var _bar_grid: GridContainer
var _bag_grid: GridContainer
var _chest_grid: GridContainer
var _status: Label
var _press: Array = []  ## [lado, item] do clique em andamento; arrastar cancela


func _ready() -> void:
	name = "ChestPanel"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_stylebox_override("panel", preload("res://scripts/ui/inventory_panel.gd").panel_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	column.add_child(_label("Baú", 16, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	column.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	row.add_child(left)
	left.add_child(_label("Barra rápida", 13))
	_bar_grid = _new_grid()
	left.add_child(_bar_grid)
	left.add_child(_label("Mochila", 13))
	_bag_grid = _new_grid()
	left.add_child(_bag_grid)
	row.add_child(VSeparator.new())
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	row.add_child(right)
	right.add_child(_label("Baú", 13))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(COLUMNS * 52 + 12, CHEST_ROWS * 52)
	right.add_child(scroll)
	_chest_grid = _new_grid()
	scroll.add_child(_chest_grid)
	scroll.set_drag_forwarding(Callable(), _can_drop.bind(1), _drop.bind(1, -1))  # soltar no vazio
	_status = _label("", 12, true)
	column.add_child(_status)
	var help := _label(HELP, 11, true)
	help.add_theme_color_override("font_color", Color("#5a3f2c"))
	column.add_child(help)
	CLOSE_BUTTON.attach(self, close)


func open(id: String = "") -> void:
	chest_id = id
	side = 0
	selected = 0
	_status.text = ""
	visible = true
	_freeze(true)
	refresh()


func close() -> void:
	visible = false
	_freeze(false)


## Playtest ID 46: o conteúdo chega pela rede (NetWorld) com o baú aberto; redesenha ao mudar.
var _seen := 0


func _process(_delta: float) -> void:
	if not visible: return
	var now := hash([CHEST.items(get_tree(), chest_id), BAG.inventory_snapshot(get_tree()), BAG.layout(get_tree())])
	if now != _seen:
		_seen = now
		refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN: _press = []  # soltar o mouse depois de arrastar não é clique


func _freeze(on: bool) -> void:
	if is_instance_valid(player):
		player.set_physics_process(not on)
		if on and "velocity" in player: player.velocity = Vector2.ZERO


## [item, quantidade] de cada lado: bolsa na ordem dos espaços, baú em ordem alfabética.
func entries(which: int) -> Array:
	var out: Array = []
	if which == 0:
		for item in BAG.layout(get_tree()):
			if not item.is_empty(): out.append([item, BAG.count_item(get_tree(), item)])
		return out
	var data := CHEST.items(get_tree(), chest_id)
	var keys: Array = data.keys()
	keys.sort()
	for k in keys:
		if int(data[k]) > 0: out.append([str(k), int(data[k])])
	return out


func refresh() -> void:
	for grid in [_bar_grid, _bag_grid, _chest_grid]:
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
	var list := entries(side)
	selected = clampi(selected, 0, maxi(0, list.size() - 1))
	var mark: String = list[selected][0] if not list.is_empty() else ""
	var slots := BAG.layout(get_tree())
	for i in slots.size():
		var item: String = slots[i]
		(_bar_grid if i < BAG.BAR else _bag_grid).add_child(_slot(0, i, item, BAG.count_item(get_tree(), item) if not item.is_empty() else 0, side == 0 and item == mark))
	var stored := entries(1)
	for i in maxi(CHEST_ROWS * COLUMNS, ceili((stored.size() + 1) / float(COLUMNS)) * COLUMNS):
		var item: String = stored[i][0] if i < stored.size() else ""
		_chest_grid.add_child(_slot(1, i, item, stored[i][1] if i < stored.size() else 0, side == 1 and item == mark))
	_center.call_deferred()


func _slot(which: int, index: int, item: String, amount: int, ring: bool) -> Control:
	var slot := SLOT.new()
	slot.name = ("Bag%d" if which == 0 else "Chest%d") % index
	if item.is_empty(): slot.setup(null, 0, false, "Espaço vazio", "")
	else: slot.setup(ITEMS.icon(item), amount, ring, str(ITEMS.info(item).get("name", item)), ITEMS.describe(item) + ("" if amount <= 1 else "\nQuantidade: %d" % amount))
	slot.set_drag_forwarding(_drag.bind(which, index, item, slot), _can_drop.bind(which), _drop.bind(which, index))
	slot.gui_input.connect(_slot_input.bind(which, item, slot))
	return slot


## Quantidade de um clique: 1, Shift = metade (arredonda para cima), Ctrl = tudo.
static func click_amount(have: int, shift: bool, ctrl: bool) -> int:
	if ctrl: return have
	if shift: return ceili(have / 2.0)
	return mini(1, have)


## Move `amount` (-1 = tudo) do item do lado `which` para o outro; devolve quantos moveu.
func transfer(which: int, item: String, amount: int = -1) -> int:
	if item.is_empty(): return 0
	var moved: int = CHEST.store(get_tree(), item, chest_id, amount) if which == 0 else CHEST.take(get_tree(), item, chest_id, amount)
	_status.text = ("Guardou %d" if which == 0 else "Pegou %d") % moved + " " + str(ITEMS.info(item).get("name", item)).to_lower() + ("." if moved > 0 else " (bolsa cheia)." if which == 1 else ".")
	refresh()
	changed.emit()
	return moved


## Move a pilha escolhida pelo teclado para o outro lado; devolve quantos moveu.
func move_selected() -> int:
	var list := entries(side)
	if list.is_empty(): return 0
	return transfer(side, list[clampi(selected, 0, list.size() - 1)][0])


## Clique age ao soltar o botão (no mesmo espaço), para não brigar com o arrastar.
func _slot_input(event: InputEvent, which: int, item: String, slot: Control) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT or item.is_empty(): return
	if mb.pressed:
		_press = [which, item]
		return
	if _press != [which, item] or not Rect2(Vector2.ZERO, slot.size).has_point(mb.position): return
	_press = []
	var have: int = BAG.count_item(get_tree(), item) if which == 0 else CHEST.count(get_tree(), item, chest_id)
	transfer(which, item, click_amount(have, mb.shift_pressed, mb.ctrl_pressed))


func _drag(_at: Vector2, which: int, index: int, item: String, slot: Control) -> Variant:
	if item.is_empty(): return null
	var preview := TextureRect.new()
	preview.texture = ITEMS.icon(item)
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.modulate.a = 0.85
	slot.set_drag_preview(preview)
	# Mesma chave do item_slot ("bag_slot") para espaços da bolsa.
	return {"bag_slot": index} if which == 0 else {"chest_item": item}


func _can_drop(_at: Vector2, data: Variant, _which: int) -> bool:
	return data is Dictionary and ((data as Dictionary).has("bag_slot") or (data as Dictionary).has("chest_item"))


## Soltar na bolsa: da bolsa troca de lugar, do baú pega a pilha (no espaço solto, se vazio).
## Soltar no baú: da bolsa guarda a pilha.
func _drop(_at: Vector2, data: Variant, which: int, index: int) -> void:
	var tree := get_tree()
	if data.has("bag_slot"):
		var from := int(data.bag_slot)
		if which == 0:
			BAG.swap_slots(tree, from, index)
			refresh()
			changed.emit()
		else:
			transfer(0, BAG.layout(tree)[from])
		return
	var item := str(data.chest_item)
	if which == 1: return
	var had := BAG.count_item(tree, item) > 0
	if transfer(1, item) > 0 and not had and index >= 0 and BAG.layout(tree)[index].is_empty():
		BAG.swap_slots(tree, BAG.layout(tree).find(item), index)
		refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo: return
	match key.physical_keycode:
		KEY_ESCAPE, KEY_Q, KEY_E: close()
		KEY_LEFT, KEY_A: side = 0
		KEY_RIGHT, KEY_D: side = 1
		KEY_UP, KEY_W: selected -= 1
		KEY_DOWN, KEY_S: selected += 1
		KEY_F, KEY_ENTER: move_selected()
		_: return
	if visible: refresh()
	get_viewport().set_input_as_handled()


func _new_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	return grid


## Centraliza na tela depois que a grade muda de tamanho (como a mochila).
func _center() -> void:
	reset_size()
	position = ((get_parent_area_size() - size) * 0.5).round()


func _label(text: String, size: int, center: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#3d2a1e"))
	if center: label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

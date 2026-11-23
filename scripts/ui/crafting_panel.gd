extends PanelContainer
## Janela de fabricação (CRIACAO.md). [B] abre as receitas "maos" em qualquer lugar;
## a bancada abre "bancada" e o fogão "fogao". Receitas em grade (pedido do usuário,
## 2026-11-22): passar o mouse mostra ingredientes (tem/precisa) e o que falta;
## clicar fabrica. Setas escolhem, F/Enter fabricam, B/E/Esc fecham. Com as mãos,
## o botão "Construir casa" entra no modo construir da casa (house_builder.gd).

signal crafted(recipe_id: String)

const CRAFTING := preload("res://scripts/systems/crafting.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const SLOT := preload("res://scripts/ui/item_slot.gd")
const INVENTORY := preload("res://scripts/ui/inventory_panel.gd")
const COLUMNS := 5
const WINDOWS := INVENTORY.WINDOWS
const TITLES := {"maos": "Fabricar com as mãos", "bancada": "Bancada de trabalho", "fogao": "Fogão"}

var station := "maos"
## Jogador congelado enquanto a janela está aberta (W/S/E navegam aqui).
var player: Node
var selected := 0
var _title: Label
var _list: GridContainer
var _status: Label
var _rows: Array[Dictionary] = []
var builder: Node2D  ## casa da região (clearing_region.add_player_house)
var _build: Button


func _ready() -> void:
	name = "CraftingPanel"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_stylebox_override("panel", INVENTORY.panel_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	_title = _label(16, Color("#3d2a1e"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_list = GridContainer.new()
	_list.columns = COLUMNS
	_list.add_theme_constant_override("h_separation", 4)
	_list.add_theme_constant_override("v_separation", 4)
	column.add_child(_list)
	_status = _label(12, Color("#3d2a1e"))
	_status.custom_minimum_size = Vector2(COLUMNS * 48, 0)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	_build = Button.new()
	_build.text = "Construir casa"
	_build.tooltip_text = "Modo construir: paredes, chão, teto e móveis. [B] sai."
	_build.add_theme_font_override("font", FONT)
	_build.add_theme_font_size_override("font_size", 12)
	_build.focus_mode = Control.FOCUS_NONE
	_build.pressed.connect(start_building)
	column.add_child(_build)
	var help := _label(11, Color("#5a3f2c"))
	help.text = "Clique ou F fabrica · B / Esc fecha"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(help)


func open(new_station: String = "maos") -> void:
	station = new_station
	selected = 0
	visible = true
	_freeze(true)
	refresh()


## Fecha a janela e entra no modo construir da casa.
func start_building() -> void:
	if not is_instance_valid(builder): return
	close()
	if not builder.building: builder.toggle_build()


func close() -> void:
	visible = false
	_freeze(false)


func _freeze(on: bool) -> void:
	if is_instance_valid(player):
		player.set_physics_process(not on)
		if on and "velocity" in player: player.velocity = Vector2.ZERO


func refresh() -> void:
	_title.text = TITLES.get(station, "Fabricar")
	_build.visible = station == "maos" and is_instance_valid(builder)
	for child in _list.get_children(): child.queue_free()
	_rows.clear()
	var recipes: Array = CRAFTING.recipes(station)
	selected = clampi(selected, 0, maxi(0, recipes.size() - 1))
	for i in recipes.size():
		var r: Dictionary = recipes[i]
		var row := _make_row(r, i == selected)
		_list.add_child(row.node)
		_rows.append(row)
	if not recipes.is_empty():
		var r: Dictionary = recipes[selected]
		var why := CRAFTING.missing(get_tree(), str(r.id))
		_status.text = str(ITEMS.info(str(r.output.keys()[0])).name) + ": " + ("pronto para fazer." if why.is_empty() else why)
	_center.call_deferred()


func _make_row(r: Dictionary, current: bool) -> Dictionary:
	var output_id: String = r.output.keys()[0]
	var why := CRAFTING.missing(get_tree(), str(r.id))
	var lines: PackedStringArray = []
	for item_id: String in r.inputs:
		lines.append("%s %d/%d" % [str(ITEMS.info(item_id).name), BAG.count_item(get_tree(), item_id), int(r.inputs[item_id])])
	for tool_id: String in r.get("requires", []):
		lines.append("Precisa: " + str(ITEMS.info(tool_id).name).to_lower())
	lines.append(ITEMS.describe(output_id))
	lines.append("Clique para fazer" if why.is_empty() else why)
	var slot := SLOT.new()
	var amount := int(r.output[output_id])
	slot.setup(ITEMS.icon(output_id), amount, current, str(ITEMS.info(output_id).name), "
".join(lines), not why.is_empty())
	slot.clicked.connect(_craft.bind(str(r.id)))
	return {"node": slot, "id": str(r.id)}


func _craft(recipe_id: String) -> void:
	if CRAFTING.craft(get_tree(), recipe_id):
		var output_id: String = CRAFTING.recipe(recipe_id).output.keys()[0]
		refresh()
		_status.text = "Você fez: " + str(ITEMS.info(output_id).name).to_lower() + "."
		crafted.emit(recipe_id)
	else:
		refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = event.keycode
	if not visible:
		if key == KEY_B and not _other_window_open() and not bool(get_tree().get_meta("build_mode", false)):
			open("maos")
			get_viewport().set_input_as_handled()
		return
	match key:
		KEY_B, KEY_E, KEY_ESCAPE:
			close()
		KEY_LEFT, KEY_A:
			selected = maxi(0, selected - 1)
			refresh()
		KEY_RIGHT, KEY_D:
			selected = mini(_rows.size() - 1, selected + 1)
			refresh()
		KEY_UP, KEY_W:
			selected = maxi(0, selected - COLUMNS)
			refresh()
		KEY_DOWN, KEY_S:
			selected = mini(_rows.size() - 1, selected + COLUMNS)
			refresh()
		KEY_F, KEY_ENTER, KEY_KP_ENTER:
			if not _rows.is_empty(): _craft(str(_rows[selected].id))
		_:
			return
	get_viewport().set_input_as_handled()


func _other_window_open() -> bool:
	for sibling in get_parent().get_children():
		if sibling != self and sibling is PanelContainer and sibling.visible and str(sibling.name) in WINDOWS:
			return true
	return false


## Centraliza na tela depois que a grade muda de tamanho.
func _center() -> void:
	reset_size()
	position = ((get_parent_area_size() - size) * 0.5).round()


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

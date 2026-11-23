extends PanelContainer
## Janela de fabricação (CRIACAO.md). [C] abre as receitas "maos" em qualquer lugar;
## a bancada abre as receitas "bancada" (open("bancada")). Cada linha mostra o
## resultado, os ingredientes (tem/precisa) e o botão Fazer; ↑/↓ escolhem,
## E/Enter fabricam, C/Esc fecham. Mesmo estilo da barra rápida.

signal crafted(recipe_id: String)

const CRAFTING := preload("res://scripts/systems/crafting.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const TITLES := {"maos": "Fabricar com as mãos", "bancada": "Bancada de trabalho", "fogao": "Fogão"}

var station := "maos"
## Jogador congelado enquanto a janela está aberta (W/S/E navegam aqui).
var player: Node
var selected := 0
var _title: Label
var _list: VBoxContainer
var _status: Label
var _rows: Array[Dictionary] = []


func _ready() -> void:
	name = "CraftingPanel"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -190
	offset_right = 190
	offset_top = -100  # cresce sozinho com mais receitas
	offset_bottom = 100
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#694657")
	frame.set_corner_radius_all(4)
	frame.set_content_margin_all(8)
	add_theme_stylebox_override("panel", frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	_title = _label(16, Color("#f6e8c2"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	column.add_child(_list)
	_status = _label(12, Color("#f6e8c2"))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	var help := _label(11, Color("#d9c2a8"))
	help.text = "↑ ↓ escolher · E fabricar · C / Esc fechar"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(help)


func open(new_station: String = "maos") -> void:
	station = new_station
	selected = 0
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
	_title.text = TITLES.get(station, "Fabricar")
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
		var why := CRAFTING.missing(get_tree(), str(recipes[selected].id))
		_status.text = "Pronto para fazer." if why.is_empty() else why


func _make_row(r: Dictionary, current: bool) -> Dictionary:
	var output_id: String = r.output.keys()[0]
	var ok := CRAFTING.can_craft(get_tree(), str(r.id))
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f6e8c2") if current else Color("#8a6676")
	style.set_corner_radius_all(3)
	style.set_content_margin_all(3)
	box.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 6)
	box.add_child(line)
	var icon := TextureRect.new()
	icon.texture = ITEMS.icon(output_id)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(32, 32)
	line.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	line.add_child(text)
	var ink := Color("#3d2a33") if current else Color("#f6e8c2")
	var title := _label(13, ink)
	title.text = str(ITEMS.info(output_id).name)
	text.add_child(title)
	var parts: PackedStringArray = []
	for item_id: String in r.inputs:
		parts.append("%s %d/%d" % [str(ITEMS.info(item_id).name).to_lower(), BAG.count_item(get_tree(), item_id), int(r.inputs[item_id])])
	for tool_id: String in r.get("requires", []):
		parts.append("precisa: " + str(ITEMS.info(tool_id).name).to_lower())
	var needs := _label(11, ink)
	needs.text = " · ".join(parts)
	text.add_child(needs)
	var button := Button.new()
	button.text = "Fazer"
	button.disabled = not ok
	button.add_theme_font_override("font", FONT)
	button.pressed.connect(_craft.bind(str(r.id)))
	line.add_child(button)
	return {"node": box, "id": str(r.id)}


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
		if key == KEY_C:
			open("maos")
			get_viewport().set_input_as_handled()
		return
	match key:
		KEY_C, KEY_ESCAPE:
			close()
		KEY_UP, KEY_W:
			selected = maxi(0, selected - 1)
			refresh()
		KEY_DOWN, KEY_S:
			selected = mini(_rows.size() - 1, selected + 1)
			refresh()
		KEY_E, KEY_ENTER, KEY_KP_ENTER:
			if not _rows.is_empty(): _craft(str(_rows[selected].id))
		_:
			return
	get_viewport().set_input_as_handled()


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

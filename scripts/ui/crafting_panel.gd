extends PanelContainer
## Janela de fabricação (CRIACAO.md), no estilo da bancada do Palworld (pedido do usuário,
## 2026-11-23): abas por categoria em cima (Ferramentas e Comida só na bancada/fogão;
## Produção, Slimes, Armazenamento e Construção também no [B]), receitas em linhas por nível (1, 2...; o nível só organiza)
## e um painel à direita com nome, descrição, materiais (tem/precisa) e tempo de construção.
## [B] abre com as mãos; a bancada abre "bancada" (mãos + bancada) e o fogão "fogao".
## A casa é um item de Construção (ícone de casa): escolher entra no modo construir.
## Teclado: setas/WASD escolhem, Q/R trocam de aba, F/Enter fabricam, B/Esc fecham, E mochila.

signal crafted(recipe_id: String)

const CRAFTING := preload("res://scripts/systems/crafting.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const FONT := preload("res://assets/fonts/ui_font.tres")  # dígitos legíveis (playtest ID 33)
const SLOT := preload("res://scripts/ui/item_slot.gd")
const INVENTORY := preload("res://scripts/ui/inventory_panel.gd")
const PLACER := preload("res://scripts/world/station_placer.gd")
const COLUMNS := 5
const CLOSE_BUTTON := preload("res://scripts/ui/close_button.gd")
const WINDOWS := INVENTORY.WINDOWS
const TITLES := {"maos": "Fabricar com as mãos", "bancada": "Bancada de trabalho", "fogao": "Fogão"}
const CATEGORIES := [["ferramentas", "Ferramentas"], ["producao", "Produção"], ["slimes", "Slimes"],
	["armazenamento", "Armazenamento"], ["construcao", "Construção"], ["comida", "Comida"]]
## Abas de cada janela: [B] sem ferramentas nem comida; a bancada com ferramentas; o
## fogão só comida (pedido do usuário, 2026-11-23).
## Construção (casa, móveis) também só na bancada; no [B] só o básico: corda e a bancada.
const TABS := {"maos": ["producao"],
	"bancada": ["ferramentas", "producao", "slimes", "armazenamento", "construcao"], "fogao": ["comida"]}
## Entradas que não são receitas: abrem o modo construir da casa (house_builder.gd).
const SPECIALS := [
	{"id": "casa", "category": "construcao", "tier": 1, "name": "Casa", "mode": "house",
		"text": "Paredes, piso e porta: arraste no chão para erguer a casa. A cama salva o jogo."},
	{"id": "moveis", "category": "construcao", "tier": 1, "name": "Móveis da casa", "mode": "furniture",
		"text": "Cama, baú, fogão, mesa e outros móveis dentro da casa."},
	# Playtest IDs 47/48: a cama à vista na aba Construção; dormir nela recupera a energia e salva.
	{"id": "cama", "category": "construcao", "tier": 1, "name": "Cama", "mode": "furniture", "furniture_choice": "cama",
		"text": "Dentro da casa. Dormir na cama recupera toda a energia e salva o jogo (4 madeiras, 6 fibras)."},
]
## Onde cada estação libera receitas (o resto aparece com o aviso de onde fazer).
const ALLOWED := {"maos": ["maos"], "bancada": ["maos", "bancada"], "fogao": ["fogao"]}
const WHERE := {"bancada": "Faça na bancada de trabalho.", "fogao": "Faça no fogão da casa."}

var station := "maos"
## Jogador congelado enquanto a janela está aberta (W/S/E navegam aqui).
var player: Node
var selected := 0
var category := "producao"
var builder: Node2D  ## casa da região (clearing_region.add_player_house)
var _title: Label
var _tabs: HBoxContainer
var _tiers: VBoxContainer  ## linhas por nível da aba atual
var _status: Label
var _detail_name: Label
var _detail_text: Label
var _detail_mats: VBoxContainer
var _action: Button
var _rows: Array[Dictionary] = []  ## {node, id, special?} na ordem da navegação


func _ready() -> void:
	name = "CraftingPanel"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_stylebox_override("panel", INVENTORY.panel_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	_title = _label(16, Color("#3d2a1e"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 3)
	column.add_child(_tabs)
	for cat: Array in CATEGORIES:
		var tab := Button.new()
		tab.name = "Tab_" + str(cat[0])
		tab.text = str(cat[1])
		tab.toggle_mode = true
		tab.focus_mode = Control.FOCUS_NONE
		tab.add_theme_font_override("font", FONT)
		tab.add_theme_font_size_override("font_size", 11)
		tab.pressed.connect(func() -> void: show_category(str(cat[0])))
		_tabs.add_child(tab)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	column.add_child(body)
	_tiers = VBoxContainer.new()
	_tiers.add_theme_constant_override("separation", 6)
	_tiers.custom_minimum_size = Vector2(COLUMNS * 50 + 30, 120)
	body.add_child(_tiers)
	var detail := VBoxContainer.new()
	detail.custom_minimum_size = Vector2(190, 0)
	detail.add_theme_constant_override("separation", 4)
	body.add_child(detail)
	_detail_name = _label(14, Color("#3d2a1e"))
	detail.add_child(_detail_name)
	_detail_text = _label(11, Color("#5a3f2c"))
	_detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_text.custom_minimum_size = Vector2(190, 0)
	detail.add_child(_detail_text)
	_detail_mats = VBoxContainer.new()
	_detail_mats.add_theme_constant_override("separation", 1)
	detail.add_child(_detail_mats)
	_action = Button.new()
	_action.focus_mode = Control.FOCUS_NONE
	_action.add_theme_font_override("font", FONT)
	_action.add_theme_font_size_override("font_size", 12)
	_action.pressed.connect(func() -> void: _activate(selected))
	detail.add_child(_action)
	_status = _label(12, Color("#3d2a1e"))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(COLUMNS * 50 + 230, 0)
	column.add_child(_status)
	var help := _label(11, Color("#5a3f2c"))
	help.text = "Clique ou F fabrica · Q/R troca de aba · B / Esc fecha"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(help)
	CLOSE_BUTTON.attach(self, close)


func open(new_station: String = "maos") -> void:
	station = new_station
	selected = 0
	category = str(TABS.get(station, TABS.maos)[0])
	visible = true
	_freeze(true)
	refresh()


func close() -> void:
	visible = false
	_freeze(false)


## Fecha a janela e entra no modo construir da casa (mode: "house" ou "furniture").
func start_building(mode: String = "house", furniture: String = "") -> void:
	if not is_instance_valid(builder): return
	close()
	builder.set("mode", mode)
	if not furniture.is_empty(): builder.set("furniture_choice", furniture)
	if not builder.building: builder.toggle_build()


func show_category(cat: String) -> void:
	category = cat
	selected = 0
	refresh()


func _freeze(on: bool) -> void:
	if is_instance_valid(player):
		player.set_physics_process(not on)
		if on and "velocity" in player: player.velocity = Vector2.ZERO


## Entradas da aba atual: receitas e especiais, ordenadas por nível.
func entries(cat: String = category) -> Array:
	var out: Array = []
	for r: Dictionary in CRAFTING.recipes():
		if str(r.get("category", "producao")) == cat: out.append(r)
	for sp: Dictionary in SPECIALS:
		if str(sp.category) == cat and is_instance_valid(builder): out.append(sp)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("tier", 1)) < int(b.get("tier", 1)))
	return out


## Por que não dá para fazer aqui ("" = pode).
func why_not(r: Dictionary) -> String:
	if r.has("mode"): return "" if is_instance_valid(builder) else "Sem lugar para construir aqui."
	var where := str(r.get("station", "maos"))
	if not ALLOWED.get(station, ["maos"]).has(where): return str(WHERE.get(where, "Faça na estação certa."))
	return CRAFTING.missing(get_tree(), str(r.id))


func refresh() -> void:
	_title.text = TITLES.get(station, "Fabricar")
	var allowed: Array = TABS.get(station, TABS.maos)
	if not allowed.has(category): category = str(allowed[0])
	for tab: Button in _tabs.get_children():
		tab.visible = allowed.has(str(tab.name).trim_prefix("Tab_"))
		tab.button_pressed = tab.name == "Tab_" + category
	for child in _tiers.get_children(): child.queue_free()
	_rows.clear()
	var list := entries()
	selected = clampi(selected, 0, maxi(0, list.size() - 1))
	if list.is_empty():
		var none := _label(12, Color("#8a6a4c"))
		none.text = "Nada aqui ainda." if category != "slimes" else "Coisas dos slimes chegam em breve."
		_tiers.add_child(none)
	var tier := -1
	var grid: GridContainer
	for i in list.size():
		var r: Dictionary = list[i]
		if int(r.get("tier", 1)) != tier:
			tier = int(r.get("tier", 1))
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 6)
			_tiers.add_child(line)
			var badge := _label(16, Color("#5c2a35"))
			badge.text = str(tier)
			badge.custom_minimum_size = Vector2(18, 0)
			badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			line.add_child(badge)
			grid = GridContainer.new()
			grid.columns = COLUMNS
			grid.add_theme_constant_override("h_separation", 4)
			grid.add_theme_constant_override("v_separation", 4)
			line.add_child(grid)
		var slot := SLOT.new()
		var blocked := not why_not(r).is_empty()
		var out_id := _output_id(r)
		var label_name := str(r.get("name", ITEMS.info(out_id).name))
		slot.setup(_icon(r), int(r.get("output", {}).get(out_id, 1)) if not r.has("mode") else 1, i == selected, label_name, why_not(r) if blocked else "Clique para ver", blocked)
		var index := i
		# Playtest ID 04: clicar só escolhe e mostra a receita; fabricar é no botão
		# (ou [F]/Enter). Passar o mouse não troca a escolha.
		slot.clicked.connect(func() -> void:
			selected = index
			refresh())
		grid.add_child(slot)
		_rows.append({"node": slot, "id": str(r.id), "special": r.has("mode")})
	if not list.is_empty(): _show_detail(list[selected])
	else: _show_detail({})
	_center.call_deferred()


func _output_id(r: Dictionary) -> String:
	return str(r.output.keys()[0]) if r.has("output") else str(r.id)


## Ícone: o do item feito; a casa e os móveis ganham desenhos próprios.
func _icon(r: Dictionary) -> Texture2D:
	if str(r.get("id")) == "casa": return house_icon()
	if str(r.get("id")) == "moveis": return load("res://assets/objects/furniture/cadeira.png")
	if str(r.get("id")) == "cama": return load("res://assets/objects/furniture/cama.png")
	return ITEMS.icon(_output_id(r))


## Casinha de pixel (telhado vermelho, porta) para o item Casa.
static func house_icon() -> ImageTexture:
	var rows := ["......XX......", ".....XRRX.....", "....XRRRRX....", "...XRRRRRRX...", "..XRRRRRRRRX..",
		".XRRRRRRRRRRX.", "XXXXXXXXXXXXXX", ".XWWWWWWWWWWX.", ".XWWBBWWWDDWX.", ".XWWBBWWWDDWX.",
		".XWWWWWWWDDWX.", ".XXXXXXXXXXXX."]
	var colors := {"X": Color("#3d2a1e"), "R": Color("#b8483a"), "W": Color("#e8d3a8"), "B": Color("#7fb2d8"), "D": Color("#7a4a2a")}
	var image := Image.create(14, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 14:
			var c := str(rows[y][x])
			if colors.has(c): image.set_pixel(x, y, colors[c])
	return ImageTexture.create_from_image(image)


func _show_detail(r: Dictionary) -> void:
	for child in _detail_mats.get_children(): child.queue_free()
	if r.is_empty():
		_detail_name.text = ""
		_detail_text.text = ""
		_action.visible = false
		_status.text = ""
		return
	var out_id := _output_id(r)
	_detail_name.text = str(r.get("name", ITEMS.info(out_id).name))
	_detail_text.text = str(r.get("text", ITEMS.describe(out_id).replace("\n", " · ")))
	for item_id: String in r.get("inputs", {}):
		var have := BAG.count_item(get_tree(), item_id)
		var need := int(r.inputs[item_id])
		var line := _label(11, Color("#2f6b2a") if have >= need else Color("#a33a2a"))
		line.text = "%s  %d/%d" % [str(ITEMS.info(item_id).name), have, need]
		_detail_mats.add_child(line)
	for tool_id: String in r.get("requires", []):
		var line := _label(11, Color("#5a3f2c"))
		line.text = "Precisa: " + str(ITEMS.info(tool_id).name).to_lower()
		_detail_mats.add_child(line)
	if PLACER.KINDS.has(out_id):
		var build := _label(11, Color("#5a3f2c"))
		build.text = "Construção: %d s" % int(PLACER.KINDS[out_id].build)
		_detail_mats.add_child(build)
	var why := why_not(r)
	_action.visible = true
	_action.text = "Construir" if r.has("mode") else "Fabricar"
	_action.disabled = not why.is_empty()
	_status.text = _detail_name.text + ": " + ("pronto para fazer." if why.is_empty() else why)


func _activate(index: int) -> void:
	var list := entries()
	if index < 0 or index >= list.size(): return
	var r: Dictionary = list[index]
	if r.has("mode"):
		start_building(str(r.mode), str(r.get("furniture_choice", "")))
		return
	if not why_not(r).is_empty():
		refresh()
		return
	_craft(str(r.id))


func _craft(recipe_id: String) -> void:
	if CRAFTING.craft(get_tree(), recipe_id):
		var output_id: String = CRAFTING.recipe(recipe_id).output.keys()[0]
		refresh()
		_status.text = "Você fez: " + str(ITEMS.info(output_id).name).to_lower() + "."
		preload("res://scripts/systems/sfx.gd").play(get_tree(), "fabricar")
		crafted.emit(recipe_id)
	else:
		refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = event.keycode
	if not visible:
		if key == KEY_B and not bool(get_tree().get_meta("build_mode", false)):
			var bag := _sibling("InventoryPanel")  # [B] com a mochila aberta troca de janela
			if bag and bag.visible: bag.call("close")
			if _other_window_open(): return
			open("maos")
			get_viewport().set_input_as_handled()
		return
	var cats: Array = TABS.get(station, TABS.maos)
	match key:
		KEY_B, KEY_ESCAPE:
			close()
		KEY_E:  # [E] troca para a mochila
			close()
			var bag := _sibling("InventoryPanel")
			if bag: bag.call("open")
		KEY_Q:
			show_category(cats[posmod(cats.find(category) - 1, cats.size())])
		KEY_R:
			show_category(cats[posmod(cats.find(category) + 1, cats.size())])
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
			_activate(selected)
		_:
			return
	get_viewport().set_input_as_handled()


func _sibling(node_name: String) -> Control:
	return get_parent().get_node_or_null(node_name) as Control if get_parent() else null


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

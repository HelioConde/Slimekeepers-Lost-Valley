extends PanelContainer
## Janela do baú (BACKLOG P2): bolsa à esquerda, baú à direita. ← → trocam o lado,
## ↑ ↓ escolhem o item, F move a pilha inteira para o outro lado, E / Esc / Q fecham.
## Mesmo estilo da janela de fabricação.

const CHEST := preload("res://scripts/systems/chest_storage.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const CLOSE_BUTTON := preload("res://scripts/ui/close_button.gd")

signal changed

var player: Node
var side := 0  # 0 bolsa, 1 baú
var selected := 0
var _columns: Array[VBoxContainer] = []
var _status: Label


func _ready() -> void:
	name = "ChestPanel"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -230
	offset_right = 230
	offset_top = -110
	offset_bottom = 110
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#694657")
	frame.set_corner_radius_all(4)
	frame.set_content_margin_all(8)
	add_theme_stylebox_override("panel", frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	var title := _label(16, Color("#f6e8c2"))
	title.text = "Baú"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	for heading in ["Bolsa", "Baú"]:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(210, 0)
		box.add_theme_constant_override("separation", 2)
		var head := _label(13, Color("#f2c46d"))
		head.text = heading
		box.add_child(head)
		row.add_child(box)
		_columns.append(box)
	_status = _label(12, Color("#f6e8c2"))
	column.add_child(_status)
	var help := _label(11, Color("#d9c2a8"))
	help.text = "← → lado · ↑ ↓ escolher · F mover a pilha · E / Esc fechar"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(help)
	CLOSE_BUTTON.attach(self, close)


## "" = baú da casa; senão o id de um baú colocado no chão (station_placer).
var chest_id := ""


func open(id: String = "") -> void:
	chest_id = id
	side = 0
	selected = 0
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
	var now := hash([CHEST.items(get_tree(), chest_id), BAG.inventory_snapshot(get_tree())])
	if now != _seen:
		_seen = now
		refresh()


func _freeze(on: bool) -> void:
	if is_instance_valid(player):
		player.set_physics_process(not on)
		if on and "velocity" in player: player.velocity = Vector2.ZERO


## [item, quantidade] de cada lado, em ordem estável.
func entries(which: int) -> Array:
	var data: Dictionary = BAG.inventory_snapshot(get_tree()) if which == 0 else CHEST.items(get_tree(), chest_id)
	var keys: Array = data.keys()
	keys.sort()
	var out: Array = []
	for k in keys:
		if int(data[k]) > 0: out.append([str(k), int(data[k])])
	return out


func refresh() -> void:
	for which in 2:
		var box := _columns[which]
		for i in range(box.get_child_count() - 1, 0, -1): box.get_child(i).queue_free()
		var list := entries(which)
		if which == side: selected = clampi(selected, 0, maxi(0, list.size() - 1))
		if list.is_empty():
			var none := _label(12, Color("#d9c2a8"))
			none.text = "(vazio)"
			box.add_child(none)
		for i in list.size():
			var line := _label(12, Color("#ffffff") if which == side and i == selected else Color("#d9c2a8"))
			line.text = ("▶ " if which == side and i == selected else "   ") + "%s ×%d" % [str(ITEMS.info(list[i][0]).get("name", list[i][0])), list[i][1]]
			box.add_child(line)


## Move a pilha escolhida para o outro lado; devolve quantos moveu.
func move_selected() -> int:
	var list := entries(side)
	if list.is_empty(): return 0
	var item: String = list[clampi(selected, 0, list.size() - 1)][0]
	var moved: int = CHEST.store(get_tree(), item, chest_id) if side == 0 else CHEST.take(get_tree(), item, chest_id)
	_status.text = ("Guardou %d" if side == 0 else "Pegou %d") % moved + " " + str(ITEMS.info(item).get("name", item)).to_lower() + ("." if moved > 0 else " (bolsa cheia).")
	refresh()
	changed.emit()
	return moved


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


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

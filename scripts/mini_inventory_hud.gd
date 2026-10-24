extends CanvasLayer
## Mini HUD com hotbar, bolsa e aviso de interacao.
const TOOL_NAMES: Array[String] = ["MACHADO", "PICARETA", "ENXADA", "REGADOR"]
const INVENTORY_ROWS: Array[String] = [
	"madeira", "pedra", "fibra", "sementes", "colheita", "cogumelos"
]

@onready var inventory: Node = get_node("../Inventory")
@onready var tool_system: Node2D = get_node("../WorldObjects/Player/ToolSystem")
var _interface_root: Control
var _buttons: Array[Button] = []
var _summary: Label
var _contents: Label
var _inventory_panel: PanelContainer
var _feedback: Label

func _ready() -> void:
	_make_interface()
	inventory.connect("inventory_changed", Callable(self, "_update_counts"))
	tool_system.connect("selected_tool_changed", Callable(self, "_update_selection"))
	tool_system.connect("feedback", Callable(self, "_show_feedback"))
	_update_counts()
	_update_selection(0)
	_show_feedback("F / clique: usar  |  E: plantar/colher  |  I: mochila")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if k.pressed and not k.echo and k.physical_keycode == KEY_I:
			_inventory_panel.visible = not _inventory_panel.visible
			get_viewport().set_input_as_handled()

func _make_interface() -> void:
	_interface_root = Control.new()
	_interface_root.name = "MiniHUDRoot"
	_interface_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_interface_root)
	_interface_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hotbar := PanelContainer.new()
	hotbar.name = "BarraDeFerramentas"
	hotbar.anchor_left = 0.5
	hotbar.anchor_right = 0.5
	hotbar.anchor_top = 1.0
	hotbar.anchor_bottom = 1.0
	hotbar.offset_left = -284.0
	hotbar.offset_right = 284.0
	hotbar.offset_top = -80.0
	hotbar.offset_bottom = -12.0
	hotbar.mouse_filter = Control.MOUSE_FILTER_STOP
	_interface_root.add_child(hotbar)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hotbar.add_child(hbox)
	for i in range(4):
		var button := Button.new()
		button.custom_minimum_size = Vector2(135.0, 54.0)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_click_tool.bind(i))
		hbox.add_child(button)
		_buttons.append(button)
	var message_panel := PanelContainer.new()
	message_panel.anchor_left = 0.5
	message_panel.anchor_right = 0.5
	message_panel.anchor_top = 1.0
	message_panel.anchor_bottom = 1.0
	message_panel.offset_left = -275.0
	message_panel.offset_right = 275.0
	message_panel.offset_top = -121.0
	message_panel.offset_bottom = -87.0
	message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interface_root.add_child(message_panel)
	_feedback = Label.new()
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_font_size_override("font_size", 13)
	message_panel.add_child(_feedback)
	var summary_panel := PanelContainer.new()
	summary_panel.anchor_left = 1.0
	summary_panel.anchor_right = 1.0
	summary_panel.offset_left = -247.0
	summary_panel.offset_right = -14.0
	summary_panel.offset_top = 82.0
	summary_panel.offset_bottom = 149.0
	summary_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interface_root.add_child(summary_panel)
	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 14)
	summary_panel.add_child(_summary)
	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "MochilaCompleta"
	_inventory_panel.anchor_left = 1.0
	_inventory_panel.anchor_right = 1.0
	_inventory_panel.offset_left = -253.0
	_inventory_panel.offset_right = -14.0
	_inventory_panel.offset_top = 160.0
	_inventory_panel.offset_bottom = 354.0
	_inventory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inventory_panel.visible = false
	_interface_root.add_child(_inventory_panel)
	_contents = Label.new()
	_contents.add_theme_font_size_override("font_size", 15)
	_inventory_panel.add_child(_contents)

func _click_tool(index: int) -> void:
	tool_system.call("select_tool", index)

func _update_selection(index: int) -> void:
	for i in range(_buttons.size()):
		var button: Button = _buttons[i]
		button.text = "%d %s\n%s" % [i + 1, TOOL_NAMES[i], "EQUIPADO" if i == index else "Selecionar"]
		button.modulate = Color("#e8d19a") if i == index else Color.WHITE

func _update_counts() -> void:
	_summary.text = "MOCHILA [I]\nMadeira %d  |  Pedra %d\nSementes %d  |  Colheita %d" % [
		int(inventory.call("quantity", "madeira")),
		int(inventory.call("quantity", "pedra")),
		int(inventory.call("quantity", "sementes")),
		int(inventory.call("quantity", "colheita"))
	]
	_contents.text = "INVENTARIO (I para fechar)\n\n"
	for item_id in INVENTORY_ROWS:
		_contents.text += "%-12s x%02d\n" % [
			_item_label(item_id), int(inventory.call("quantity", item_id))
		]

func _item_label(item_id: String) -> String:
	match item_id:
		"madeira": return "Madeira"
		"pedra": return "Pedra"
		"fibra": return "Fibra"
		"sementes": return "Sementes"
		"colheita": return "Colheita"
		"cogumelos": return "Cogumelos"
	return item_id

func _show_feedback(message: String) -> void:
	if _feedback != null:
		_feedback.text = message

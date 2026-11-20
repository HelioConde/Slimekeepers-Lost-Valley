extends CanvasLayer
## Pausa da exploração: Esc (ui_cancel) pausa o SceneTree e foca "Continuar";
## Esc ou o botão retomam. Não abre por cima de uma pausa que não é sua.
const FONT := preload("res://assets/fonts/PixelifySans.ttf")

var continue_button: Button
var _panel: Control


func _ready() -> void:
	name = "PauseOverlay"
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.hide()


func is_open() -> bool:
	return is_instance_valid(_panel) and _panel.visible


func open() -> void:
	if is_open() or get_tree().paused:
		return
	get_tree().paused = true
	_panel.show()
	continue_button.grab_focus()


func close() -> void:
	if not is_open():
		return
	_panel.hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if is_open():
		close()
	else:
		open()
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _build() -> void:
	_panel = ColorRect.new()
	_panel.name = "Shade"
	_panel.color = Color(0.08, 0.06, 0.1, 0.55)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(center)

	var card := PanelContainer.new()
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("#f6e8c2")
	skin.border_color = Color("#694657")
	skin.set_border_width_all(2)
	skin.set_corner_radius_all(4)
	skin.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", skin)
	center.add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)

	var title := Label.new()
	title.text = "Jogo pausado"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#3e5c43"))
	column.add_child(title)

	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "Continuar"
	continue_button.add_theme_font_override("font", FONT)
	continue_button.add_theme_font_size_override("font_size", 16)
	continue_button.pressed.connect(close)
	column.add_child(continue_button)

	var hint := Label.new()
	hint.text = "Esc para voltar ao jogo"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", FONT)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("#694657"))
	column.add_child(hint)

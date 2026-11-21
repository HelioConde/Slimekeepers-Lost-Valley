extends PanelContainer
## Mostra o próximo passo do ciclo de culinária abaixo do relógio; some ao concluir.
## Atualiza por amostragem para não depender de cada ponto que altera a sessão.
const GUIDANCE := preload("res://scripts/systems/cooking_guidance.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const REFRESH_SECONDS := 0.5

var label: Label
var _elapsed := 0.0


func _ready() -> void:
	name = "CookingGuidance"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Sob o relógio, crescendo para a esquerda só o necessário para o texto.
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -18
	offset_right = -18
	offset_top = 128
	offset_bottom = 128
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("#f6e8c2")
	skin.border_color = Color("#694657")
	skin.set_border_width_all(2)
	skin.set_corner_radius_all(4)
	skin.set_content_margin_all(4)
	skin.content_margin_left = 7
	skin.content_margin_right = 7
	add_theme_stylebox_override("panel", skin)
	label = Label.new()
	label.name = "NextStep"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#3e5c43"))
	add_child(label)
	refresh()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= REFRESH_SECONDS:
		_elapsed = 0.0
		refresh()


func refresh() -> void:
	if not is_instance_valid(label) or not is_inside_tree():
		return
	var text := GUIDANCE.next_step(get_tree())
	label.text = text
	visible = not text.is_empty()

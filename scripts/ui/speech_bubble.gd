extends PanelContainer
## Balão de fala contextual (playtest ID 48): um texto curto sobre a cabeça do personagem
## quando falta ferramenta/condição ("Preciso de uma picareta..."). Mesmo visual do balão
## do tutorial (tutorial_hud.gd). Um balão por vez, com intervalo por chave de situação;
## só local (não sincroniza no multijogador). Se o tutorial está falando, sobe acima dele.

const FONT := preload("res://assets/fonts/ui_font.tres")
const INK := Color("#3d2a1e")
const PAPER := Color("#f6ead0")
const EDGE := Color("#6b4a32")
const HEAD := Vector2(0, -44)  ## topo da cabeça em relação aos pés (como o tutorial)
const TAIL := 8.0
const WIDTH := 250.0
const SHOW_SECONDS := 3.0
const COOLDOWN := 25.0  ## mesma situação só volta a falar depois disso

var region: Node  ## clearing_region: player
var key := ""  ## situação do balão atual
var _left := 0.0
var _label: Label
var _tail: Control
var _next_at: Dictionary = {}  ## chave -> ticks (ms) em que pode falar de novo


func _ready() -> void:
	name = "SpeechBubble"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.border_color = EDGE
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(8)
	paper.shadow_color = Color(0, 0, 0, 0.35)
	paper.shadow_offset = Vector2(0, 3)
	paper.shadow_size = 2
	paper.set_content_margin_all(8)
	add_theme_stylebox_override("panel", paper)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.custom_minimum_size = Vector2(WIDTH - 16.0, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", INK)
	add_child(_label)
	_tail = Control.new()
	_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tail.custom_minimum_size = Vector2(TAIL * 2, TAIL + 4)
	_tail.draw.connect(func() -> void:
		_tail.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(TAIL * 2, 0), Vector2(TAIL, TAIL + 3)]), EDGE)
		_tail.draw_colored_polygon(PackedVector2Array([Vector2(3, 0), Vector2(TAIL * 2 - 3, 0), Vector2(TAIL, TAIL - 1)]), PAPER))
	add_child(_tail)


## PanelContainer estica os filhos; o rabinho volta para a borda de baixo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and is_instance_valid(_tail):
		_tail.size = _tail.custom_minimum_size
		_tail.position = Vector2(size.x * 0.5 - TAIL, size.y - 3)


## Fala `text` para a situação `situation`. false = ignorado (em intervalo ou outro balão aberto).
func say(situation: String, text: String, cooldown: float = COOLDOWN) -> bool:
	var now := Time.get_ticks_msec()
	if visible or now < int(_next_at.get(situation, 0)): return false
	_next_at[situation] = now + int(cooldown * 1000.0)
	key = situation
	_label.text = text
	_left = SHOW_SECONDS
	reset_size()
	visible = true
	_follow()
	return true


func _process(delta: float) -> void:
	if not visible: return
	_left -= delta
	if _left <= 0.0:
		visible = false
		key = ""
		return
	_follow()


func _follow() -> void:
	var player: Node2D = region.get("player") if region else null
	if not is_instance_valid(player) or not is_inside_tree(): return
	var head: Vector2 = get_viewport().get_canvas_transform() * (player.global_position + HEAD)
	var screen := get_viewport_rect().size
	var at := head - Vector2(size.x * 0.5, size.y + TAIL + 2)
	var tutorial := get_parent().get_node_or_null("TutorialHud") as Control
	var above_tutorial := tutorial != null and tutorial.visible
	if above_tutorial: at.y = tutorial.position.y - size.y - TAIL - 6  # o do tutorial fica intacto
	_tail.visible = not above_tutorial
	position = Vector2(clampf(at.x, 6, screen.x - size.x - 6), clampf(at.y, 6, screen.y - size.y - 6)).round()
	_tail.position.x = clampf(head.x - position.x - TAIL, 10, size.x - TAIL * 2 - 10)

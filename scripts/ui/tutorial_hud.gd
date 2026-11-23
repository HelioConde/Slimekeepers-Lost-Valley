extends PanelContainer
## Tutorial inicial (pedido do usuário, 2026-11-23): depois do despertar do Novo Jogo,
## um balão de fala sobre a cabeça do protagonista (aba com o nome, título e texto com
## as teclas desenhadas, rabinho apontando para ele) que segue o personagem. Cada dica
## passa sozinha quando o jogador faz o que ela pede; [Tab] pula. O passo fica na
## sessão (KEY) e vai no save.

const KEY := "tutorial_step"
const BAG := preload("res://scripts/systems/forest_bag.gd")
const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const INK := Color("#3d2a1e")
const PAPER := Color("#f6ead0")
const EDGE := Color("#6b4a32")
const TAB := Color("#5c2a35")
## [título, texto com [TECLA], condição para passar]. Condições em _done().
const STEPS := [
	["Vamos começar pelo básico!", "Use as teclas [W] [A] [S] [D] para mover seu personagem. Segure [Shift] para correr.", "walk"],
	["Coletando recursos", "Chegue perto de um graveto ou pedrinha e aperte [F] ou clique nele. Andar cancela.", "pick"],
	["Sua mochila", "Aperte [E] para abrir a mochila e ver o que você juntou.", "bag"],
	["Fabricando", "Aperte [B] para fabricar. Fibra do mato vira corda; corda, graveto e pedra viram um machado.", "craft"],
	["Ferramentas", "Escolha a ferramenta na barra com [1] a [0] ou a roda do mouse. Segure [F] ou o clique para golpear árvores e pedras.", "swing"],
	["Amigos slimes", "Chegue perto de um slime e aperte [F] para fazer amizade.", "friend"],
	["Sua casa", "Em [B], \"Construir casa\" abre o modo construir. Dormir na cama salva o jogo.", "read"],
]
const READ_SECONDS := 9.0
const WIDTH := 330.0
## Topo da cabeça em relação aos pés do jogador (sprite 128 px, escala 0,65 em y -34).
const HEAD := Vector2(0, -60)
const TAIL := 10.0

var region: Node  ## clearing_region: player, inventory_panel, crafting_panel
var _label: Label  ## título da dica
var _body: HFlowContainer
var _footer: Label
var _tab: PanelContainer
var _tail: Control
var _walked := 0.0
var _time := 0.0


func _ready() -> void:
	name = "TutorialHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var who: Dictionary = PROTAGONIST.data(get_tree())
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.border_color = EDGE
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(8)
	paper.shadow_color = Color(0, 0, 0, 0.35)
	paper.shadow_offset = Vector2(0, 3)
	paper.shadow_size = 2
	paper.set_content_margin_all(8)
	paper.content_margin_top = 12
	add_theme_stylebox_override("panel", paper)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 3)
	add_child(column)
	_label = _text("", 15, INK)
	_label.add_theme_constant_override("outline_size", 1)
	_label.add_theme_color_override("font_outline_color", INK)  # negrito da referência
	column.add_child(_label)
	_body = HFlowContainer.new()
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.custom_minimum_size = Vector2(WIDTH - 20.0, 0)
	_body.add_theme_constant_override("h_separation", 4)
	_body.add_theme_constant_override("v_separation", 3)
	column.add_child(_body)
	_footer = _text("", 10, Color("#8a6a4c"))
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_footer)
	# Aba com o nome, presa à borda de cima (fora do encaixe do PanelContainer).
	_tab = PanelContainer.new()
	_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tab_style := StyleBoxFlat.new()
	tab_style.bg_color = TAB
	tab_style.border_color = Color("#2e141a")
	tab_style.set_border_width_all(2)
	tab_style.set_corner_radius_all(6)
	tab_style.content_margin_left = 14
	tab_style.content_margin_right = 14
	tab_style.content_margin_top = 1
	tab_style.content_margin_bottom = 1
	_tab.add_theme_stylebox_override("panel", tab_style)
	_tab.add_child(_text(str(who.get("name", "")), 13, PAPER))
	add_child(_tab)
	# Rabinho do balão apontando para a cabeça (desenhado: triângulo com borda).
	_tail = Control.new()
	_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tail.custom_minimum_size = Vector2(TAIL * 2, TAIL + 4)
	_tail.draw.connect(func() -> void:
		var w := TAIL
		_tail.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 2, 0), Vector2(w, TAIL + 3)]), EDGE)
		_tail.draw_colored_polygon(PackedVector2Array([Vector2(3, 0), Vector2(w * 2 - 3, 0), Vector2(w, TAIL - 1)]), PAPER))
	add_child(_tail)
	_show()


## PanelContainer estica todos os filhos; a aba volta para cima da borda.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and is_instance_valid(_tab):
		_tab.size = _tab.get_combined_minimum_size()
		_tab.position = Vector2(12, -_tab.size.y + 4)
	if what == NOTIFICATION_SORT_CHILDREN and is_instance_valid(_tail):
		_tail.size = _tail.custom_minimum_size
		_tail.position = Vector2(size.x * 0.5 - TAIL, size.y - 3)


func _text(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Tecla desenhada (como na referência): caixinha clara com borda e sombra.
func _keycap(key: String) -> Control:
	var cap := PanelContainer.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffaf0")
	style.border_color = INK
	style.set_border_width_all(2)
	style.border_width_bottom = 4
	style.set_corner_radius_all(4)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	cap.add_theme_stylebox_override("panel", style)
	var label := _text(key, 12, INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_child(label)
	return cap


static func active(tree: SceneTree) -> bool:
	return tree.has_meta(KEY) and int(tree.get_meta(KEY)) < STEPS.size()


func step() -> int:
	return int(get_tree().get_meta(KEY, STEPS.size()))


func _show() -> void:
	visible = active(get_tree())
	if not visible: return
	var data: Array = STEPS[step()]
	_label.text = str(data[0])
	for child in _body.get_children(): child.queue_free()
	for word in str(data[1]).split(" "):
		var close := word.find("]")
		if word.begins_with("[") and close > 0:
			_body.add_child(_keycap(word.substr(1, close - 1)))
			if close + 1 < word.length(): _body.add_child(_text(word.substr(close + 1), 13, INK))
		else:
			_body.add_child(_text(word, 13, INK))
	_footer.text = "[Tab] pular dica  ·  %d/%d" % [step() + 1, STEPS.size()]
	_walked = 0.0
	_time = 0.0
	reset_size()
	_follow()


func advance() -> void:
	get_tree().set_meta(KEY, step() + 1)
	_show()


func _process(delta: float) -> void:
	if not active(get_tree()):
		visible = false
		return
	if not visible: _show()  # começou agora (fim do despertar)
	_follow()
	_time += delta
	if _done(str(STEPS[step()][2]), delta): advance()


## Fica sobre a cabeça do jogador, dentro da tela (pés -> tela pela câmera).
func _follow() -> void:
	var player: Node2D = region.get("player") if region else null
	if not is_instance_valid(player) or not is_inside_tree(): return
	var head: Vector2 = get_viewport().get_canvas_transform() * (player.global_position + HEAD)
	var screen := get_viewport_rect().size
	var at := head - Vector2(size.x * 0.5, size.y + TAIL + 2)
	position = Vector2(clampf(at.x, 6, screen.x - size.x - 6), clampf(at.y, 24, screen.y - size.y - 6)).round()
	if is_instance_valid(_tail):  # o rabinho continua apontando para a cabeça
		_tail.position.x = clampf(head.x - position.x - TAIL, 10, size.x - TAIL * 2 - 10)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if visible and key and key.pressed and not key.echo and key.physical_keycode == KEY_TAB:
		advance()
		get_viewport().set_input_as_handled()


func _done(kind: String, delta: float) -> bool:
	var tree := get_tree()
	match kind:
		"walk":
			var player: Node = region.get("player") if region else null
			if player is CharacterBody2D and (player as CharacterBody2D).velocity.length() > 10.0: _walked += delta
			return _walked > 1.5
		"pick":
			return BAG.count_item(tree, "graveto") + BAG.count_item(tree, "pedra_pequena") + BAG.count_item(tree, "fibra") > 0
		"bag":
			return _open("inventory_panel")
		"craft":
			return _open("crafting_panel")
		"swing":
			var player: Node = region.get("player") if region else null
			return (is_instance_valid(player) and player.has_method("is_using_tool") and player.is_using_tool() and str(player.get("current_animation")).begins_with("axe")) or _time > 20.0
		"friend":
			for key in ["forest_slime_friends", "valley_slime_friends"]:
				if not (tree.get_meta(key, {}) as Dictionary).is_empty(): return true
			return false
	return _time > READ_SECONDS


func _open(panel_name: String) -> bool:
	var panel: Variant = region.get(panel_name) if region else null
	return panel is Control and is_instance_valid(panel) and (panel as Control).visible

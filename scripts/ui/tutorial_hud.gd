extends PanelContainer
## Tutorial inicial (pedido do usuário, 2026-11-23): depois do despertar do Novo Jogo,
## um balão de fala sobre a cabeça do protagonista (aba com o nome, título e texto com
## as teclas desenhadas, rabinho apontando para ele) que segue o personagem. Cada dica
## passa sozinha quando o jogador faz o que ela pede; [Tab] pula. O passo fica na
## sessão (KEY) e vai no save.
## Multijogador (playtest ID 18): cada jogo tem o próprio passo (KEY não sincroniza,
## scripts/net/net_world.gd) e as condições olham a mochila deste jogador. Só a
## bancada é da dupla (placed_stations): planta/depósito/obra valem para os dois, e a
## dica diz isso.

const KEY := "tutorial_step"
const BAG := preload("res://scripts/systems/forest_bag.gd")
const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
const BUILD := preload("res://scripts/systems/build_site.gd")
const FONT := preload("res://assets/fonts/ui_font.tres")  # dígitos legíveis (playtest ID 33)
const INK := Color("#3d2a1e")
const PAPER := Color("#f6ead0")
const EDGE := Color("#6b4a32")
const TAB := Color("#5c2a35")
## [título, texto com [TECLA], condição para passar]. Condições em _done().
## [esq] = ícone do mouse com o botão esquerdo; [roda] = ícone da roda do mouse.
const STEPS := [
	["Vamos começar pelo básico!", "Use as teclas [W] [A] [S] [D] para andar. Segure [Shift] para correr.", "walk"],
	["Coletando recursos", "Junte 8 gravetos e 6 pedrinhas: chegue perto e aperte [F] ou [esq] (andar cancela)", "pick"],
	["Arrancando mato", "Aperte [F] perto de um tufo de mato e espere arrancar. Junte 9 fibras.", "fiber"],
	["Sua mochila", "Aperte [E] para ver a mochila. [E] de novo fecha.", "bag"],
	["Fabricando corda", "Aperte [B] e clique [esq] na corda até ter 3 cordas (3 fibras cada).", "rope"],
	# Obra em etapas (playtest ID 40): planta sem custo -> depositar -> construir.
	["A planta da bancada", "No [B], escolha a bancada e clique no chão para colocar a planta. Ela não gasta nada.", "plan"],
	["Levando os materiais", "Leve 6 gravetos, 4 pedrinhas e 2 cordas até a planta e aperte [F] ou [esq] nela para depositar.", "deposit"],
	["Construindo a bancada", "Com tudo depositado a planta fica verde: aperte [F] ou [esq] nela. Leva 10 segundos (andar pausa; em dupla vai mais rápido).", "build"],
	["Usando a bancada", "Chegue perto da bancada e aperte [F] ou [esq] para abrir", "use"],
	["Seu primeiro machado", "Na bancada, aba Ferramentas: faça o machado (2 gravetos, 2 pedrinhas e 1 corda).", "axe"],
	["Cortando árvores", "Escolha o machado na barra com [1] a [0] ou [roda] e, perto de uma árvore pequena, segure [F] ou [esq]", "swing"],
	["Pronto!", "Na bancada você fabrica as ferramentas; no [B], construções. Bom começo!", "read"],
]
const SHARED := ["plan", "deposit", "build"]  ## passos com a bancada da dupla
const SHARED_NOTE := "Em dupla a bancada é uma só: o que um fizer nela vale para os dois."
const READ_SECONDS := 9.0
const WIDTH := 330.0
## Topo da cabeça em relação aos pés do jogador (sprite 128 px, escala 0,48 em y -25;
## playtest ID 52: personagem menor para caber na casa, escolha do usuário 2026-11-27).
const HEAD := Vector2(0, -44)
const TAIL := 10.0

var region: Node  ## clearing_region: player, inventory_panel, crafting_panel
var _label: Label  ## título da dica
var _body: HFlowContainer
var _footer: Label
var _tab: PanelContainer
var _tail: Control
var _walked := 0.0
var _bag_seen := false
var _highlight: Node2D  ## anel branco piscando nos alvos (tutorial_highlight.gd)
var _scan := 0.0
const NEAR_ITEMS := 720.0  ## coletáveis da dica: anéis de mais longe (benchmark rodada 2)
const PER_ITEM := 3
const NEAR := 460.0  ## só destaca alvos perto do jogador  ## mochila já abriu nesta dica (passa ao fechar)
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
	if region:
		_highlight = preload("res://scripts/ui/tutorial_highlight.gd").new()
		region.add_child.call_deferred(_highlight)
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


## Palavra da dica: a frase já veio traduzida; a palavra sozinha não traduz de novo.
func _word(value: String) -> Label:
	var label := _text(value, 13, INK)
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	return label


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


## Mouse em pixel art (pedido do usuário: ícone no lugar de "mouse"/"roda do mouse"):
## botão esquerdo ou roda em vermelho. X contorno, L/R botões, W roda, B corpo.
const MOUSE_ROWS := [".XXXXXXXXX.", "XLLLXWXRRRX", "XLLLXWXRRRX", "XLLLXWXRRRX", "XLLLXXXRRRX", "XXXXXXXXXXX",
	"XBBBBBBBBBX", "XBBBBBBBBBX", "XBBBBBBBBBX", "XBBBBBBBBBX", ".XBBBBBBBX.", "..XXXXXXX.."]


static func mouse_texture(part: String) -> ImageTexture:
	var image := Image.create(11, MOUSE_ROWS.size(), false, Image.FORMAT_RGBA8)
	var hot := Color("#d8434a")
	var shell := Color("#fffaf0")
	for y in MOUSE_ROWS.size():
		for x in 11:
			match str(MOUSE_ROWS[y][x]):
				"X": image.set_pixel(x, y, INK)
				"L": image.set_pixel(x, y, hot if part == "esq" else shell)
				"W": image.set_pixel(x, y, hot if part == "roda" else shell)
				"R", "B": image.set_pixel(x, y, shell)
	return ImageTexture.create_from_image(image)


func _mouse_icon(part: String) -> Control:
	var icon := TextureRect.new()
	icon.name = "Mouse_" + part
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = mouse_texture(part)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(14, 16)  # do tamanho da tecla desenhada
	return icon


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
	var text := tr(str(data[1]))  # traduz a frase inteira antes de quebrar em palavras (ID 15)
	if _together() and str(data[2]) in SHARED: text += " " + tr(SHARED_NOTE)
	for word in text.split(" "):
		var close := word.find("]")
		if word.begins_with("[") and close > 0:
			var token := word.substr(1, close - 1)
			_body.add_child(_mouse_icon(token) if token in ["esq", "roda"] else _keycap(token), true)  # nome legível mesmo com os antigos saindo
			if close + 1 < word.length(): _body.add_child(_word(word.substr(close + 1)))
		else:
			_body.add_child(_word(word))
	_footer.text = tr("[Tab] pular dica") + "  ·  %d/%d" % [step() + 1, STEPS.size()]
	_walked = 0.0
	_bag_seen = false
	_time = 0.0
	reset_size()
	_follow()


func advance() -> void:
	get_tree().set_meta(KEY, step() + 1)
	_show()


func _process(delta: float) -> void:
	if not active(get_tree()):
		visible = false
		if is_instance_valid(_highlight): _highlight.targets = []
		return
	_scan -= delta
	if _scan <= 0.0 and is_instance_valid(_highlight):
		_scan = 0.4
		_highlight.targets = _targets(str(STEPS[step()][2]))
	if not visible: _show()  # começou agora (fim do despertar)
	_follow()
	_time += delta
	_footer.text = _progress(str(STEPS[step()][2])) + tr("[Tab] pular dica") + "  ·  %d/%d" % [step() + 1, STEPS.size()]
	if _done(str(STEPS[step()][2]), delta): advance()


## Fica sobre a cabeça do jogador, dentro da tela (pés -> tela pela câmera).
func _follow() -> void:
	var player: Node2D = region.get("player") if region else null
	if not is_instance_valid(player) or not is_inside_tree(): return
	var head: Vector2 = get_viewport().get_canvas_transform() * (player.global_position + HEAD)
	var screen := get_viewport_rect().size
	var window := _open("inventory_panel") or _open("crafting_panel")
	_tail.visible = not window
	if window:  # janela aberta no centro: o balão sobe para o alto e não a cobre
		position = Vector2(round((screen.x - size.x) * 0.5), 26)
		return
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
			return _paid_solo() or _has(tree, ["bancada", "machado"]) or (BAG.count_item(tree, "graveto") >= 8 and BAG.count_item(tree, "pedra_pequena") >= 6)
		"fiber":
			return BAG.count_item(tree, "fibra") + BAG.count_item(tree, "corda") * 3 >= 9 or _paid_solo() or _has(tree, ["bancada", "machado"])
		"bag":
			_bag_seen = _bag_seen or _open("inventory_panel")
			return _bag_seen and not _open("inventory_panel")
		"rope":
			return BAG.count_item(tree, "corda") >= 3 or _paid_solo() or _has(tree, ["bancada", "machado"])
		"axe":
			return _has(tree, ["machado"])
		"plan":  # a bancada já fabricada (save antigo) também vale
			return _has(tree, ["bancada"]) or _placed()
		"deposit":
			return _paid()
		"build":
			return (get_tree().get_meta("placed_stations", []) as Array).any(func(e: Dictionary) -> bool: return str(e.get("kind", "bancada")) == "bancada" and bool(e.get("built", true)))
		"use":
			var craft: Variant = region.get("crafting_panel") if region else null
			return _open("crafting_panel") and str((craft as Node).get("station")) == "bancada"
		"swing":
			var player: Node = region.get("player") if region else null
			return is_instance_valid(player) and player.has_method("is_using_tool") and player.is_using_tool() and str(player.get("current_animation")).begins_with("axe")
		"friend":
			for key in ["forest_slime_friends", "valley_slime_friends"]:
				if not (tree.get_meta(key, {}) as Dictionary).is_empty(): return true
			return false
	return _time > READ_SECONDS


## Onde a dica manda ir: [pé no mundo, raio do anel], os mais perto do jogador.
func _targets(kind: String) -> Array:
	var player: Node2D = region.get("player") if region else null
	if not is_instance_valid(player): return []
	var from := player.global_position
	var found: Array = []
	var items := {"pick": ["graveto", "pedra_pequena"], "fiber": ["fibra"]}
	if kind in ["deposit", "axe"]:  # destaca o que ainda falta (mato vira corda, gravetos, pedrinhas)
		var need := {"deposit": [6, 4, 2], "axe": [2, 2, 1]}[kind] as Array
		var want: Array = []
		if BAG.count_item(get_tree(), "graveto") < int(need[0]): want.append("graveto")
		if BAG.count_item(get_tree(), "pedra_pequena") < int(need[1]): want.append("pedra_pequena")
		if BAG.count_item(get_tree(), "corda") + BAG.count_item(get_tree(), "fibra") / 3 < int(need[2]): want.append("fibra")
		items[kind] = want
	if kind == "pick":  # benchmark rodada 2: com gravetos quase prontos, os anéis iam todos para gravetos
		items[kind] = (["graveto"] if BAG.count_item(get_tree(), "graveto") < 8 else []) 			+ (["pedra_pequena"] if BAG.count_item(get_tree(), "pedra_pequena") < 6 else [])
	if items.has(kind):
		var forage: Node = region.get("forage")
		var day: int = get_tree().root.get_node("GameClock").day_number
		if is_instance_valid(forage):
			for spot: Dictionary in forage.spots:
				if str(spot.item) in items[kind] and spot.at.distance_to(from) < NEAR_ITEMS and not forage.is_taken(get_tree(), spot.id, day):
					found.append([spot.at, 14.0 if kind == "pick" else 18.0, str(spot.item)])
			# Até PER_ITEM anéis de cada tipo que ainda falta (antes: 6 mais perto, de qualquer tipo).
			found.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).distance_to(from) < (b[0] as Vector2).distance_to(from))
			var per: Dictionary = {}
			found = found.filter(func(e: Array) -> bool:
				per[e[2]] = int(per.get(e[2], 0)) + 1
				return int(per[e[2]]) <= PER_ITEM)
	elif kind == "swing":
		var chop: Node = region.get("choppable")
		if is_instance_valid(chop):
			var cut: Dictionary = chop.state(get_tree())
			for key: String in chop.trees:
				var tree: Node2D = chop.trees[key]
				if tree.global_position.distance_to(from) > NEAR or not chop.is_small(key): continue
				if cut.has(key):  # tronco caído ainda não processado também vale madeira
					if not bool(cut[key].get("processed", false)): found.append([chop.log_position(key), 20.0])
				else: found.append([tree.global_position, 24.0])
	if kind in ["use", "build", "deposit"]:
		var placer: Node = region.get("placer")
		if is_instance_valid(placer):
			for station: Node2D in placer.get("_stations"): found.append([station.global_position, 30.0])
	found.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).distance_to(from) < (b[0] as Vector2).distance_to(from))
	return found.slice(0, 6)


## Contagem do que a dica pede (ex.: "Gravetos 1/2 · Pedrinhas 0/2   ").
func _progress(kind: String) -> String:
	var tree := get_tree()
	var parts: PackedStringArray = []
	match kind:
		"pick":
			parts.append(tr("Gravetos %d/8") % mini(8, BAG.count_item(tree, "graveto")))
			parts.append(tr("Pedrinhas %d/6") % mini(6, BAG.count_item(tree, "pedra_pequena")))
		"fiber":
			parts.append(tr("Fibras %d/9") % mini(9, BAG.count_item(tree, "fibra") + BAG.count_item(tree, "corda") * 3))
		"rope":
			parts.append(tr("Cordas %d/3") % mini(3, BAG.count_item(tree, "corda")))
		"deposit":
			parts.append(tr("Gravetos %d/6") % mini(6, BAG.count_item(tree, "graveto")))
			parts.append(tr("Pedrinhas %d/4") % mini(4, BAG.count_item(tree, "pedra_pequena")))
			parts.append(tr("Cordas %d/2") % mini(2, BAG.count_item(tree, "corda")))
	return "" if parts.is_empty() else " · ".join(parts) + "     "


func _placed() -> bool:
	return not (get_tree().get_meta("placed_stations", []) as Array).is_empty()


## Alguma bancada com o material todo depositado (pronta, construindo ou feita).
func _paid() -> bool:
	return (get_tree().get_meta("placed_stations", []) as Array).any(func(e: Dictionary) -> bool:
		return str(e.get("kind", "bancada")) == "bancada" and BUILD.stage(e) != "plan")


## Bancada paga pula a coleta só no solo (save antigo que já gastou o material); em
## dupla quem pagou pode ter sido o outro, e a coleta de cada um é dele.
func _paid_solo() -> bool:
	return _paid() and not _together()


func _together() -> bool:
	var net := get_node_or_null("/root/NetSession")
	return net != null and bool(net.get("connected"))


static func _has(tree: SceneTree, items: Array) -> bool:
	return items.any(func(i: String) -> bool: return BAG.count_item(tree, i) > 0)


func _open(panel_name: String) -> bool:
	var panel: Variant = region.get(panel_name) if region else null
	return panel is Control and is_instance_valid(panel) and (panel as Control).visible

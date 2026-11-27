extends Control
## Seleção de protagonista (Novo Jogo): Aren e Moni sentados de costas um para o
## outro numa clareira encantada. Cursor em cima: realça, o outro esmaece e o
## personagem olha por cima do ombro (uma vez por entrada). Clique fixa a escolha
## e mostra Confirmar/Voltar. Teclado/controle: ←/→ escolhem, Enter confirma,
## Esc volta. Simbólica (Bíblia): no mundo, quem foi escolhido desperta sozinho.
## Multijogador (playtest ID 17): a tela vira a sala. "Jogador 1" (anfitrião) e
## "Jogador 2" aparecem acima do protagonista de cada um, nas duas telas; o que o outro
## escolheu fica bloqueado; Confirmar vira Pronto e o anfitrião começa quando os dois
## estão prontos. Voltar sai da sala; se o anfitrião sair, o convidado volta ao menu.

const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
const NET := preload("res://scripts/net/net_session.gd")
const SessionState = preload("res://scripts/systems/session_state.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const ART := "res://assets/menu/select/"
const FOREST := "res://scenes/regions/FlorestaDoDespertarV2.tscn"
const MENU := "res://scenes/start_menu.tscn"
const ORDER := ["aren", "moni"]
const CARD_SCALE := 2.6
const DIM := Color(0.62, 0.66, 0.78)
const LIT := Color(1.12, 1.1, 1.02)

var hovered := ""
var selected := ""
var figures := {}   # id -> TextureRect
var panels := {}    # id -> PanelContainer
var _textures := {} # id -> [neutral, look]
var _shadows := {}  # id -> Polygon2D
var _buttons: HBoxContainer
var _confirm: Button
var _breath := 0.0
var _leaving := false
var _fade: ColorRect
var _loading := false
var _loading_label: Label
var _loading_started := 0.0
var _net: Node  ## NetSession (autoload)
var _mp := false  ## sala do multijogador nesta tela
var _tags := {}  ## id -> Label "Jogador N" acima do personagem
var _status: Label
var _problem := ""  ## a sala não abriu (porta ocupada, Steam fechada)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load(ART + "background.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	add_child(_fireflies())
	var title := _label("Escolha seu protagonista", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_top = 40
	title.offset_left = -300
	title.offset_right = 300
	add_child(title)
	for id in ORDER:
		_textures[id] = [load(ART + id + "_sit.png"), load(ART + id + "_look.png")]
		var shadow := Polygon2D.new()
		shadow.color = Color(0.02, 0.05, 0.06, 0.45)
		add_child(shadow)
		_shadows[id] = shadow
		figures[id] = _figure(id)
		panels[id] = _panel(id)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 24)
	_buttons.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_buttons.offset_top = -100
	_buttons.offset_bottom = -44
	_buttons.offset_left = -260
	_buttons.offset_right = 260
	add_child(_buttons)
	_confirm = _button("Confirmar", _on_confirm)
	_confirm.disabled = true
	_buttons.add_child(_confirm)
	_buttons.add_child(_button("Voltar", _on_back))
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_net()
	add_child(_fade)
	resized.connect(_layout)
	_layout()
	_refresh()


## Sala: o anfitrião abre ao chegar aqui; o convidado chega já conectado.
func _setup_net() -> void:
	_net = get_node_or_null("/root/NetSession")
	if _net == null: return
	if not str(_net.pending_host).is_empty():
		_problem = _net.open_pending_host()
		_mp = true
	elif str(_net.mode) == "guest" and bool(_net.in_lobby):
		_mp = true
	if not _mp: return
	for id in ORDER:
		var tag := _label("", 22)
		tag.name = "Tag" + id.capitalize()
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.custom_minimum_size = Vector2(260, 0)
		add_child(tag)
		_tags[id] = tag
	_status = _label("", 18)
	_status.name = "LobbyStatus"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_status.offset_top = 86
	_status.offset_left = -360
	_status.offset_right = 360
	add_child(_status)
	_net.message.connect(_on_net_message)
	_net.peer_joined.connect(_on_peer_joined)
	_net.peer_left.connect(_on_peer_left)
	_net.status_changed.connect(_on_net_status)


func _layout() -> void:
	# De costas: as costas (borda de trás do desenho) se tocam no centro; pés no
	# gramado da clareira, com sombra. A arte olha para a direita; Aren é espelhado.
	var ground := size * Vector2(0.5, 0.8)
	var w := 128.0 * CARD_SCALE
	for id in ORDER:
		var f: TextureRect = figures[id]
		var used: Rect2 = (f.texture as Texture2D).get_image().get_used_rect()
		f.size = Vector2(w, w)
		f.pivot_offset = Vector2(w * 0.5, used.end.y * CARD_SCALE)
		var back := used.position.x * CARD_SCALE  # costas da arte (lado esquerdo)
		var x := ground.x - back if id == "moni" else ground.x - (w - back)
		f.position = Vector2(x, ground.y - used.end.y * CARD_SCALE).round()
		var shadow: Polygon2D = _shadows[id]
		var feet_w := used.size.x * CARD_SCALE * 0.5
		shadow.position = Vector2(ground.x + (feet_w * 0.9 if id == "moni" else -feet_w * 0.9), ground.y - 4)
		shadow.polygon = PackedVector2Array([Vector2(-feet_w, 0), Vector2(-feet_w * 0.7, -10), Vector2(feet_w * 0.7, -10), Vector2(feet_w, 0), Vector2(feet_w * 0.7, 10), Vector2(-feet_w * 0.7, 10)])
		var p: PanelContainer = panels[id]
		p.size = Vector2(280, 0)
		p.reset_size()
		p.position = Vector2(size.x * 0.05 if id == "aren" else size.x * 0.95 - p.size.x, size.y * 0.34).round()
	_place_tags()


## "Jogador N" centrado acima da cabeça (a altura muda com a linha "Pronto!").
func _place_tags() -> void:
	for id: String in _tags:
		var f: TextureRect = figures[id]
		var used: Rect2 = (f.texture as Texture2D).get_image().get_used_rect()
		var x := used.get_center().x * CARD_SCALE
		if f.flip_h: x = f.size.x - x
		var tag: Label = _tags[id]
		tag.reset_size()
		tag.position = Vector2(f.position.x + x - tag.size.x * 0.5, f.position.y + used.position.y * CARD_SCALE - tag.size.y - 6).round()


func _process(delta: float) -> void:
	# Respiração: leve subida e descida, cada um no seu ritmo.
	_breath += delta
	if _loading: _poll_loading()
	for i in ORDER.size():
		var f: TextureRect = figures[ORDER[i]]
		f.scale = Vector2(1.0, 1.0 + 0.012 * sin(_breath * 1.6 + i * 1.3))


func _figure(id: String) -> TextureRect:
	var f := TextureRect.new()
	f.name = id.capitalize()
	f.texture = _textures[id][0]
	f.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	f.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	f.flip_h = id == "aren"  # arte olha para a direita
	f.mouse_filter = Control.MOUSE_FILTER_STOP
	f.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	f.mouse_entered.connect(_on_hover.bind(id))
	f.mouse_exited.connect(_on_unhover.bind(id))
	f.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: select(id))
	add_child(f)
	return f


func _panel(id: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(280, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2a2230e6")
	style.border_color = Color("#c9a56a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", style)
	# Clicar no cartão com o nome também escolhe (benchmark 2026-11-27: só a figura respondia).
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.mouse_entered.connect(_on_hover.bind(id))
	p.mouse_exited.connect(_on_unhover.bind(id))
	p.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: select(id))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	p.add_child(column)
	var data: Dictionary = PROTAGONIST.ALL[id]
	var name_label := _label(str(data.name), 28)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	var blurb := _label(str(data.blurb), 16)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(256, 0)  # largura fixa: sem ela o texto quebrado estica o painel
	column.add_child(blurb)
	add_child(p)
	return p


## Realce de quem está em foco (cursor ou seleção); o outro esmaece.
func _refresh() -> void:
	var focus := selected if hovered.is_empty() else hovered
	for id in ORDER:
		var target := Color.WHITE if focus.is_empty() else (LIT if id == focus else DIM)
		var f: TextureRect = figures[id]
		f.create_tween().tween_property(f, "modulate", target, 0.25)
		var p: PanelContainer = panels[id]
		p.create_tween().tween_property(p, "modulate:a", 1.0 if (focus.is_empty() or id == focus) else 0.45, 0.25)
		# Olha por cima do ombro só enquanto está em foco (troca uma vez, sem repetir).
		f.texture = _textures[id][1] if id == focus else _textures[id][0]
	_confirm.disabled = selected.is_empty()
	if _mp: _refresh_lobby()


## Sala: quem escolheu quem (nas duas telas), prontidão e o que falta para começar.
func _refresh_lobby() -> void:
	var me := 2 if str(_net.mode) == "guest" else 1
	var theirs := str(_net.remote_protagonist) if bool(_net.connected) else ""
	for id: String in ORDER:
		var lines: PackedStringArray = []
		if id == selected: lines.append(_tag_text(me, true, bool(_net.local_ready)))
		if id == theirs: lines.append(_tag_text(3 - me, false, bool(_net.remote_ready)))
		(_tags[id] as Label).text = "\n".join(lines)
	_place_tags()
	_confirm.text = "Cancelar pronto" if bool(_net.local_ready) else "Pronto"
	_confirm.disabled = selected.is_empty() or selected == theirs
	var other := 3 - me
	if not bool(_net.connected):
		_status.text = _problem if not _problem.is_empty() else str(_net.status)
	elif theirs.is_empty():
		_status.text = "Jogador %d na sala. Esperando a escolha dele..." % other
	elif not bool(_net.local_ready):
		_status.text = "Escolha seu protagonista e aperte Pronto."
	elif not bool(_net.remote_ready):
		_status.text = "Esperando o Jogador %d ficar pronto..." % other
	else:
		_status.text = "Os dois prontos! Começando..." if me == 1 else "Os dois prontos! Esperando o anfitrião começar..."


static func _tag_text(n: int, me: bool, is_ready: bool) -> String:
	return "Jogador %d%s%s" % [n, " (você)" if me else "", "\nPronto!" if is_ready else ""]


func _on_hover(id: String) -> void:
	if hovered == id: return
	hovered = id
	_refresh()


func _on_unhover(id: String) -> void:
	if hovered != id: return
	hovered = ""
	_refresh()


func select(id: String) -> void:
	if _leaving or not PROTAGONIST.ALL.has(id): return
	# Sala: pronto trava a escolha; o protagonista do outro não pode ser escolhido.
	if _mp and (bool(_net.local_ready) or (bool(_net.connected) and id == str(_net.remote_protagonist))): return
	selected = id
	if _mp: _net.lobby_update(id, false)
	var f: TextureRect = figures[id]
	var t := f.create_tween()  # pequena reação: pulinho
	t.tween_property(f, "position:y", f.position.y - 10.0, 0.1)
	t.tween_property(f, "position:y", f.position.y, 0.14)
	_refresh()
	_confirm.grab_focus()


func _on_confirm() -> void:
	if selected.is_empty() or _leaving: return
	if _mp:  # Pronto / Cancelar pronto
		_net.lobby_update(selected, not bool(_net.local_ready))
		_refresh()
		_try_start()
		return
	_start(false)


## Anfitrião: os dois prontos com protagonistas diferentes -> os dois carregam o mapa.
func _try_start() -> void:
	if not _mp or _leaving or not _net.lobby_can_start(): return
	_net.send({"t": "lobby_start"})
	_net.lobby_begin()
	_start(false)


func _on_net_message(data: Dictionary) -> void:
	if _leaving: return
	match str(data.get("t", "")):
		"lobby":
			selected = str(_net.local_protagonist)  # empate na escolha: vale a do anfitrião
			_refresh()
			_try_start()
		"lobby_start":
			if str(_net.mode) != "guest": return
			if selected.is_empty(): selected = NET.other_of(str(_net.remote_protagonist))
			_net.local_protagonist = selected
			_net.lobby_begin()
			_start(true)


func _on_peer_joined(_who: String) -> void:
	if not _leaving: _refresh()


func _on_net_status(_text: String) -> void:
	if not _leaving: _refresh()


## O outro saiu: o anfitrião segue esperando; o convidado volta ao menu (a sala fechou).
func _on_peer_left() -> void:
	if _leaving: return
	if str(_net.mode) != "guest":
		_refresh()
		return
	_leaving = true
	_net.menu_notice = "O Jogador 1 fechou a sala."
	# Fora do aviso de desconexão: fechar o ENet dentro do próprio poll dele dá erro.
	(func() -> void:
		_net.leave()
		get_tree().change_scene_to_file(MENU)).call_deferred()


## Começa a partida nova; o convidado pula o despertar e já começa o tutorial dele.
func _start(guest: bool) -> void:
	_leaving = true
	GameClock.reset_new_game()
	SessionState.clear_session(get_tree())
	PROTAGONIST.choose(get_tree(), selected)
	if guest: NET.start_guest_tutorial(get_tree())
	# Carrega o mapa em segundo plano atrás de uma tela de carregamento (nada de
	# tela preta parada): escurece, mostra o nome e um pontinho pulsando.
	ResourceLoader.load_threaded_request(FOREST)
	_loading_label = _label(str(PROTAGONIST.ALL[selected].name) + " está despertando", 26)
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_loading_label.offset_left = -320
	_loading_label.offset_right = 320
	_loading_label.modulate.a = 0.0
	add_child(_loading_label)
	var t := create_tween().set_parallel()
	t.tween_property(_fade, "color:a", 0.92, 0.7)
	t.tween_property(_loading_label, "modulate:a", 1.0, 0.7)
	_loading = true
	_loading_started = _breath


func _poll_loading() -> void:
	_loading_label.text = str(PROTAGONIST.ALL[selected].name) + " está despertando" + ".".repeat(1 + int(_breath * 2.0) % 3)
	if _breath - _loading_started < 1.2:
		return  # tempo mínimo da transição, mesmo com o mapa já carregado
	if ResourceLoader.load_threaded_get_status(FOREST) == ResourceLoader.THREAD_LOAD_LOADED:
		_loading = false
		get_window().content_scale_size = Vector2i(960, 540)
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(FOREST))


func _on_back() -> void:
	if _leaving: return
	if _mp:  # sai da sala (o outro é avisado)
		_leaving = true
		_net.leave()
	get_tree().change_scene_to_file(MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		select("aren")
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		select("moni")
	elif event.is_action_pressed("ui_cancel"):
		_on_back()
	else:
		return
	get_viewport().set_input_as_handled()


func _fireflies() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 40
	p.lifetime = 6.0
	p.preprocess = 4.0
	p.position = Vector2(640, 360)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(660, 360)
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 12.0
	p.spread = 180.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(0.7, 1, 0.9, 0), Color(0.75, 1, 0.9, 0.9), Color(0.6, 0.85, 1, 0.5), Color(0.6, 0.85, 1, 0)])
	p.color_ramp = ramp
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = additive
	return p


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#f6e8c2"))
	label.add_theme_color_override("font_outline_color", Color("#1a1420"))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 52)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(action)
	return b

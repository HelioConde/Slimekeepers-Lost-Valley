extends Control
## Presentation scene; the existing prototype remains the source of gameplay.
const MenuTheme = preload("res://scripts/menu/menu_theme.gd")
const BoardDetails = preload("res://scripts/menu/board_details.gd")
const LogoPlaque = preload("res://scripts/menu/logo_plaque.gd")
const Ruins = preload("res://scripts/menu/ruins_backdrop.gd")
## Ações do menu (rótulo, nome do nó, ícone em assets/menu/ruins/icons/).
const ACTIONS := [["Novo Jogo","NovoJogo","novo_jogo"],["Continuar","Continuar","continuar"],
	["Multijogador","Multijogador","multijogador"],["Configurações","Configuracoes","configuracoes"],
	["Créditos","Creditos","creditos"],["Sair","Sair","sair"]]
const SessionState = preload("res://scripts/systems/session_state.gd")
const SaveGame = preload("res://scripts/systems/save_game.gd")
var panorama: Node2D
var logo: Panel
var buttons: VBoxContainer
var frame: PanelContainer
var mascot: AnimatedSprite2D
var _mascot_wait := 3.0
var options_layer: Control
var reduce_motion := false
var _crest: AnimatedSprite2D
var _prefs := ConfigFile.new()

func _ready() -> void:
	GameClock.stop()
	# Menu uses physical pixels; the gameplay's 960x540 canvas is restored on entry.
	get_window().content_scale_size = Vector2i.ZERO
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = MenuTheme.make_theme()
	_prefs.load("user://presentation.cfg")
	reduce_motion = _prefs.get_value("accessibility","reduce_motion",false)
	panorama = Node2D.new()
	panorama.name = "Panorama"
	panorama.z_index = -10
	add_child(panorama)
	var ruins := Ruins.new()
	ruins.name = "Ruins"
	panorama.add_child(ruins)
	ruins.reduce_motion = reduce_motion
	SaveGame.migrate_legacy()  # save de arquivo único vira o espaço 1 (sem apagar)
	_build_logo()
	_build_buttons()
	_build_mascot()
	resized.connect(_layout)
	_layout()
	buttons.get_child(0).grab_focus()
	if not reduce_motion:
		logo.modulate.a = 0
		buttons.modulate.a = 0
		var entrance := create_tween().set_parallel(true)
		entrance.tween_property(logo,"modulate:a",1.0,0.45)
		entrance.tween_property(buttons,"modulate:a",1.0,0.35).set_delay(0.15)

func _build_logo() -> void:
	logo = Panel.new()
	logo.name = "Logo"
	logo.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	var trim := LogoPlaque.new()
	logo.add_child(trim)
	trim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := Label.new()
	title.name = "Title"
	title.text = "SLIMEKEEPERS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font",MenuTheme.font(true))
	title.add_theme_font_size_override("font_size",72)
	title.add_theme_color_override("font_color",Color("#ffdfa0"))
	title.add_theme_color_override("font_outline_color",Color("#342934"))
	title.add_theme_constant_override("outline_size",6)
	title.add_theme_color_override("font_shadow_color",Color("#251e2b"))
	title.add_theme_constant_override("shadow_offset_y",4)
	logo.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 20
	title.offset_bottom = 94
	var plaque := PanelContainer.new()
	var plaque_style := MenuTheme.panel(8)
	plaque_style.bg_color = Color("#e8c78a")
	plaque_style.border_color = Color("#62452f")
	plaque_style.set_border_width_all(3)
	plaque_style.border_width_bottom = 5
	plaque.add_theme_stylebox_override("panel",plaque_style)
	logo.add_child(plaque)
	plaque.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	plaque.offset_left = 136
	plaque.offset_right = -136
	plaque.offset_top = -32
	plaque.offset_bottom = 18
	var subtitle := Label.new()
	subtitle.text = "LOST VALLEY"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font",MenuTheme.font(true))
	subtitle.add_theme_font_size_override("font_size",28)
	plaque.add_child(subtitle)
	_crest = AnimatedSprite2D.new()
	_crest.sprite_frames = load("res://assets/slimes/bestiary/gelito/gelito_frames.tres")
	_crest.scale = Vector2(2,2)
	_crest.play("idle")
	logo.add_child(_crest)
	_crest.speed_scale = 0 if reduce_motion else 1

func _build_buttons() -> void:
	frame = PanelContainer.new()
	frame.name = "ActionsFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stone := MenuTheme.panel(10)
	stone.bg_color = Color(0.17,0.19,0.2,0.86)
	stone.border_color = Color("#6f7d52")
	stone.set_border_width_all(3)
	stone.shadow_color = Color(0,0,0,0.35)
	stone.shadow_size = 6
	frame.add_theme_stylebox_override("panel",stone)
	add_child(frame)
	buttons = VBoxContainer.new()
	buttons.name = "Actions"
	buttons.add_theme_constant_override("separation",10)
	add_child(buttons)
	for action in ACTIONS:
		var caption: String = action[0]
		var button := Button.new()
		button.name = action[1]
		button.text = caption
		button.icon = load("res://assets/menu/ruins/icons/%s.png" % action[2])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_constant_override("h_separation",14)
		button.custom_minimum_size = Vector2(0,52)
		button.add_theme_font_size_override("font_size",24)
		button.add_theme_font_override("font",MenuTheme.font(true))
		if caption == "Novo Jogo":
			var primary := MenuTheme.button(&"normal")
			primary.bg_color = MenuTheme.CREAM
			button.add_theme_stylebox_override("normal",primary)
			var primary_hover := MenuTheme.button(&"hover")
			primary_hover.bg_color = Color("#f6daa1")
			button.add_theme_stylebox_override("hover",primary_hover)
			var primary_pressed := MenuTheme.button(&"pressed")
			primary_pressed.bg_color = Color("#cbaa72")
			button.add_theme_stylebox_override("pressed",primary_pressed)
			for font_state in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:
				button.add_theme_color_override(font_state,MenuTheme.INK)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		buttons.add_child(button)
		var trim := BoardDetails.new()
		button.add_child(trim)
		trim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.mouse_entered.connect(func():
			if not button.disabled:
				button.grab_focus()
		)
		button.focus_entered.connect(_highlight.bind(button,true))
		button.focus_exited.connect(_highlight.bind(button,false))
		match caption:
			"Novo Jogo": button.pressed.connect(_start_game)
			"Continuar":
				# Ativo quando algum espaço tem save (gravado ao amanhecer e ao dormir).
				if not SaveGame.used_slots().is_empty():
					button.pressed.connect(_continue_game)
				else:
					button.disabled = true
					button.tooltip_text = "O jogo salva sozinho a cada amanhecer."
					button.focus_mode = Control.FOCUS_NONE
			"Multijogador": button.pressed.connect(_show_multiplayer)
			"Configurações": button.pressed.connect(_show_options)
			"Créditos": button.pressed.connect(_show_notice.bind("Créditos",
				["Slimekeepers: Lost Valley","Criação e direção: Helio Conde","Motor: Godot Engine 4.7",
				"Arte em pixel: PixelLab, com ajustes do projeto","Fonte: Pixelify Sans"]))
			"Sair": button.pressed.connect(func(): get_tree().quit())
	var active := buttons.get_children().filter(func(b): return not (b as Button).disabled)
	for i in range(active.size()):
		var button := active[i] as Button
		button.focus_neighbor_top = button.get_path_to(active[(i+active.size()-1)%active.size()])
		button.focus_neighbor_bottom = button.get_path_to(active[(i+1)%active.size()])
		button.focus_next = button.focus_neighbor_bottom
		button.focus_previous = button.focus_neighbor_top

## Slime azul ao lado do menu: respira, pisca e às vezes reage (frames da Bolhinha).
func _build_mascot() -> void:
	mascot = AnimatedSprite2D.new()
	mascot.name = "Mascot"
	mascot.sprite_frames = load("res://assets/slimes/living_v3/bolhinha/frames.tres")
	mascot.play("idle")
	mascot.animation_finished.connect(func(): mascot.play("idle"))
	add_child(mascot)
	mascot.speed_scale = 0 if reduce_motion else 1

func _process(delta: float) -> void:
	if reduce_motion or not is_instance_valid(mascot): return
	var base: float = mascot.get_meta("base_scale", 1.0)
	var breath := sin(Time.get_ticks_msec() / 1000.0 * 2.2)
	mascot.scale = Vector2(base * (1.0 + breath * 0.025), base * (1.0 - breath * 0.025))
	_mascot_wait -= delta
	if _mascot_wait <= 0.0 and mascot.animation == &"idle":
		_mascot_wait = randf_range(3.5, 7.0)
		mascot.play([&"blink", &"blink", &"curious", &"happy"].pick_random())

func _highlight(button: Button, focused: bool) -> void:
	if focused and is_instance_valid(mascot) and not reduce_motion and randf() < 0.25:
		mascot.play(&"happy")
	var target := Color("#fff0c7") if focused else Color.WHITE
	if reduce_motion:
		button.modulate = target
	else:
		create_tween().tween_property(button,"modulate",target,0.12)

func _layout() -> void:
	if not is_instance_valid(logo): return
	# Cenário 480×270 em escala inteira cobrindo a tela; o corte sobra à esquerda/topo
	# para manter a cachoeira (direita) e o caminho (embaixo) à vista.
	var scenery_scale := ceilf(maxf(size.x/Ruins.SIZE.x,size.y/Ruins.SIZE.y))
	panorama.scale = Vector2.ONE * scenery_scale
	panorama.position = Vector2(round((size.x-Ruins.SIZE.x*scenery_scale)*0.8),round(size.y-Ruins.SIZE.y*scenery_scale))
	var ui_scale := maxf(1.0,floor(minf(size.x/1280.0,size.y/720.0)*2.0)/2.0)
	var compact := size.y < 600
	for control in [logo,buttons,frame]:
		control.scale = Vector2.ONE * ui_scale
	var left := roundf(clampf(size.x*0.06,24,140))
	logo.size = Vector2(600,140)
	logo.position = Vector2(left-40*ui_scale,(30 if compact else 44)*ui_scale).round()
	_crest.position = Vector2(300,-15)
	buttons.add_theme_constant_override("separation",6 if compact else 10)
	for button in buttons.get_children():
		button.custom_minimum_size.y = 36 if compact else 52
	buttons.size = Vector2(360,0)
	buttons.reset_size()
	buttons.position = Vector2(left+18*ui_scale,logo.position.y+(150 if compact else 176)*ui_scale).round()
	frame.size = buttons.size + Vector2(36,36)
	frame.position = buttons.position - Vector2(18,18)*ui_scale
	var base := 2.0*ui_scale
	mascot.set_meta("base_scale",base)
	mascot.scale = Vector2.ONE*base
	mascot.position = frame.position + Vector2(frame.size.x*ui_scale+20*ui_scale,frame.size.y*ui_scale-30*ui_scale)
	if is_instance_valid(options_layer):
		var panel := options_layer.get_node("Card") as PanelContainer
		panel.scale = Vector2.ONE * ui_scale
		panel.position = ((size - panel.size*ui_scale)/2).round()

## Continuar (relatório de playtest IDs 56 e 58): com um só espaço salvo, abre direto;
## com mais de um, mostra a lista para escolher a partida.
func _continue_game() -> void:
	var used := SaveGame.used_slots()
	if used.size() == 1: _load_slot(int(used[0]))
	elif used.size() > 1: _show_slots(false)

func _load_slot(n: int) -> void:
	SaveGame.use_slot(n)
	var region := SaveGame.restore(get_tree(), GameClock)
	if region.is_empty():
		return
	get_window().content_scale_size = Vector2i(960,540)
	get_tree().change_scene_to_file(region)

## Novo Jogo escolhe o espaço; espaço ocupado pede confirmação antes de ser substituído.
## A seleção de protagonista reinicia a partida ao confirmar.
func _start_game() -> void:
	_show_slots(true)

func _new_in_slot(n: int) -> void:
	SaveGame.use_slot(n)
	get_tree().change_scene_to_file("res://scenes/protagonist_select.tscn")

static func slot_label(n: int) -> String:
	var i := SaveGame.info(n)
	if i.is_empty(): return "Espaço %d · vazio" % n
	var who: String = {"aren": "Aren", "moni": "Moni"}.get(str(i.protagonist), "?")
	var when: Dictionary = Time.get_datetime_dict_from_unix_time(int(i.saved_at) + int(Time.get_time_zone_from_system().bias) * 60)  # bias em minutos
	return "Espaço %d · Dia %d · %s%s · salvo %02d/%02d %02d:%02d" % [n, int(i.day), who,
		" · multijogador" if str(i.mode) == "mp" else "", when.day, when.month, when.hour, when.minute]

func _show_slots(new_game: bool) -> void:
	var actions: Array = []
	for n in range(1, SaveGame.SLOTS + 1):
		var empty := SaveGame.info(n).is_empty()
		if not new_game and empty: continue
		var pick: Callable = (func() -> void: _new_in_slot(n)) if new_game and empty else 			((func() -> void: _confirm_overwrite(n)) if new_game else (func() -> void: _load_slot(n)))
		actions.append([slot_label(n), pick])
	actions.append(["Voltar", _close_options])
	_show_dialog("Novo jogo" if new_game else "Continuar", ["Escolha o espaço da partida."], actions)

func _confirm_overwrite(n: int) -> void:
	_close_options()
	_show_dialog("Substituir?", [slot_label(n), "A partida deste espaço será substituída pela nova quando o jogo salvar. As outras não mudam."],
		[["Substituir e começar", func() -> void: _new_in_slot(n)], ["Voltar", func() -> void:
			_close_options()
			_show_slots(true)]])

## Janela com título, textos e botões [[texto, callable], ...] no estilo das demais.
func _show_dialog(heading: String, lines: Array, actions: Array) -> void:
	if is_instance_valid(options_layer): return
	_show_notice(heading, lines)
	var stack := options_layer.get_node("Card").get_child(0) as VBoxContainer
	var close := stack.get_node("Close") as Button
	var first: Button = null
	for a: Array in actions:
		var b := Button.new()
		b.text = str(a[0])
		b.custom_minimum_size.y = 46
		b.pressed.connect(a[1])
		stack.add_child(b)
		if first == null: first = b
	stack.remove_child(close)
	close.queue_free()
	(options_layer.get_node("Card") as Control).reset_size()
	_layout()
	if first: first.grab_focus()

var _opener: Control

## Janela simples (Multijogador em desenvolvimento, Créditos) no estilo das configurações.
func _show_notice(heading: String, lines: Array) -> void:
	if is_instance_valid(options_layer): return
	_opener = get_viewport().gui_get_focus_owner()
	for button in buttons.get_children(): button.focus_mode = Control.FOCUS_NONE
	options_layer = Control.new()
	options_layer.name = "Notice"
	add_child(options_layer)
	options_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.08,0.09,0.13,0.72)
	options_layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.name = "Card"
	card.custom_minimum_size = Vector2(460,0)
	options_layer.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",14)
	card.add_child(stack)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size",34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	for line in lines:
		var text := Label.new()
		text.text = str(line)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = 440  # largura para quebrar a linha (sem isso a janela estica)
		stack.add_child(text)
	var close := Button.new()
	close.name = "Close"
	close.text = "Voltar"
	close.custom_minimum_size.y = 54
	close.pressed.connect(_close_options)
	stack.add_child(close)
	card.reset_size()
	_layout()
	close.grab_focus()

## Multijogador P2P (decisão do usuário: pela Steam). Dois jogadores: quem hospeda
## escolhe Aren ou Moni; quem entra joga com o outro. Rede local para testar sem Steam.
func _show_multiplayer() -> void:
	if is_instance_valid(options_layer): return
	_opener = get_viewport().gui_get_focus_owner()
	for button in buttons.get_children(): button.focus_mode = Control.FOCUS_NONE
	var net := get_node("/root/NetSession")
	options_layer = Control.new()
	options_layer.name = "Multiplayer"
	add_child(options_layer)
	options_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.08,0.09,0.13,0.72)
	options_layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.name = "Card"
	card.custom_minimum_size = Vector2(480,0)
	options_layer.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",10)
	card.add_child(stack)
	var title := Label.new()
	title.text = "Multijogador"
	title.add_theme_font_size_override("font_size",34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	var info := Label.new()
	info.text = "Quem hospeda escolhe Aren ou Moni; quem entra joga com o outro."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size.x = 440  # largura para quebrar a linha (sem isso a janela estica)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(info)
	var status := Label.new()
	status.name = "Status"
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 440  # largura para quebrar a linha (sem isso a janela estica)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.text = str(net.status)
	stack.add_child(status)
	net.status_changed.connect(func(text: String) -> void:
		if is_instance_valid(status): status.text = text)
	var host_steam := Button.new()
	host_steam.name = "HostSteam"
	host_steam.text = "Hospedar pela Steam"
	host_steam.pressed.connect(func() -> void:
		var problem: String = net.steam_init()
		if not problem.is_empty():
			status.text = problem
			return
		net.pending_host = "steam"
		_start_game())
	stack.add_child(host_steam)
	var host_lan := Button.new()
	host_lan.name = "HostLan"
	host_lan.text = "Hospedar na rede local"
	host_lan.pressed.connect(func() -> void:
		net.pending_host = "enet"
		_start_game())
	stack.add_child(host_lan)
	var row := HBoxContainer.new()
	stack.add_child(row)
	var address := LineEdit.new()
	address.name = "Address"
	address.text = "127.0.0.1"
	address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(address)
	var join_lan := Button.new()
	join_lan.name = "JoinLan"
	join_lan.text = "Entrar"
	join_lan.pressed.connect(func() -> void:
		var target := address.text.strip_edges()
		# Número grande = ID de sala da Steam; senão, IP da rede local.
		var problem: String = net.join_steam(int(target)) if target.is_valid_int() and target.length() > 10 else net.join_enet(target)
		if not problem.is_empty(): status.text = problem)
	row.add_child(join_lan)
	var steam_hint := Label.new()
	steam_hint.text = "Pela Steam: aceite o convite do amigo com esta janela aberta, ou digite o ID da sala acima e clique em Entrar."
	steam_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	steam_hint.custom_minimum_size.x = 440  # largura para quebrar a linha (sem isso a janela estica)
	steam_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	steam_hint.add_theme_font_size_override("font_size",14)
	stack.add_child(steam_hint)
	var close := Button.new()
	close.name = "Close"
	close.text = "Voltar"
	close.custom_minimum_size.y = 48
	close.pressed.connect(_close_options)
	stack.add_child(close)
	net.steam_init()  # liga a Steam (se aberta) para receber convites
	card.reset_size()
	_layout()
	host_steam.grab_focus()

func _show_options() -> void:
	if is_instance_valid(options_layer): return
	_opener = get_viewport().gui_get_focus_owner()
	for button in buttons.get_children(): button.focus_mode = Control.FOCUS_NONE
	options_layer = Control.new()
	options_layer.name = "Options"
	add_child(options_layer)
	options_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.08,0.09,0.13,0.72)
	options_layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.name = "Card"
	card.custom_minimum_size = Vector2(460,420)
	options_layer.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",18)
	card.add_child(stack)
	var title := Label.new()
	title.text = "Configurações"
	title.add_theme_font_size_override("font_size",34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	var motion := CheckButton.new()
	motion.name = "ReduceMotion"
	motion.text = "Reduzir movimento ambiental"
	motion.button_pressed = reduce_motion
	motion.toggled.connect(_set_reduced_motion)
	stack.add_child(motion)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Tela cheia"
	fullscreen.button_pressed = get_window().mode == Window.MODE_FULLSCREEN
	fullscreen.toggled.connect(func(enabled: bool):
		get_window().mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED
	)
	stack.add_child(fullscreen)
	var volume_label := Label.new()
	volume_label.text = "Volume do ambiente"
	stack.add_child(volume_label)
	var volume := HSlider.new()
	volume.name = "AmbientVolume"
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 5
	volume.value = float(_prefs.get_value("audio","ambient_volume",0.65))*100
	volume.custom_minimum_size.y = 22
	volume.value_changed.connect(func(value:float):
		_prefs.set_value("audio","ambient_volume",value/100.0)
		_prefs.save("user://presentation.cfg"); preload("res://scripts/systems/sfx.gd").reload_settings()
	)
	stack.add_child(volume)
	var mute := CheckButton.new()
	mute.name = "MuteAmbient"
	mute.text = "Silenciar ambiente"
	mute.button_pressed = bool(_prefs.get_value("audio","muted",false))
	mute.toggled.connect(func(enabled:bool):
		_prefs.set_value("audio","muted",enabled)
		_prefs.save("user://presentation.cfg"); preload("res://scripts/systems/sfx.gd").reload_settings()
	)
	stack.add_child(mute)
	# Disco de ações do slime: clique (padrão) ou segurar [F] e soltar (slime_action_disc.gd).
	var disc_hold := CheckButton.new()
	disc_hold.name = "SlimeDiscHold"
	disc_hold.text = "Disco do slime: segurar F e soltar"
	disc_hold.button_pressed = str(_prefs.get_value("controls", "slime_disc", "clique")) == "segurar"
	disc_hold.toggled.connect(func(enabled: bool):
		_prefs.set_value("controls", "slime_disc", "segurar" if enabled else "clique")
		_prefs.save("user://presentation.cfg")
	)
	stack.add_child(disc_hold)
	var close := Button.new()
	close.name = "Close"
	close.text = "Voltar"
	close.custom_minimum_size.y = 54
	close.pressed.connect(_close_options)
	stack.add_child(close)
	var focusables := [motion,fullscreen,volume,mute,close]
	for i in focusables.size():
		focusables[i].focus_neighbor_top = focusables[i].get_path_to(focusables[(i+focusables.size()-1)%focusables.size()])
		focusables[i].focus_neighbor_bottom = focusables[i].get_path_to(focusables[(i+1)%focusables.size()])
		focusables[i].focus_previous = focusables[i].focus_neighbor_top
		focusables[i].focus_next = focusables[i].focus_neighbor_bottom
	card.position = ((size-card.size)/2).round()
	_layout()
	motion.grab_focus()

func _set_reduced_motion(enabled: bool) -> void:
	_apply_reduced_motion(enabled)
	_prefs.set_value("accessibility","reduce_motion",enabled)
	_prefs.save("user://presentation.cfg"); preload("res://scripts/systems/sfx.gd").reload_settings()

func _apply_reduced_motion(enabled: bool) -> void:
	reduce_motion = enabled
	panorama.get_node("Ruins").reduce_motion = enabled
	if is_instance_valid(mascot): mascot.speed_scale = 0 if enabled else 1
	_crest.speed_scale = 0 if enabled else 1

func _close_options() -> void:
	options_layer.queue_free()
	options_layer = null
	for button in buttons.get_children():
		if not (button as Button).disabled: button.focus_mode = Control.FOCUS_ALL
	if is_instance_valid(_opener): _opener.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_instance_valid(options_layer):
		get_viewport().set_input_as_handled()
		_close_options()

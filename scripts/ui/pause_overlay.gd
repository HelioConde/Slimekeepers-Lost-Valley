extends CanvasLayer
## Menu do Esc (playtest IDs 61 e 22). Esc abre: Continuar, Opções, Tutorial e Voltar ao
## menu principal (com confirmação e o estado do último salvamento). Fechar Opções/Tutorial
## volta a este menu. Os painéis (mochila, fabricação, baú) tratam o Esc antes e se fecham
## sozinhos: este menu não abre por cima deles.
## Solo: pausa o SceneTree. Multijogador (NetSession.mode != ""): NÃO pausa; só congela o
## jogador local (como os painéis), o mundo, o relógio e a rede seguem.
const FONT := preload("res://assets/fonts/ui_font.tres")  # dígitos legíveis (playtest ID 33)
const SAVE := preload("res://scripts/systems/save_game.gd")
const SFX := preload("res://scripts/systems/sfx.gd")
const PREFS_PATH := "user://presentation.cfg"
const MENU_SCENE := "res://scenes/start_menu.tscn"
## Teclas que a navegação do próprio menu usa; as demais não passam ao jogo em MP.
const NAV_ACTIONS := ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_cancel", "ui_focus_next", "ui_focus_prev"]
const HELP := "Andar: [W] [A] [S] [D] (segure [Shift] para correr)\n" \
	+ "Pegar, arrancar, abrir e usar: [F] ou clique esquerdo\n" \
	+ "Mochila: [E]  ·  Fabricação e construções: [B]\n" \
	+ "Barra de itens: [1] a [0] ou a roda do mouse\n" \
	+ "Este menu: [Esc]\n\n" \
	+ "Como o jogo anda: junte gravetos, pedrinhas e fibras, faça cordas no [B], monte a bancada e faça o machado para cortar árvores.\n\n" \
	+ "Slimes: escolha uma comida na barra e aperte [F] perto de um slime para criar amizade.\n\n" \
	+ "Multijogador: pelo menu principal."

var continue_button: Button
var options_button: Button
var tutorial_button: Button
var main_menu_button: Button
var volume_slider: HSlider
var mute_check: CheckButton
var options_back: Button
var tutorial_back: Button
var confirm_button: Button
var cancel_button: Button
var save_label: Label
var title_label: Label
var _panel: Control
var _hint: Label
var _pages: Dictionary = {}
var _page := "menu"
var _opener: Button
var _mp := false  # modo em que o menu foi aberto (o fechamento desfaz o mesmo)
var _player_was_active := true


func _ready() -> void:
	name = "PauseOverlay"
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.hide()


func is_open() -> bool:
	return is_instance_valid(_panel) and _panel.visible


## Há partida multijogador em andamento (host ou convidado).
func is_multiplayer() -> bool:
	var net := get_node_or_null("/root/NetSession")
	return net != null and str(net.get("mode")) != ""


func open() -> void:
	if is_open():
		return
	_mp = is_multiplayer()
	if _mp:
		_freeze_player(true)
	elif get_tree().paused:
		return  # não rouba uma pausa que não é nossa
	else:
		get_tree().paused = true
	_opener = null
	_panel.show()
	_show_page("menu")


func close() -> void:
	if not is_open():
		return
	_panel.hide()
	if _mp:
		_freeze_player(false)
	else:
		get_tree().paused = false


## Esc: fecha o submenu (volta ao menu) ou o próprio menu; abre se estiver fechado.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if not is_open():
		open()
	elif _page == "menu":
		close()
	else:
		_show_page("menu")
	if is_inside_tree():
		get_viewport().set_input_as_handled()


## Em MP a árvore não pausa, então os atalhos do jogo (B, E, F...) não podem chegar aos
## painéis e ao jogador enquanto o menu está aberto; só a navegação do menu passa.
func _input(event: InputEvent) -> void:
	if not _mp or not is_open() or not (event is InputEventKey):
		return
	for action: String in NAV_ACTIONS:
		if event.is_action(action):
			return
	get_viewport().set_input_as_handled()


func _freeze_player(on: bool) -> void:
	var parent := get_parent()
	var player: Variant = parent.get("player") if parent else null
	if not is_instance_valid(player):
		return
	if on:
		_player_was_active = player.is_physics_processing()
		player.set_physics_process(false)
		if "velocity" in player:
			player.velocity = Vector2.ZERO
	else:
		player.set_physics_process(_player_was_active)


func _show_page(page: String) -> void:
	_page = page
	for key: String in _pages:
		(_pages[key] as Control).visible = key == page
	match page:
		"menu":
			title_label.text = "Menu — a partida continua" if _mp else "Jogo pausado"
			_hint.text = "Esc para voltar ao jogo"
			(_opener if is_instance_valid(_opener) else continue_button).grab_focus()
		"options":
			title_label.text = "Opções"
			_hint.text = "Esc para voltar ao menu"
			var audio := _read_audio()
			volume_slider.set_value_no_signal(float(audio.volume) * 100.0)
			mute_check.set_pressed_no_signal(bool(audio.muted))
			volume_slider.grab_focus()
		"tutorial":
			title_label.text = "Primeiros passos"
			_hint.text = "Esc para voltar ao menu"
			tutorial_back.grab_focus()
		"confirm":
			title_label.text = "Voltar ao menu principal?"
			_hint.text = "Esc para cancelar"
			save_label.text = _save_text()
			cancel_button.grab_focus()


func _go(page: String, opener: Button) -> void:
	_opener = opener
	_show_page(page)


func _read_audio() -> Dictionary:
	var cfg := ConfigFile.new()
	var out := {"volume": 0.65, "muted": false}
	if cfg.load(PREFS_PATH) == OK:
		out.volume = clampf(float(cfg.get_value("audio", "ambient_volume", 0.65)), 0.0, 1.0)
		out.muted = bool(cfg.get_value("audio", "muted", false))
	return out


## Grava no mesmo arquivo do menu inicial e aplica na hora (efeitos, ambiente e música).
func _save_audio(_value: Variant = null) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PREFS_PATH)  # mantém as outras seções
	var volume := volume_slider.value / 100.0
	cfg.set_value("audio", "ambient_volume", volume)
	cfg.set_value("audio", "muted", mute_check.button_pressed)
	cfg.save(PREFS_PATH)
	SFX.reload_settings()
	var region := get_parent()
	if region == null:
		return
	var ambience: Variant = region.get("environmental_audio")
	if is_instance_valid(ambience):
		ambience.set_muted(mute_check.button_pressed)
		ambience.set_ambient_volume(volume)
	var music := region.get_node_or_null("RegionMusic")
	if music and music.has_method("apply_settings"):
		music.apply_settings()


## Estado do último save do espaço atual e o que a saída faz.
func _save_text() -> String:
	var info := SAVE.info(SAVE.slot)
	var text := ""
	if info.is_empty():
		text = "Ainda não há salvamento no espaço %d." % SAVE.slot
	else:
		text = "Último salvamento: dia %d" % int(info.day)
		if int(info.saved_at) > 0:
			var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
			var d := Time.get_datetime_dict_from_unix_time(int(info.saved_at) + bias)
			text += ", %02d/%02d às %02d:%02d" % [d.day, d.month, d.hour, d.minute]
		text += " (espaço %d)." % SAVE.slot
	text += " O jogo salva sozinho a cada amanhecer; o que você fez depois disso será perdido."
	if _mp:
		var mode := str(get_node("/root/NetSession").get("mode"))
		text += "\n\n" + ("Você é o anfitrião: a sessão será encerrada para o outro jogador." if mode == "host" else "Você sai da partida do anfitrião.")
	return text


func _leave_to_menu() -> void:
	var net := get_node_or_null("/root/NetSession")
	if _mp and net:
		net.call("leave")
	close()
	get_tree().change_scene_to_file(MENU_SCENE)


func _build() -> void:
	_panel = ColorRect.new()
	_panel.name = "Shade"
	(_panel as ColorRect).color = Color(0.08, 0.06, 0.1, 0.55)
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
	card.custom_minimum_size = Vector2(320, 0)
	center.add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)

	title_label = _label("", 20, "#3e5c43")
	column.add_child(title_label)

	var menu := _page_box(column, "menu")
	continue_button = _button(menu, "ContinueButton", "Continuar", close)
	options_button = _button(menu, "OptionsButton", "Opções", func() -> void: _go("options", options_button))
	tutorial_button = _button(menu, "TutorialButton", "Tutorial", func() -> void: _go("tutorial", tutorial_button))
	main_menu_button = _button(menu, "MainMenuButton", "Voltar ao menu principal", func() -> void: _go("confirm", main_menu_button))

	var options := _page_box(column, "options")
	options.add_child(_label("Volume do ambiente", 15, "#402f39", HORIZONTAL_ALIGNMENT_LEFT))
	volume_slider = HSlider.new()
	volume_slider.name = "AmbientVolume"
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 5
	volume_slider.custom_minimum_size = Vector2(260, 22)
	volume_slider.value_changed.connect(_save_audio)
	options.add_child(volume_slider)
	mute_check = CheckButton.new()
	mute_check.name = "MuteAmbient"
	mute_check.text = "Silenciar ambiente"
	mute_check.add_theme_font_override("font", FONT)
	mute_check.add_theme_font_size_override("font_size", 15)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		mute_check.add_theme_color_override(state, Color("#402f39"))
	mute_check.toggled.connect(_save_audio)
	options.add_child(mute_check)
	options_back = _button(options, "OptionsBack", "Voltar", func() -> void: _show_page("menu"))

	var tutorial := _page_box(column, "tutorial")
	var help := _label(HELP, 14, "#402f39", HORIZONTAL_ALIGNMENT_LEFT)
	help.name = "HelpText"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(440, 0)
	tutorial.add_child(help)
	tutorial_back = _button(tutorial, "TutorialBack", "Voltar", func() -> void: _show_page("menu"))

	var confirm := _page_box(column, "confirm")
	save_label = _label("", 14, "#402f39", HORIZONTAL_ALIGNMENT_LEFT)
	save_label.name = "SaveStatus"
	save_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_label.custom_minimum_size = Vector2(380, 0)
	confirm.add_child(save_label)
	confirm_button = _button(confirm, "ConfirmExitButton", "Sair para o menu", _leave_to_menu)
	cancel_button = _button(confirm, "CancelExitButton", "Cancelar", func() -> void: _show_page("menu"))

	_hint = _label("", 13, "#694657")
	column.add_child(_hint)


func _page_box(parent: Control, key: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = key.capitalize() + "Page"
	box.add_theme_constant_override("separation", 10)
	parent.add_child(box)
	_pages[key] = box
	return box


func _button(parent: Control, node_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _label(text: String, size: int, color: String, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(color))
	return label

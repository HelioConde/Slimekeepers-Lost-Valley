extends SceneTree
## Playtest IDs 61 e 22: menu do Esc (Continuar, Opções, Tutorial, Voltar ao menu principal).
## Solo pausa a árvore; em MP (NetSession.mode != "") só congela o jogador local.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_pause_menu.gd

const TUTORIAL := preload("res://scripts/ui/tutorial_hud.gd")
const SFX := preload("res://scripts/systems/sfx.gd")
const SAVE := preload("res://scripts/systems/save_game.gd")
const PREFS := "user://presentation.cfg"
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func frames(n: int = 3) -> void:
	for i in n: await process_frame


func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames()


func run() -> void:
	var had_prefs := FileAccess.file_exists(PREFS)
	var prefs_backup := FileAccess.get_file_as_bytes(PREFS) if had_prefs else PackedByteArray()
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	await frames(20)
	var overlay: CanvasLayer = region.get_node("PauseOverlay")
	var player: CharacterBody2D = region.get("player")
	var tutorial_before: Variant = get_meta(TUTORIAL.KEY, -1)

	check(not region.has_node("HUD/Interface/ReturnToMenu"), "botão Menu do HUD não existe mais")
	check(not overlay.is_open() and not paused, "menu começa fechado")

	# Solo: Esc abre com os 4 botões e pausa de verdade.
	await key(KEY_ESCAPE)
	check(overlay.is_open() and paused, "solo: Esc abre o menu e pausa a árvore")
	check(overlay.title_label.text == "Jogo pausado", "solo: título 'Jogo pausado'")
	var labels := ["Continuar", "Opções", "Tutorial", "Voltar ao menu principal"]
	var buttons: Array = [overlay.continue_button, overlay.options_button, overlay.tutorial_button, overlay.main_menu_button]
	for i in 4:
		check(buttons[i].is_visible_in_tree() and buttons[i].text == labels[i], "botão '%s' visível" % labels[i])
	check(overlay.continue_button.has_focus(), "Continuar começa com o foco do teclado")
	check(overlay.friend_button.is_visible_in_tree(), "solo: \"Abrir para amigo\" aparece no menu do Esc")

	# Opções: abre, grava no presentation.cfg, aplica e volta ao menu.
	overlay.options_button.pressed.emit()
	await frames()
	check(overlay.volume_slider.is_visible_in_tree() and not overlay.continue_button.is_visible_in_tree(), "Opções abre")
	check(overlay.volume_slider.has_focus(), "Opções: foco no volume")
	overlay.volume_slider.value = 35
	overlay.mute_check.button_pressed = true
	await frames()
	var cfg := ConfigFile.new()
	cfg.load(PREFS)
	check(is_equal_approx(float(cfg.get_value("audio", "ambient_volume", -1.0)), 0.35) and bool(cfg.get_value("audio", "muted", false)), "volume e mudo gravados em presentation.cfg")
	check(SFX._settings_volume() == 0.0, "mudo vale na hora para os efeitos")
	overlay.mute_check.button_pressed = false
	await frames()
	check(is_equal_approx(SFX._settings_volume(), 0.35), "sem mudo, o volume escolhido vale na hora")
	# Playtest ID 15: música com volume próprio, sem mexer no ambiente.
	overlay.music_slider.value = 80
	await frames()
	cfg.load(PREFS)
	check(is_equal_approx(float(cfg.get_value("audio", "music_volume", -1.0)), 0.8) and is_equal_approx(float(cfg.get_value("audio", "ambient_volume", -1.0)), 0.35), "música tem volume próprio (80%) e o ambiente fica em 35%")
	var music := region.get_node_or_null("RegionMusic")
	var song: AudioStreamPlayer = music.get_node_or_null("Music") if music else null
	if song: check(absf(db_to_linear(song.volume_db) - 0.8 * music.GAIN) < 0.01, "a faixa tocando segue o volume da música (%.3f, esperado %.3f)" % [db_to_linear(song.volume_db), 0.8 * music.GAIN])
	await key(KEY_ESCAPE)
	check(overlay.is_open() and overlay.continue_button.is_visible_in_tree() and not overlay.volume_slider.is_visible_in_tree(), "Esc fecha Opções e volta ao menu do Esc")
	check(overlay.options_button.has_focus(), "foco volta ao botão Opções")
	overlay.options_button.pressed.emit()
	await frames()
	overlay.options_back.pressed.emit()
	await frames()
	check(overlay.is_open() and overlay.continue_button.is_visible_in_tree(), "botão Voltar das Opções volta ao menu")

	# Tutorial: texto dos controles, sem mexer no progresso do tutorial.
	overlay.tutorial_button.pressed.emit()
	await frames()
	var help: Label = overlay.find_child("HelpText", true, false)
	check(help.is_visible_in_tree() and help.text.contains("[E]") and help.text.contains("[B]"), "Tutorial abre com os controles")
	await key(KEY_ESCAPE)
	check(overlay.is_open() and overlay.continue_button.is_visible_in_tree(), "Esc fecha o Tutorial e volta ao menu do Esc")
	overlay.tutorial_button.pressed.emit()
	await frames()
	overlay.tutorial_back.pressed.emit()
	await frames()
	check(overlay.continue_button.is_visible_in_tree(), "botão Voltar do Tutorial volta ao menu")
	check(get_meta(TUTORIAL.KEY, -1) == tutorial_before, "progresso do tutorial intocado")

	# Voltar ao menu principal: pede confirmação; Cancelar mantém a partida.
	overlay.main_menu_button.pressed.emit()
	await frames()
	check(overlay.confirm_button.is_visible_in_tree() and overlay.cancel_button.is_visible_in_tree(), "Voltar ao menu pede confirmação")
	check(overlay.save_label.text.contains("salvamento"), "confirmação mostra o estado do último save")
	check(overlay.cancel_button.has_focus(), "foco começa em Cancelar")
	overlay.cancel_button.pressed.emit()
	await frames()
	check(region.is_inside_tree() and overlay.is_open() and paused and overlay.continue_button.is_visible_in_tree(), "Cancelar mantém a partida e volta ao menu")
	await key(KEY_ESCAPE)
	check(not overlay.is_open() and not paused, "Esc no menu principal do Esc retoma o jogo")

	# Esc fecha primeiro um painel aberto; o menu não abre por cima.
	region.crafting_panel.call("open", "maos")
	await frames()
	await key(KEY_ESCAPE)
	check(not region.crafting_panel.visible and not overlay.is_open() and not paused, "Esc fecha o painel sem abrir o menu")

	# Multijogador simulado: não pausa, só trava o jogador local.
	var net := root.get_node_or_null("NetSession")
	var stub := net == null
	if stub:
		net = Node.new()
		net.name = "NetSession"
		var script := GDScript.new()
		script.source_code = "extends Node\nvar mode := \"\"\nfunc leave() -> void:\n\tmode = \"\"\n"
		script.reload()
		net.set_script(script)
		root.add_child(net)
	var old_mode: Variant = net.get("mode")
	net.set("mode", "host")
	var start := player.global_position
	await key(KEY_ESCAPE)
	check(overlay.is_open() and not paused, "MP: menu abre e a árvore NÃO pausa")
	check(overlay.title_label.text == "Menu — a partida continua", "MP: título não diz 'Jogo pausado'")
	check(not player.is_physics_processing() and player.velocity == Vector2.ZERO, "MP: jogador local travado")
	var physics_before := Engine.get_physics_frames()
	Input.action_press("move_right")
	for i in 10: await physics_frame
	Input.action_release("move_right")
	check(Engine.get_physics_frames() >= physics_before + 10, "MP: a simulação continua rodando")
	check(player.global_position.is_equal_approx(start), "MP: jogador local não anda com o menu aberto")
	await key(KEY_B)
	check(not region.crafting_panel.visible, "MP: B não abre a fabricação por cima do menu")
	# Voltar ao menu salva: no MP, só o anfitrião (o convidado não grava nada).
	SAVE.prefix = "user://test_pause_slots_%d_" % Time.get_ticks_usec()
	SAVE.use_slot(2)
	net.set("mode", "client")
	check(not overlay.save_before_leaving() and not FileAccess.file_exists(SAVE.current()), "MP convidado: voltar ao menu não grava")
	net.set("mode", "host")
	overlay.main_menu_button.pressed.emit()
	await frames()
	check(overlay.save_label.text.contains("anfitrião"), "MP: confirmação avisa o anfitrião")
	overlay.cancel_button.pressed.emit()
	await frames()
	await key(KEY_ESCAPE)
	check(not overlay.is_open() and not paused and player.is_physics_processing(), "MP: fechar devolve o controle ao jogador")
	Input.action_press("move_right")
	for i in 10: await physics_frame
	Input.action_release("move_right")
	check(not player.global_position.is_equal_approx(start), "MP: jogador volta a andar depois")
	await key(KEY_B)
	check(region.crafting_panel.visible, "MP: B abre a fabricação sem a árvore pausar")
	check(not paused, "MP: fabricação não pausa a árvore")
	region.crafting_panel.call("close")
	net.set("mode", old_mode)
	if stub: net.queue_free()
	await frames()

	# Solo: confirmar "Voltar ao menu principal" grava o arquivo do espaço atual.
	check(not FileAccess.file_exists(SAVE.current()), "espaço 2 de teste começa sem save")
	await key(KEY_ESCAPE)
	overlay.main_menu_button.pressed.emit()
	await frames()
	check(overlay.save_label.text.contains("salva agora"), "confirmação avisa que vai salvar")
	overlay.confirm_button.pressed.emit()
	await frames()
	var saved := SAVE.read()
	check(FileAccess.file_exists(SAVE.slot_path(2)) and str(saved.get("region", "")) == region.scene_file_path, "voltar ao menu grava o save do espaço 2")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE.slot_path(2) + suffix))
	SAVE.prefix = SAVE.DEFAULT_PREFIX
	SAVE.use_slot(1)

	# Restaura o arquivo de opções do jogador.
	if had_prefs:
		var file := FileAccess.open(PREFS, FileAccess.WRITE)
		file.store_buffer(prefs_backup)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PREFS))
	SFX.reload_settings()
	print("PAUSE_MENU: %d failures" % failures)
	quit(1 if failures else 0)

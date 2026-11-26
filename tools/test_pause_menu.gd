extends SceneTree
## Playtest IDs 61 e 22: menu do Esc (Continuar, Opções, Tutorial, Voltar ao menu principal).
## Solo pausa a árvore; em MP (NetSession.mode != "") só congela o jogador local.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_pause_menu.gd

const TUTORIAL := preload("res://scripts/ui/tutorial_hud.gd")
const SFX := preload("res://scripts/systems/sfx.gd")
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

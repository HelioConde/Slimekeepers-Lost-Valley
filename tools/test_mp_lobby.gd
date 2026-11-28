extends SceneTree
## Playtest IDs 17 e 18 com dois jogos de verdade (rede local ENet; mesmo protocolo da
## Steam). Este processo hospeda e abre um segundo Godot (tools/net/mp_lobby_guest.gd).
## Confere: o anfitrião abre a sala na tela de escolha; o convidado vai para ela; os dois
## veem "Jogador 1/2" acima do protagonista certo; o já escolhido fica bloqueado;
## Voltar sai da sala sem travar e dá para entrar de novo; só começa com os dois prontos;
## cada um tem o próprio tutorial (um não avança nem pula a dica do outro).
## Antes, sem rede: se o anfitrião sai, o convidado volta ao menu com aviso.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_mp_lobby.gd

const PORT := 24697
const RESULT := "user://mp_lobby_guest_result.json"
const HOST_TAB := "user://mp_lobby_host_tab.flag"
const SELECT := "res://scenes/protagonist_select.tscn"
const FOREST := "res://scenes/regions/FlorestaDoDespertarV2.tscn"
const TUT := preload("res://scripts/ui/tutorial_hud.gd")
const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
const SAVE := preload("res://scripts/systems/save_game.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func wait_until(cond: Callable, seconds: float) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		if cond.call(): return true
		await process_frame
	return false


func on_scene(path: String) -> bool:
	return current_scene != null and current_scene.scene_file_path == path


func tag(id: String) -> String:
	var t: Label = current_scene.get("_tags").get(id) if on_scene(SELECT) else null
	return t.text if t else ""


func key(code: int) -> void:
	var down := InputEventKey.new()
	down.keycode = code
	down.physical_keycode = code
	down.pressed = true
	root.push_input(down)
	for i in 3: await process_frame
	var up := down.duplicate()
	up.pressed = false
	root.push_input(up)
	for i in 3: await process_frame


func run() -> void:
	for f in [RESULT, HOST_TAB]: DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	SAVE.prefix = "user://test_mp_lobby_host_slot_"  # nunca os espaços do jogador
	SAVE.use_slot(1)
	var net := root.get_node("NetSession")
	DisplayServer.window_set_size(Vector2i(1280, 720))

	# 0) Convidado na sala e o anfitrião some: volta ao menu com aviso (simulado, sem rede).
	net.mode = "guest"
	net.in_lobby = true
	net.connected = true
	change_scene_to_file(SELECT)
	for i in 20: await process_frame
	check(bool(current_scene.get("_mp")), "convidado na sala: a tela vira sala")
	net._on_peer_gone()
	check(await wait_until(func() -> bool: return on_scene("res://scenes/start_menu.tscn"), 10.0), "anfitrião saiu: convidado volta ao menu")
	for i in 10: await process_frame
	var notice: Node = current_scene.get_node_or_null("Notice") if current_scene else null
	check(notice != null and notice.find_children("*", "Label", true, false).any(func(l: Node) -> bool: return (l as Label).text.contains("fechou a sala")), "menu explica que a sala fechou")
	check(net.mode == "" and not net.in_lobby, "sessão do convidado limpa")

	# 1) Anfitrião abre a sala ao chegar na escolha.
	net.pending_host = "enet"
	net.pending_port = PORT
	change_scene_to_file(SELECT)
	for i in 20: await process_frame
	var sel: Control = current_scene
	check(bool(sel.get("_mp")) and net.mode == "host" and net.in_lobby, "anfitrião abre a sala na tela de escolha")
	sel.call("select", "aren")
	await process_frame
	check(tag("aren") == "Jogador 1 (você)", "Jogador 1 acima do Aren (%s)" % tag("aren"))
	check((sel.get("_confirm") as Button).text == "Pronto", "confirmar vira Pronto")
	sel.call("_on_confirm")
	check(bool(net.local_ready) and (sel.get("_confirm") as Button).text == "Cancelar pronto" and tag("aren").contains("Pronto!"), "Pronto marca e mostra a prontidão")
	sel.call("select", "moni")
	check(sel.get("selected") == "aren", "pronto trava a escolha")
	sel.call("_on_confirm")
	check(not bool(net.local_ready) and on_scene(SELECT), "Cancelar pronto desfaz (sozinho não começa)")

	# 2) Convidado entra, tenta o Aren, fica com a Moni, sai e volta.
	var guest := OS.create_process(OS.get_executable_path(), ["--path", ProjectSettings.globalize_path("res://"),
		"--rendering-driver", "opengl3", "--script", "res://tools/net/mp_lobby_guest.gd", "--", str(PORT)])
	check(guest > 0, "segundo jogo aberto (pid %d)" % guest)
	check(await wait_until(func() -> bool: return bool(net.connected), 60.0), "Jogador 2 entrou na sala")
	check(await wait_until(func() -> bool: return str(net.remote_protagonist) == "moni", 60.0), "Jogador 2 escolhe a Moni")
	check(tag("moni") == "Jogador 2", "anfitrião vê Jogador 2 acima da Moni (%s)" % tag("moni"))
	check(tag("aren") == "Jogador 1 (você)", "e Jogador 1 continua no Aren")
	if OS.has_environment("SK_MP_SHOTS"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("SK_MP_SHOTS") + "/lobby_anfitriao_sala.png")
	check(await wait_until(func() -> bool: return not bool(net.connected), 60.0), "Jogador 2 volta ao menu (sai da sala)")
	for i in 5: await process_frame
	check(on_scene(SELECT) and tag("moni") == "" and str(net.remote_protagonist) == "" and net.in_lobby, "anfitrião segue na sala, vaga livre")
	check(await wait_until(func() -> bool: return bool(net.connected) and str(net.remote_protagonist) == "moni", 60.0), "Jogador 2 entra de novo e escolhe a Moni")

	# 3) Só começa com os dois prontos.
	sel.call("_on_confirm")
	var early := false
	var ok := await wait_until(func() -> bool:
		if not bool(net.remote_ready) and not on_scene(SELECT): early = true
		return bool(net.remote_ready) or early, 60.0)
	check(ok and not early, "não começa enquanto o Jogador 2 não está pronto")
	check(await wait_until(func() -> bool: return on_scene(FOREST) and current_scene.get("player") != null, 60.0), "os dois prontos: o anfitrião carrega o mapa")
	check(PROTAGONIST.current(self) == "aren" and str(net.remote_protagonist) == "moni" and not net.in_lobby, "anfitrião joga com Aren; o outro é a Moni")
	var scene := current_scene
	check(await wait_until(func() -> bool:
		var r := scene.find_child("RemotePlayer", true, false)
		return r != null and (r as Node2D).visible and str(r.get("protagonist_override")) == "moni", 60.0), "Moni do convidado aparece no mapa do anfitrião")

	# 4) Tutorial do anfitrião (começa quando termina o despertar), independente do convidado.
	check(await wait_until(func() -> bool: return TUT.active(self), 60.0), "tutorial do anfitrião começa após o despertar")
	for i in 5: await process_frame
	var hud: Control = scene.get_node("HUD/Interface/TutorialHud")
	check(hud.visible and hud.step() == 0, "anfitrião vê a primeira dica (passo %d), o andar do convidado não conta" % hud.step())
	if OS.has_environment("SK_MP_SHOTS"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("SK_MP_SHOTS") + "/lobby_anfitriao_tutorial.png")
	await key(KEY_TAB)
	await key(KEY_TAB)
	check(hud.step() == 2, "[Tab] pula só as dicas do anfitrião (passo %d)" % hud.step())
	FileAccess.open(HOST_TAB, FileAccess.WRITE).store_string("2")
	set_meta(TUT.KEY, 5)  # planta da bancada: objetivo da dupla, a dica diz isso
	hud._show()
	await process_frame
	var said := " ".join(hud._body.get_children().filter(func(n: Node) -> bool: return n is Label and not n.is_queued_for_deletion()).map(func(l: Label) -> String: return l.text))
	check(said.contains("dupla"), "dica da bancada avisa que é da dupla")
	check(await wait_until(func() -> bool: return FileAccess.file_exists(RESULT), 90.0), "convidado terminou a verificação")
	if FileAccess.file_exists(RESULT):
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RESULT))
		for line: String in data.get("checks", []): print("  convidado " + line)
		check(int(data.get("failures", 1)) == 0, "verificações do convidado passaram")
	net.leave()
	OS.kill(guest)
	print("MP_LOBBY: %d failures" % failures)
	quit(1 if failures else 0)

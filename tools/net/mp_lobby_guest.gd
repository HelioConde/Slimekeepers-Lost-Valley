extends SceneTree
## Convidado do tools/test_mp_lobby.gd: entra na sala, confere a tela de escolha,
## sai e volta, fica pronto e confere o próprio tutorial. Grava em
## user://mp_lobby_guest_result.json.

const RESULT := "user://mp_lobby_guest_result.json"
const HOST_TAB := "user://mp_lobby_host_tab.flag"
const SELECT := "res://scenes/protagonist_select.tscn"
const FOREST := "res://scenes/regions/FlorestaDoDespertarV2.tscn"
const TUT := preload("res://scripts/ui/tutorial_hud.gd")
const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
const SAVE := preload("res://scripts/systems/save_game.gd")
var checks: Array[String] = []
var failures := 0
var net: Node
var port := 24697


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	checks.append(("PASS: " if ok else "FAIL: ") + what)
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


## Entra na sala (tenta de novo enquanto o anfitrião ainda não liberou a vaga).
func enter_lobby() -> bool:
	for attempt in 4:
		net.join_enet("127.0.0.1", port)
		if await wait_until(func() -> bool: return on_scene(SELECT) and bool(current_scene.get("_mp")), 20.0): return true
	return false


func finish() -> void:
	var file := FileAccess.open(RESULT, FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "checks": checks}))
	file.close()
	for i in 60: await process_frame
	quit()


func run() -> void:
	DisplayServer.window_set_position(Vector2i(40, 40))
	if OS.get_cmdline_user_args().size() > 0: port = int(OS.get_cmdline_user_args()[0])
	SAVE.prefix = "user://test_mp_lobby_guest_slot_"
	SAVE.use_slot(1)
	net = root.get_node("NetSession")
	check(await enter_lobby(), "entra na sala e vai para a tela de escolha")
	if not on_scene(SELECT):
		await finish()
		return
	var sel: Control = current_scene
	check(net.in_lobby and str(net.remote_protagonist) == "aren", "vê a escolha do anfitrião (%s)" % net.remote_protagonist)
	check(tag("aren") == "Jogador 1", "Jogador 1 acima do Aren (%s)" % tag("aren"))
	sel.call("select", "aren")
	check(str(sel.get("selected")) == "", "Aren do Jogador 1 fica bloqueado")
	sel.call("select", "moni")
	check(tag("moni") == "Jogador 2 (você)", "Jogador 2 acima da Moni (%s)" % tag("moni"))
	for i in 90: await process_frame  # o anfitrião confere antes de sair
	sel.call("_on_back")
	check(await wait_until(func() -> bool: return on_scene("res://scenes/start_menu.tscn"), 10.0) and net.mode == "", "Voltar sai da sala para o menu")
	await create_timer(1.0).timeout
	check(await enter_lobby(), "entra de novo na sala")
	sel = current_scene
	sel.call("select", "moni")
	check(await wait_until(func() -> bool: return bool(net.remote_ready), 60.0), "vê o Jogador 1 pronto")
	check(tag("aren").contains("Pronto!"), "prontidão do Jogador 1 aparece (%s)" % tag("aren").replace("\n", " "))
	if OS.has_environment("SK_MP_SHOTS"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("SK_MP_SHOTS") + "/lobby_convidado_sala.png")
	await create_timer(1.5).timeout
	check(on_scene(SELECT), "não começa sem o Jogador 2 pronto")
	sel.call("_on_confirm")
	check(await wait_until(func() -> bool: return on_scene(FOREST) and current_scene.get("player") != null, 60.0), "os dois prontos: entra no mapa")
	if not on_scene(FOREST):
		await finish()
		return
	for i in 20: await process_frame
	var scene := current_scene
	check(PROTAGONIST.current(self) == "moni" and str(net.local_protagonist) == "moni" and str(net.remote_protagonist) == "aren", "joga com Moni; o outro é o Aren")
	check(not PROTAGONIST.intro_pending(self), "convidado não repete o despertar")
	var hud: Control = scene.get_node("HUD/Interface/TutorialHud")
	check(await wait_until(func() -> bool: return TUT.active(self) and hud.visible, 10.0) and hud.step() == 0, "convidado vê o tutorial desde o começo")
	if OS.has_environment("SK_MP_SHOTS"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("SK_MP_SHOTS") + "/lobby_convidado_tutorial.png")
	Input.action_press("move_right")
	var walked := await wait_until(func() -> bool: return hud.step() >= 1, 15.0)
	Input.action_release("move_right")
	check(walked and hud.step() == 1, "andar passa a dica do convidado (passo %d)" % hud.step())
	check(await wait_until(func() -> bool: return FileAccess.file_exists(HOST_TAB), 90.0), "anfitrião pulou as dicas dele")
	for i in 30: await process_frame
	check(hud.step() == 1 and hud.visible, "pulo do anfitrião não mexe no tutorial do convidado (passo %d)" % hud.step())
	await finish()

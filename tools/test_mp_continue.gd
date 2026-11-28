extends SceneTree
## Continuar em dupla (pedido do usuário, 2026-11-27): o anfitrião abre a sala com o jogo
## em andamento; o amigo entra com o outro protagonista e a bolsa guardada no save; ao
## sair, a bolsa nova volta para o save do anfitrião.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_mp_continue.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const PORT := 24731
const RESULT := "user://mp_continue_guest_result.json"
var failures := 0


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func wait_until(cond: Callable, seconds: float) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		if cond.call(): return true
		await process_frame
	return false


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RESULT))
	var net := root.get_node("NetSession")
	var NET: Node = net  # funções estáticas pelo nó (preload no script quebraria sem GameClock)
	preload("res://scripts/systems/protagonist.gd").choose(self, "aren")
	preload("res://scripts/systems/protagonist.gd").finish_intro(self)
	set_meta("tutorial_step", 99)
	# Bolsa da Moni guardada de uma vez anterior: 3 pedras polidas.
	var mine: Dictionary = NET.bag_snapshot(self)
	for key in NET.BAG_KEYS: if has_meta(key): remove_meta(key)
	BAG.add_item(self, "pedra_polida", 3)
	NET.store_guest_bag(self, "moni", NET.bag_snapshot(self))
	for key in NET.BAG_KEYS: if has_meta(key): remove_meta(key)
	NET.apply_bag(self, mine)
	change_scene_to_file("res://scenes/regions/FlorestaDoDespertarV2.tscn")
	for i in 40: await process_frame
	net.pending_port = PORT
	check(net.call("open_in_world", "enet", "aren").is_empty() and not net.in_lobby, "sala abre com o jogo em andamento (sem tela de escolha)")
	var guest := OS.create_process(OS.get_executable_path(), ["--path", ProjectSettings.globalize_path("res://"),
		"--rendering-driver", "opengl3", "--script", "res://tools/net/mp_continue_guest.gd", "--", str(PORT)])
	check(guest > 0, "segundo jogo aberto")
	check(await wait_until(func() -> bool: return bool(net.connected), 60.0), "o amigo entrou")
	check(str(net.remote_protagonist) == "moni", "o amigo joga com o outro protagonista (%s)" % net.remote_protagonist)
	check(await wait_until(func() -> bool: return FileAccess.file_exists(RESULT), 90.0), "o amigo terminou a verificação")
	check(await wait_until(func() -> bool: return str(NET.guest_bag(self, "moni")).contains("graveto"), 15.0), "a bolsa nova do amigo ficou no save do anfitrião")
	if FileAccess.file_exists(RESULT):
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RESULT))
		for line in data.get("checks", []): print("  amigo: ", line)
		check(int(data.get("failures", 1)) == 0, "verificações do amigo passaram")
	net.leave()
	if OS.is_process_running(guest): OS.kill(guest)
	print("MP_CONTINUE: %d failures" % failures)
	quit(1 if failures else 0)

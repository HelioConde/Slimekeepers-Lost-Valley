extends SceneTree
## Multijogador de verdade com dois jogos (rede local ENet; o protocolo é o mesmo da
## Steam): este processo hospeda com Aren e abre um segundo Godot que entra.
## Confere: quem entra fica com Moni, cai no mapa do anfitrião, cada um vê o outro
## protagonista e os movimentos chegam dos dois lados.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_multiplayer_lan.gd

const PORT := 24690
const RESULT := "user://mp_guest_result.json"
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


func run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RESULT))
	var net := root.get_node("NetSession")
	var protagonist := preload("res://scripts/systems/protagonist.gd")
	root.get_node("GameClock").reset_new_game()
	preload("res://scripts/systems/session_state.gd").clear_session(self)
	protagonist.choose(self, "aren")
	protagonist.finish_intro(self)
	check(net.host_enet("aren", PORT).is_empty(), "anfitrião abre a sala na rede local")
	change_scene_to_file("res://scenes/regions/FlorestaDoDespertarV2.tscn")
	for i in 40: await process_frame
	var guest := OS.create_process(OS.get_executable_path(), ["--path", ProjectSettings.globalize_path("res://"),
		"--rendering-driver", "opengl3", "--script", "res://tools/net/mp_guest.gd", "--", str(PORT)])
	check(guest > 0, "segundo jogo aberto (pid %d)" % guest)
	check(await wait_until(func() -> bool: return bool(net.connected), 60.0), "o outro jogador entrou")
	check(str(net.remote_protagonist) == "moni", "quem entra joga com Moni (%s)" % net.remote_protagonist)
	var scene := current_scene
	check(await wait_until(func() -> bool:
		var r := scene.find_child("RemotePlayer", true, false)
		return r != null and (r as Node2D).visible, 60.0), "Moni aparece no mapa do anfitrião")
	var remote: Node2D = scene.find_child("RemotePlayer", true, false)
	if OS.has_environment("SK_MP_SHOTS"):  # prova visual: as duas janelas desenham o jogo
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("SK_MP_SHOTS") + "/anfitriao_aren.png")
	if remote != null:
		check(str(remote.get("protagonist_override")) == "moni", "boneco do outro jogador usa a arte da Moni")
		var before := remote.global_position
		check(await wait_until(func() -> bool: return remote.global_position.distance_to(before) > 60.0, 30.0),
			"movimento da Moni chega ao anfitrião (%s -> %s)" % [before, remote.global_position])
	# Mundo compartilhado: o anfitrião ara uma cova; o convidado ara outra (net_world.gd).
	preload("res://scripts/systems/farm_state.gd").till(self, Vector2i(1, 1), "floresta")
	# O anfitrião anda; o convidado confere e grava o resultado.
	var player: Node2D = scene.get("player")
	var start := Time.get_ticks_msec()
	var step := 0
	while not FileAccess.file_exists(RESULT) and Time.get_ticks_msec() - start < 60000:
		step += 1
		player.global_position += Vector2(4 if (step / 40) % 2 == 0 else -4, 0)  # vai e volta
		await create_timer(0.03).timeout
	check(FileAccess.file_exists(RESULT), "convidado terminou a verificação")
	check(await wait_until(func() -> bool: return preload("res://scripts/systems/farm_state.gd").is_tilled(self, Vector2i(2, 1), "floresta"), 10.0), "cova arada pelo convidado aparece no anfitrião")
	if FileAccess.file_exists(RESULT):
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RESULT))
		for line: String in data.get("checks", []): print("  convidado " + line)
		check(int(data.get("failures", 1)) == 0, "verificações do convidado passaram")
	net.leave()
	OS.kill(guest)
	print("MULTIPLAYER_LAN: %d failures" % failures)
	quit(1 if failures else 0)

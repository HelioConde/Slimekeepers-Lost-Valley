extends SceneTree
## Convidado do tools/test_multiplayer_lan.gd: entra pela rede local, confere o que vê
## e grava o resultado em user://mp_guest_result.json.

const RESULT := "user://mp_guest_result.json"
var checks: Array[String] = []
var failures := 0


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


func run() -> void:
	DisplayServer.window_set_position(Vector2i(40, 40))
	var port := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 24690
	var net := root.get_node("NetSession")
	check(net.join_enet("127.0.0.1", port).is_empty(), "conecta ao anfitrião")
	check(await wait_until(func() -> bool: return bool(net.connected), 30.0), "recebe as boas-vindas")
	check(str(net.local_protagonist) == "moni", "joga com Moni (%s)" % net.local_protagonist)
	check(await wait_until(func() -> bool:
		return current_scene != null and current_scene.scene_file_path.ends_with("FlorestaDoDespertarV2.tscn") and current_scene.get("player") != null, 60.0),
		"entra no mapa do anfitrião")
	for i in 30: await process_frame
	var scene := current_scene
	var protagonist := preload("res://scripts/systems/protagonist.gd")
	check(protagonist.current(self) == "moni", "protagonista local é a Moni")
	check(await wait_until(func() -> bool:
		var r := scene.find_child("RemotePlayer", true, false)
		return r != null and (r as Node2D).visible, 30.0), "vê o Aren do anfitrião")
	var remote: Node2D = scene.find_child("RemotePlayer", true, false)
	if OS.has_environment("SK_MP_SHOTS"):  # prova visual: as duas janelas desenham o jogo
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("SK_MP_SHOTS") + "/convidado_moni.png")
	if remote != null:
		check(str(remote.get("protagonist_override")) == "aren", "boneco do anfitrião usa a arte do Aren")
	# Anda para o anfitrião ver.
	var player: Node2D = scene.get("player")
	for i in 30:
		player.global_position += Vector2(0, 4)
		await create_timer(0.05).timeout
	if remote != null:
		var before := remote.global_position
		check(await wait_until(func() -> bool: return remote.global_position.distance_to(before) > 30.0, 30.0),
			"movimento do Aren chega ao convidado")
	var FARM := preload("res://scripts/systems/farm_state.gd")
	check(await wait_until(func() -> bool: return FARM.is_tilled(self, Vector2i(1, 1), "floresta"), 20.0), "cova arada pelo anfitrião aparece no convidado")
	FARM.till(self, Vector2i(2, 1), "floresta")
	for i in 90: await process_frame  # dá tempo de enviar (verificação a cada 0,5 s)
	var file := FileAccess.open(RESULT, FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "checks": checks}))
	file.close()
	for i in 60: await process_frame
	quit()

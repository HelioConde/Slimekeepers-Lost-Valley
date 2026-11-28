extends SceneTree
## Teste rápido da Steam num PC só (precisa do cliente Steam aberto e logado):
## inicia o GodotSteam (App 480), cria uma sala só de amigos e sai. Não testa o
## segundo jogador; isso pede outro PC com outra conta (docs/gameplay/MULTIJOGADOR.md).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_steam_smoke.gd

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var net := root.get_node("NetSession")
	var problem: String = net.host_steam("aren")
	check(problem.is_empty(), "Steam iniciou e pediu a sala (%s)" % problem)
	if problem.is_empty():
		var start := Time.get_ticks_msec()
		while int(net.lobby_id) == 0 and Time.get_ticks_msec() - start < 20000:
			await process_frame
		check(int(net.lobby_id) != 0, "sala criada na Steam (status: %s)" % net.status)
	net.leave()
	for i in 10: await process_frame
	print("STEAM_SMOKE: %d failures" % failures)
	quit(1 if failures else 0)

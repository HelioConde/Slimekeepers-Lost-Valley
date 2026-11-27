extends SceneTree
## Playtest ID 12: hospedar de novo ou trocar de modo não pode travar. Uma sessão nova
## fecha a anterior (porta liberada, sala antiga fechada).
## Uso: godot --path . --headless --script res://tools/test_net_restart.gd

const PORT := 24711
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var net: Node = root.get_node("NetSession")
	check(net.host_enet("aren", PORT) == "", "hospeda na rede local")
	check(net.host_enet("aren", PORT) == "", "hospedar de novo na mesma porta funciona")
	check(net.mode == "host" and net.transport == "enet", "segue como anfitrião")
	check(net.join_enet("127.0.0.1", PORT) == "", "trocar para entrar numa sala não trava")
	check(net.mode == "guest", "agora é convidado (a sala anterior fechou)")
	check(net.host_enet("moni", PORT) == "", "voltar a hospedar depois de entrar funciona")
	net.leave()
	check(net.mode == "" and net.transport == "", "sair limpa a sessão")
	print("NET_RESTART: %d failures" % failures)
	quit(1 if failures else 0)

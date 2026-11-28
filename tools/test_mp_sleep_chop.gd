extends SceneTree
## Multijogador com dois jogos de verdade (ENet local; mesmo protocolo da Steam):
##  36) o golpe de um jogador balança e derruba a árvore também na tela do outro
##      (anfitrião corta uma, convidado corta outra);
##  35) dormir: o anfitrião deita e espera "(1/2)" sem virar o dia; quando o convidado
##      deita, os dois acordam às 06:00 do dia seguinte com energia cheia.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_mp_sleep_chop.gd

const PORT := 24694
const ENERGY := preload("res://scripts/systems/energy_state.gd")
var failures := 0
var inbox: Array[Dictionary] = []
var fx: Array[Dictionary] = []


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


func msg(step: String, seconds: float = 60.0) -> Dictionary:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		for d in inbox:
			if str(d.get("s", "")) == step:
				inbox.erase(d)
				return d
		await process_frame
	return {}


## Duas árvores cortáveis visíveis e inteiras.
func pick_trees(chop: Node) -> Array:
	var out: Array = []
	var chopped: Dictionary = chop.state(self)
	for key: String in chop.trees:
		var tree: Node2D = chop.trees[key]
		if chopped.has(key) or not tree.is_visible_in_tree() or not (tree.get_node("Sprite") as CanvasItem).visible: continue
		out.append(key)
		if out.size() == 2: break
	return out


func run() -> void:
	var net := root.get_node("NetSession")
	net.message.connect(func(d: Dictionary) -> void:
		if str(d.get("t", "")) == "tst": inbox.append(d)
		if str(d.get("t", "")) == "chop_fx": fx.append(d))
	var clock := root.get_node("GameClock")
	clock.reset_new_game()
	preload("res://scripts/systems/session_state.gd").clear_session(self)
	var protagonist := preload("res://scripts/systems/protagonist.gd")
	protagonist.choose(self, "aren")
	protagonist.finish_intro(self)
	check(net.host_enet("aren", PORT).is_empty(), "anfitrião abre a sala")
	change_scene_to_file("res://scenes/regions/FlorestaDoDespertarV2.tscn")
	for i in 40: await process_frame
	var guest := OS.create_process(OS.get_executable_path(), ["--path", ProjectSettings.globalize_path("res://"),
		"--rendering-driver", "opengl3", "--script", "res://tools/net/mp_sleep_chop_guest.gd", "--", str(PORT)])
	check(guest > 0, "segundo jogo aberto (pid %d)" % guest)
	check(await wait_until(func() -> bool: return bool(net.connected), 60.0), "o convidado entrou")
	var scene := current_scene
	var chop: Node = scene.get("choppable")
	var keys := pick_trees(chop)
	check(keys.size() == 2, "duas árvores para cortar")
	if keys.size() < 2:
		finish(net)
		return
	net.send({"t": "tst", "s": "trees", "mine": keys[0], "yours": keys[1]})
	check(not (await msg("ready", 90.0)).is_empty(), "convidado pronto no mesmo mapa")
	# 36) Anfitrião corta: o convidado confere a queda na tela dele.
	var tree: Node2D = chop.trees[keys[0]]
	var hits: int = chop.fell_hits(keys[0])
	for i in hits:
		chop.strike({"key": keys[0], "kind": "tree"}, clock.day_number, 1, tree.global_position + Vector2.LEFT * 30)
		await create_timer(0.2).timeout
	var seen := await msg("host_fell", 20.0)
	check(int(seen.get("fx", 0)) == hits, "convidado recebeu %d de %d golpes do anfitrião" % [int(seen.get("fx", 0)), hits])
	check(bool(seen.get("fell", false)), "a árvore do anfitrião caiu na tela do convidado")
	# Convidado corta: o anfitrião vê o balanço e a queda.
	var other: Node2D = chop.trees[keys[1]]
	var falling := [false]
	other.get_parent().child_entered_tree.connect(func(n: Node) -> void:
		if str(n.name).begins_with("Falling"): falling[0] = true)
	fx.clear()
	net.send({"t": "tst", "s": "chop"})
	var done := await msg("guest_fell", 30.0)
	var expected := int(done.get("hits", 99))
	check(await wait_until(func() -> bool: return fx.size() >= expected, 5.0), "anfitrião recebeu os golpes do convidado (%d de %d)" % [fx.size(), expected])
	check(falling[0], "a árvore do convidado caiu (animação) na tela do anfitrião")
	check(not (other.get_node("Sprite") as CanvasItem).visible, "a copa sumiu no anfitrião")
	check(fx.size() > 0 and int(fx.back().get("side", 0)) == 1, "cai para o lado do corte (direita)")
	# 35) Dormir junto.
	clock.set_time(22, 0)
	ENERGY.restore(self, -ENERGY.MAX)  # cansado
	var day: int = clock.day_number
	await create_timer(0.3).timeout
	scene.sleep_until_morning()
	var sleep_net: Node = scene.get_node("NetSleep")
	check(bool(sleep_net.sleeping), "anfitrião deitou")
	var label := scene.find_child("SleepWaiting", true, false) as Label
	check(label != null and label.visible and label.text.begins_with("Esperando os outros (1/2)"), "mostra Esperando os outros (1/2)")
	await create_timer(1.0).timeout
	check(int(clock.day_number) == day, "sozinho na cama o dia não vira")
	net.send({"t": "tst", "s": "sleep", "day": day})
	check(await wait_until(func() -> bool: return int(clock.day_number) == day + 1 and not bool(sleep_net.sleeping), 15.0), "os dois deitados: o dia vira no anfitrião")
	check(clock.get_hour() == 6, "anfitrião acorda às 06:00 (%02d:%02d)" % [clock.get_hour(), clock.get_minute()])
	check(ENERGY.current(self) == ENERGY.MAX, "anfitrião acorda com energia cheia")
	var woke := await msg("woke", 20.0)
	check(int(woke.get("day", 0)) == day + 1 and int(woke.get("hour", 0)) == 6, "convidado acorda no mesmo dia e hora (%s)" % str(woke.get("day", "?")))
	check(bool(woke.get("full", false)), "convidado acorda com energia cheia")
	for line in woke.get("checks", []): print("  convidado: ", line)
	failures += int(woke.get("failures", 0))
	finish(net)


func finish(net: Node) -> void:
	net.leave()
	print("RESULT: %s (%d falhas)" % ["OK" if failures == 0 else "FALHOU", failures])
	quit(1 if failures > 0 else 0)

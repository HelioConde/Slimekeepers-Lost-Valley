extends SceneTree
## Itens no chão no multijogador (playtest IDs 20 e 21), com dois jogos de verdade
## (rede local ENet; mesmo protocolo da Steam). Este processo hospeda (Aren) e abre o
## convidado (tools/net/mp_drops_guest.gd, Moni). Passos combinados por mensagens "tst":
##  A) convidado coleta: o anfitrião vê o mesmo drop no mesmo ponto; o convidado pega e
##     o item some no anfitrião (sem ir para a bolsa dele);
##  B) os dois correm para o mesmo drop: só um recebe, sem duplicar;
##  C) convidado solta 3 de 5 fibras: fica com 2, não puxa de volta, o anfitrião pega 3;
##  D) anfitrião solta o machado (ferramenta): o convidado pega.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_mp_drops.gd

const PORT := 24692
const BAG := preload("res://scripts/systems/forest_bag.gd")
var failures := 0
var inbox: Array[Dictionary] = []


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


## Espera a mensagem de teste `step` do convidado ({} se não chegar).
func msg(step: String, seconds: float = 60.0) -> Dictionary:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		for d in inbox:
			if str(d.get("s", "")) == step:
				inbox.erase(d)
				return d
		await process_frame
	return {}


func find_drop(drops: Node, id: String) -> Dictionary:
	for e: Dictionary in drops.get("drops"):
		if str(e.id) == id: return e
	return {}


func count(item: String) -> int:
	return BAG.count_item(self, item)


func run() -> void:
	var net := root.get_node("NetSession")
	net.message.connect(func(d: Dictionary) -> void: if str(d.get("t", "")) == "tst": inbox.append(d))
	root.get_node("GameClock").reset_new_game()
	preload("res://scripts/systems/session_state.gd").clear_session(self)
	var protagonist := preload("res://scripts/systems/protagonist.gd")
	protagonist.choose(self, "aren")
	protagonist.finish_intro(self)
	check(net.host_enet("aren", PORT).is_empty(), "anfitrião abre a sala")
	change_scene_to_file("res://scenes/regions/FlorestaDoDespertarV2.tscn")
	for i in 40: await process_frame
	var guest := OS.create_process(OS.get_executable_path(), ["--path", ProjectSettings.globalize_path("res://"),
		"--rendering-driver", "opengl3", "--script", "res://tools/net/mp_drops_guest.gd", "--", str(PORT)])
	check(guest > 0, "segundo jogo aberto (pid %d)" % guest)
	check(await wait_until(func() -> bool: return bool(net.connected), 60.0), "o convidado entrou")
	var scene := current_scene
	check(await wait_until(func() -> bool:
		var r := scene.find_child("RemotePlayer", true, false)
		return r != null and (r as Node2D).visible, 60.0), "Moni aparece no mapa do anfitrião")
	var drops: Node2D = scene.get("item_drops")
	var player: Node2D = scene.get("player")
	var base := player.global_position
	net.send({"t": "tst", "s": "base", "x": base.x, "y": base.y})
	check(not (await msg("ready")).is_empty(), "convidado pronto no mesmo mapa")
	player.global_position = base + Vector2(-300, 0)  # longe dos drops do convidado
	# A) Convidado coleta (forage.drop -> item_drops.spawn).
	var sticks := count("graveto")
	net.send({"t": "tst", "s": "A"})
	var a := await msg("A_landed", 30.0)
	var entry := find_drop(drops, str(a.get("id", "?")))
	check(not entry.is_empty(), "drop do convidado aparece no anfitrião (id %s)" % a.get("id", "?"))
	if not entry.is_empty():
		await wait_until(func() -> bool: return bool(entry.ready), 5.0)
		var at := (entry.node as Node2D).global_position
		var there := Vector2(float(a.get("x", 0.0)), float(a.get("y", 0.0)))
		check(at.distance_to(there) < 2.0, "mesmo ponto nas duas telas (%s x %s)" % [at, there])
	net.send({"t": "tst", "s": "A_take"})
	check(await wait_until(func() -> bool: return find_drop(drops, str(a.get("id", "?"))).is_empty(), 15.0),
		"o drop some no anfitrião quando o convidado pega")
	check(bool((await msg("A_done", 20.0)).get("ok", false)), "o graveto entrou na bolsa do convidado")
	check(count("graveto") == sticks, "a bolsa do anfitrião não ganhou o graveto")
	# B) Disputa pelo mesmo drop (2 rodadas: o anfitrião sai junto e sai atrasado).
	for delay in [0.0, 0.25]:
		player.global_position = base + Vector2(-300, 0)
		var stones := count("pedra_pequena")
		drops.spawn("pedra_pequena", 3, base + Vector2(0, 220))
		var stone: Dictionary = drops.drops.back()
		check(not (await msg("B_seen", 15.0)).is_empty(), "convidado vê a pedra do anfitrião")
		await wait_until(func() -> bool: return bool(stone.ready), 5.0)
		var landed := (stone.node as Node2D).global_position
		net.send({"t": "tst", "s": "B_go", "x": landed.x, "y": landed.y})
		if delay > 0.0: await create_timer(delay).timeout
		player.global_position = landed + Vector2(-12, 14)
		check(await wait_until(func() -> bool: return drops.pending() == 0, 10.0), "a pedra disputada saiu do chão do anfitrião")
		var b := await msg("B_done", 20.0)
		await create_timer(0.3).timeout
		var host_got := count("pedra_pequena") - stones
		var guest_got := int(b.get("n", -1))
		check(host_got + guest_got == 3 and (host_got == 0 or guest_got == 0),
			"atraso %.2f s: só um recebeu as 3 pedras (anfitrião %d, convidado %d)" % [delay, host_got, guest_got])
		check(int(b.get("left", -1)) == 0, "nada sobrou no chão do convidado (%d)" % int(b.get("left", -1)))
		player.global_position = base + Vector2(-300, 0)
		for i in 10: await process_frame
	# C) Convidado solta 3 fibras; o anfitrião pega.
	player.global_position = base + Vector2(-300, 0)
	var fibers := count("fibra")
	net.send({"t": "tst", "s": "C"})
	var c := await msg("C_dropped", 20.0)
	var fiber := find_drop(drops, str(c.get("id", "?")))
	check(not fiber.is_empty() and int(fiber.get("amount", 0)) == 3, "anfitrião vê as 3 fibras soltas pelo convidado")
	if not fiber.is_empty():
		player.global_position = (fiber.node as Node2D).global_position + Vector2(0, 14)
	check(await wait_until(func() -> bool: return count("fibra") == fibers + 3, 10.0), "anfitrião pegou as 3 fibras (%d)" % (count("fibra") - fibers))
	net.send({"t": "tst", "s": "C_check"})
	check(bool((await msg("C_done", 20.0)).get("ok", false)), "convidado ficou com 2 fibras e o drop sumiu na tela dele")
	# D) Anfitrião solta uma ferramenta; o convidado pega.
	BAG.add_item(self, "machado", 1)
	check(drops.drop_from_bag("machado", 1) and count("machado") == 0, "anfitrião solta o machado")
	var axe: Dictionary = drops.drops.back()
	await wait_until(func() -> bool: return bool(axe.ready), 5.0)
	await create_timer(0.6).timeout
	check(count("machado") == 0 and drops.pending() == 1, "quem soltou não puxa o machado de volta")
	var axe_at := (axe.node as Node2D).global_position
	net.send({"t": "tst", "s": "D", "x": axe_at.x, "y": axe_at.y})
	check(bool((await msg("D_done", 20.0)).get("ok", false)), "o convidado pegou o machado")
	check(await wait_until(func() -> bool: return drops.pending() == 0, 5.0) and count("machado") == 0,
		"machado sumiu do chão do anfitrião e não voltou para a bolsa dele")
	net.send({"t": "tst", "s": "end"})
	var result := await msg("result", 20.0)
	for line in result.get("checks", []): print("  convidado " + str(line))
	check(not result.is_empty() and int(result.get("failures", 1)) == 0, "verificações do convidado passaram")
	net.leave()
	OS.kill(guest)
	print("MP_DROPS: %d failures" % failures)
	quit(1 if failures else 0)

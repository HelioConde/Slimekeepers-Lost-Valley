extends SceneTree
## Obra em etapas no multijogador (playtest IDs 23, 24 e 40) com dois jogos de verdade
## (rede local ENet; mesmo protocolo da Steam). Este processo hospeda (Aren) e abre o
## convidado (tools/net/mp_build_guest.gd, Moni). Passos combinados por mensagens "tst":
##  A) anfitrião coloca a planta sem custo; o convidado a vê e deposita 3 gravetos (sai da
##     bolsa dele, entra na obra do anfitrião); sem material completo não há progresso;
##     o anfitrião completa; os dois constroem juntos (ninguém tem a obra cancelada);
##  B) mesma bancada só com o anfitrião: a dupla terminou mais rápido;
##  C) os dois constroem o baú; o convidado se afasta e o anfitrião continua até concluir;
##  D) o convidado deposita e cancela: o material volta para ele, a planta some nos dois;
##  E) prévia do convidado aparece para o anfitrião e some quando ele desiste (ID 23).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_mp_build.gd

const PORT := 24694
const BAG := preload("res://scripts/systems/forest_bag.gd")
const BUILD := preload("res://scripts/systems/build_site.gd")
var failures := 0
var inbox: Array[Dictionary] = []
var net: Node


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


func say(step: String, extra: Dictionary = {}) -> void:
	var data := {"t": "tst", "s": step}
	data.merge(extra)
	net.send(data)


func press() -> void:
	for pressed in [true, false]:
		var e := InputEventAction.new()
		e.action = "interact"
		e.pressed = pressed
		Input.parse_input_event(e)
		await process_frame
		await process_frame


func site(id: String) -> Dictionary:
	return BUILD.find(self, id)


## Chão livre perto de `from` para uma planta.
func free_spot(placer: Node2D, from: Vector2) -> Vector2:
	for i in 40:
		var at := (from + Vector2(70 * (i % 5) - 140, 70 * (i / 5))).round()
		if placer.can_place(at): return at
	return from


## Coloca a planta pelo caminho do jogo e devolve o id.
func place(placer: Node2D, at: Vector2, kind: String, paid: bool) -> String:
	placer.call("_place", at, kind, paid)
	return BUILD.station_id({"region": placer.region_id, "x": at.x, "y": at.y})


func run() -> void:
	net = root.get_node("NetSession")
	net.message.connect(func(d: Dictionary) -> void: if str(d.get("t", "")) == "tst": inbox.append(d))
	root.get_node("GameClock").reset_new_game()
	preload("res://scripts/systems/session_state.gd").clear_session(self)
	var protagonist := preload("res://scripts/systems/protagonist.gd")
	protagonist.choose(self, "aren")
	protagonist.finish_intro(self)
	set_meta("tutorial_step", 99)
	check(net.host_enet("aren", PORT).is_empty(), "anfitrião abre a sala")
	change_scene_to_file("res://scenes/regions/FlorestaDoDespertarV2.tscn")
	for i in 40: await process_frame
	var guest := OS.create_process(OS.get_executable_path(), ["--path", ProjectSettings.globalize_path("res://"),
		"--rendering-driver", "opengl3", "--script", "res://tools/net/mp_build_guest.gd", "--", str(PORT)])
	check(guest > 0, "segundo jogo aberto (pid %d)" % guest)
	check(await wait_until(func() -> bool: return bool(net.connected), 60.0), "o convidado entrou")
	var scene := current_scene
	check(await wait_until(func() -> bool:
		var r := scene.find_child("RemotePlayer", true, false)
		return r != null and (r as Node2D).visible, 60.0), "Moni aparece no mapa do anfitrião")
	var player: Node2D = scene.get("player")
	var placer: Node2D = scene.get("placer")
	Input.warp_mouse(Vector2.ZERO)
	var base := player.global_position
	say("base", {"x": base.x, "y": base.y})
	check(not (await msg("ready")).is_empty(), "convidado pronto no mesmo mapa")

	# A) Planta sem custo, depósito do convidado, dupla.
	var at := free_spot(placer, base + Vector2(0, 140))
	var a := place(placer, at, "bancada", false)
	check(BUILD.stage(site(a)) == "plan" and BAG.count_item(self, "graveto") == 0, "anfitrião colocou a planta sem custo")
	say("A", {"id": a, "x": at.x, "y": at.y})
	var dep := await msg("A_dep", 30.0)
	check(await wait_until(func() -> bool: return int(site(a).deposited.get("graveto", 0)) == 3, 10.0), "depósito do convidado chegou à obra (3/6)")
	check(int(dep.get("left", -1)) == 0, "os gravetos saíram da bolsa do convidado")
	check(not BUILD.work(self, a, 3.0) and float(site(a).progress) == 0.0, "sem material completo a obra não anda")
	BAG.add_item(self, "graveto", 3)
	BAG.add_item(self, "pedra_pequena", 4)
	BAG.add_item(self, "corda", 2)
	player.global_position = at + Vector2(-18, 20)
	await physics_frame
	await press()
	check(BUILD.stage(site(a)) == "ready" and BAG.count_item(self, "graveto") == 0, "anfitrião completou o material")
	check(not (await msg("A_ready", 20.0)).is_empty(), "convidado vê a planta pronta (verde)")
	say("A_build")
	await press()
	var started := Time.get_ticks_msec()
	await create_timer(1.5).timeout
	check(str(placer.get("_building")) == a, "anfitrião continua construindo com o convidado ajudando")
	var mid := await msg("A_mid", 10.0)
	check(bool(mid.get("building", false)), "convidado continua construindo (a obra dele não foi cancelada)")
	check(await wait_until(func() -> bool: return bool(site(a).get("built", false)), 15.0), "bancada concluída em dupla")
	var duo := (Time.get_ticks_msec() - started) / 1000.0
	await create_timer(0.8).timeout
	check(not BUILD.work(self, a, 1.0) and int(site(a).deposited.graveto) == 6, "conclui uma vez, sem duplicar material")
	var done_a := await msg("A_done", 20.0)
	check(bool(done_a.get("built", false)) and not bool(done_a.get("building", true)), "convidado vê a bancada pronta e para de construir")

	# B) Mesma obra só com o anfitrião.
	var at_b := free_spot(placer, base + Vector2(0, 300))
	var b := place(placer, at_b, "bancada", true)
	player.global_position = at_b + Vector2(-18, 20)
	await physics_frame
	await press()
	started = Time.get_ticks_msec()
	check(await wait_until(func() -> bool: return bool(site(b).get("built", false)), 15.0), "bancada concluída sozinho")
	var solo := (Time.get_ticks_msec() - started) / 1000.0
	check(duo < solo * 0.8, "dupla termina mais rápido (%.1f s x %.1f s sozinho)" % [duo, solo])

	# C) Afastar um não cancela o outro.
	var at_c := free_spot(placer, base + Vector2(0, 460))
	var c := place(placer, at_c, "bau_campo", true)
	player.global_position = at_c + Vector2(-18, 20)
	await physics_frame
	say("C", {"id": c, "x": at_c.x, "y": at_c.y})
	check(not (await msg("C_seen", 20.0)).is_empty(), "convidado vê a planta do baú")
	say("C_build")
	await press()
	var gone := await msg("C_left", 20.0)
	check(bool(gone.get("stopped", false)), "o convidado se afastou e parou só a obra dele")
	await create_timer(0.5).timeout
	check(str(placer.get("_building")) == c or bool(site(c).get("built", false)), "anfitrião continua construindo depois que o convidado saiu")
	check(await wait_until(func() -> bool: return bool(site(c).get("built", false)), 10.0), "baú concluído pelo anfitrião")

	# D) Convidado deposita e cancela.
	var at_d := free_spot(placer, base + Vector2(0, 620))
	var d := place(placer, at_d, "bancada", false)
	say("D", {"id": d, "x": at_d.x, "y": at_d.y})
	var dd := await msg("D_done", 30.0)
	check(site(d).is_empty(), "planta cancelada pelo convidado some no anfitrião")
	check(bool(dd.get("ok", false)), "as cordas depositadas voltaram ao convidado")

	# E) Prévia do convidado (ID 23).
	say("E")
	var ghost: Sprite2D = placer.get("_remote_ghost")
	check(await wait_until(func() -> bool: return ghost.visible, 10.0), "anfitrião vê a prévia da planta do convidado")
	say("E_off")
	check(await wait_until(func() -> bool: return not ghost.visible, 10.0), "a prévia some quando o convidado desiste")

	say("end")
	var result := await msg("result", 20.0)
	for line in result.get("checks", []): print("  convidado " + str(line))
	check(not result.is_empty() and int(result.get("failures", 1)) == 0, "verificações do convidado passaram")
	net.leave()
	OS.kill(guest)
	print("MP_BUILD: %d failures" % failures)
	quit(1 if failures else 0)

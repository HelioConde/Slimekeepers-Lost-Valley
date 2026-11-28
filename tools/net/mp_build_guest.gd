extends SceneTree
## Convidado do tools/test_mp_build.gd: entra pela rede local e segue os passos que o
## anfitrião manda (mensagens "tst"); devolve as verificações no fim ("result").

const BAG := preload("res://scripts/systems/forest_bag.gd")
const BUILD := preload("res://scripts/systems/build_site.gd")
var checks: Array[String] = []
var failures := 0
var inbox: Array[Dictionary] = []
var net: Node


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


func at_of(d: Dictionary) -> Vector2:
	return Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))


func run() -> void:
	DisplayServer.window_set_position(Vector2i(40, 40))
	var port := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 24694
	net = root.get_node("NetSession")
	net.message.connect(func(d: Dictionary) -> void: if str(d.get("t", "")) == "tst": inbox.append(d))
	set_meta("tutorial_step", 99)
	check(net.join_enet("127.0.0.1", port).is_empty(), "conecta ao anfitrião")
	check(await wait_until(func() -> bool: return bool(net.connected), 30.0), "recebe as boas-vindas")
	check(await wait_until(func() -> bool:
		return current_scene != null and current_scene.scene_file_path.ends_with("FlorestaDoDespertarV2.tscn") and current_scene.get("player") != null, 60.0),
		"entra no mapa do anfitrião")
	for i in 30: await process_frame
	var scene := current_scene
	var player: Node2D = scene.get("player")
	var placer: Node2D = scene.get("placer")
	Input.warp_mouse(Vector2.ZERO)
	var base := at_of(await msg("base"))
	player.global_position = base + Vector2(300, 0)
	set_meta("tutorial_step", 99)
	say("ready")

	# A) Vê a planta, deposita 3 gravetos, constrói junto.
	var a := await msg("A")
	var id := str(a.get("id", ""))
	check(await wait_until(func() -> bool: return placer.call("_node", id) != null, 10.0), "vê a planta do anfitrião")
	check(BUILD.stage(BUILD.find(self, id)) == "plan", "planta esperando material na tela do convidado")
	BAG.add_item(self, "graveto", 3)
	player.global_position = at_of(a) + Vector2(18, 20)
	await physics_frame
	await press()
	say("A_dep", {"left": BAG.count_item(self, "graveto")})
	# >= 3: o anfitrião completa logo depois do depósito do convidado.
	check(await wait_until(func() -> bool: return int(BUILD.find(self, id).get("deposited", {}).get("graveto", 0)) >= 3, 10.0), "vê o próprio depósito chegar à obra")
	check(await wait_until(func() -> bool: return BUILD.stage(BUILD.find(self, id)) == "ready", 20.0), "vê a planta pronta para construir")
	var label: Label = (placer.call("_node", id) as Node2D).get_node("Needs")
	check(label.text.contains("completos"), "texto da planta avisa os materiais completos")
	say("A_ready")
	await msg("A_build")
	await press()
	await create_timer(1.5).timeout
	say("A_mid", {"building": str(placer.get("_building")) == id})
	check(await wait_until(func() -> bool: return bool(BUILD.find(self, id).get("built", false)), 15.0), "vê a bancada concluída")
	await create_timer(0.5).timeout
	say("A_done", {"built": bool(BUILD.find(self, id).get("built", false)), "building": not str(placer.get("_building")).is_empty()})
	check(BAG.count_item(self, "graveto") == 0, "nenhum graveto voltou nem duplicou")

	# C) Constrói o baú junto e se afasta.
	var c := await msg("C")
	var cid := str(c.get("id", ""))
	await wait_until(func() -> bool: return placer.call("_node", cid) != null, 10.0)
	player.global_position = at_of(c) + Vector2(18, 20)
	await physics_frame
	say("C_seen")
	await msg("C_build")
	await press()
	await create_timer(1.0).timeout
	var was := str(placer.get("_building")) == cid
	player.global_position = at_of(c) + Vector2(300, 0)  # afasta
	await create_timer(0.3).timeout
	say("C_left", {"stopped": was and str(placer.get("_building")).is_empty()})
	check(was, "estava construindo o baú junto")

	# D) Deposita 2 cordas e cancela: recebe de volta.
	var d := await msg("D")
	var did := str(d.get("id", ""))
	await wait_until(func() -> bool: return placer.call("_node", did) != null, 10.0)
	player.global_position = at_of(d) + Vector2(18, 20)
	await physics_frame
	BAG.add_item(self, "corda", 2)
	await press()
	var deposited := await wait_until(func() -> bool: return int(BUILD.find(self, did).get("deposited", {}).get("corda", 0)) == 2, 10.0)
	check(deposited and BAG.count_item(self, "corda") == 0, "depositou 2 cordas")
	placer.call("cancel_site", did)
	var ok := await wait_until(func() -> bool: return BAG.count_item(self, "corda") == 2 and placer.call("_node", did) == null, 10.0)
	check(ok, "cancelar devolveu as cordas e tirou a planta")
	say("D_done", {"ok": ok})

	# E) Prévia que o anfitrião vê.
	await msg("E")
	player.global_position = base + Vector2(120, 120)
	placer.call("begin_plan", "bancada")
	await msg("E_off")
	placer.set("_plan_kind", "")

	await msg("end")
	say("result", {"failures": failures, "checks": checks})
	for i in 60: await process_frame
	quit()

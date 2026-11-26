extends SceneTree
## Convidado do tools/test_mp_drops.gd: entra pela rede local e segue os passos que o
## anfitrião manda (mensagens "tst"); devolve as verificações no fim ("result").

const BAG := preload("res://scripts/systems/forest_bag.gd")
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


func count(item: String) -> int:
	return BAG.count_item(self, item)


func at_of(d: Dictionary) -> Vector2:
	return Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))


func run() -> void:
	DisplayServer.window_set_position(Vector2i(40, 40))
	var port := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 24692
	net = root.get_node("NetSession")
	net.message.connect(func(d: Dictionary) -> void: if str(d.get("t", "")) == "tst": inbox.append(d))
	check(net.join_enet("127.0.0.1", port).is_empty(), "conecta ao anfitrião")
	check(await wait_until(func() -> bool: return bool(net.connected), 30.0), "recebe as boas-vindas")
	check(await wait_until(func() -> bool:
		return current_scene != null and current_scene.scene_file_path.ends_with("FlorestaDoDespertarV2.tscn") and current_scene.get("player") != null, 60.0),
		"entra no mapa do anfitrião")
	for i in 30: await process_frame
	var scene := current_scene
	check(await wait_until(func() -> bool:
		var r := scene.find_child("RemotePlayer", true, false)
		return r != null and (r as Node2D).visible, 30.0), "vê o Aren do anfitrião")
	var base := at_of(await msg("base"))
	var drops: Node2D = scene.get("item_drops")
	var player: Node2D = scene.get("player")
	player.global_position = base + Vector2(300, 0)
	say("ready")
	# A) Coleta: o graveto cai pelo mesmo caminho da coleta (forage.drop = item_drops.spawn).
	await msg("A")
	var forage: Node = scene.get("forage")
	var drop: Callable = forage.get("drop") if is_instance_valid(forage) else Callable(drops, "spawn")
	drop.call("graveto", 1, base + Vector2(300, -200))
	var stick: Dictionary = drops.drops.back()
	check(bool(stick.shared), "drop da coleta é compartilhado")
	await wait_until(func() -> bool: return bool(stick.ready), 5.0)
	var stick_at := (stick.node as Node2D).global_position
	say("A_landed", {"id": stick.id, "x": stick_at.x, "y": stick_at.y})
	await msg("A_take")
	var sticks := count("graveto")
	player.global_position = stick_at + Vector2(0, 14)
	var ok := await wait_until(func() -> bool: return count("graveto") == sticks + 1 and drops.pending() == 0, 10.0)
	check(ok, "pegou o próprio graveto pelo anfitrião")
	say("A_done", {"ok": ok})
	# B) Disputa: vê a pedra do anfitrião e corre para ela quando mandarem (2 rodadas).
	for round in 2:
		player.global_position = base + Vector2(300, 0)
		check(await wait_until(func() -> bool:
			return drops.drops.any(func(e: Dictionary) -> bool: return e.item == "pedra_pequena" and bool(e.ready)), 15.0),
			"vê a pedra solta pelo anfitrião")
		say("B_seen")
		var stones := count("pedra_pequena")
		var go := await msg("B_go")
		player.global_position = at_of(go) + Vector2(12, 14)
		await wait_until(func() -> bool: return drops.pending() == 0, 10.0)
		await create_timer(0.5).timeout
		say("B_done", {"n": count("pedra_pequena") - stones, "left": drops.pending()})
	# C) Solta 3 de 5 fibras; não puxa de volta; o anfitrião pega.
	await msg("C")
	player.global_position = base + Vector2(300, 0)
	await create_timer(0.3).timeout
	var fibers := count("fibra")
	BAG.add_item(self, "fibra", 5)
	check(drops.drop_from_bag("fibra", 3), "solta 3 fibras")
	check(not drops.drop_from_bag("fibra", 99), "não solta mais do que tem")
	var fiber: Dictionary = drops.drops.back()
	await wait_until(func() -> bool: return bool(fiber.ready), 5.0)
	await create_timer(0.6).timeout
	check(count("fibra") == fibers + 2 and drops.pending() == 3, "ficou com 2 e não puxou as 3 de volta")
	var fiber_at := (fiber.node as Node2D).global_position
	say("C_dropped", {"id": fiber.id, "x": fiber_at.x, "y": fiber_at.y})
	await msg("C_check")
	ok = await wait_until(func() -> bool: return drops.pending() == 0, 5.0) and count("fibra") == fibers + 2
	say("C_done", {"ok": ok})
	# D) Pega o machado que o anfitrião soltou.
	var axe := await msg("D")
	player.global_position = at_of(axe) + Vector2(0, 14)
	ok = await wait_until(func() -> bool: return count("machado") == 1 and drops.pending() == 0, 10.0)
	say("D_done", {"ok": ok})
	await msg("end")
	say("result", {"failures": failures, "checks": checks})
	for i in 60: await process_frame
	quit()

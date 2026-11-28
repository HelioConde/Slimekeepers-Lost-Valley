extends SceneTree
## Convidado do tools/test_mp_sleep_chop.gd (passos por mensagens "tst").

const ENERGY := preload("res://scripts/systems/energy_state.gd")
var checks: Array[String] = []
var failures := 0
var inbox: Array[Dictionary] = []
var fx: Array[Dictionary] = []
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


func run() -> void:
	DisplayServer.window_set_position(Vector2i(40, 40))
	var port := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 24694
	net = root.get_node("NetSession")
	net.message.connect(func(d: Dictionary) -> void:
		if str(d.get("t", "")) == "tst": inbox.append(d)
		if str(d.get("t", "")) == "chop_fx": fx.append(d))
	check(net.join_enet("127.0.0.1", port).is_empty(), "conecta ao anfitrião")
	var trees := await msg("trees", 90.0)
	check(await wait_until(func() -> bool:
		return current_scene != null and current_scene.scene_file_path.ends_with("FlorestaDoDespertarV2.tscn") and current_scene.get("choppable") != null, 60.0),
		"entra no mapa do anfitrião")
	for i in 30: await process_frame
	var scene := current_scene
	var chop: Node = scene.get("choppable")
	var host_key := str(trees.get("mine", ""))
	var my_key := str(trees.get("yours", ""))
	var host_tree: Node2D = chop.trees.get(host_key)
	var falling := [false]
	if host_tree != null:
		host_tree.get_parent().child_entered_tree.connect(func(n: Node) -> void:
			if str(n.name).begins_with("Falling"): falling[0] = true)
	say("ready")
	await wait_until(func() -> bool: return falling[0], 15.0)
	await create_timer(0.5).timeout
	say("host_fell", {"fx": fx.size(), "fell": falling[0] and host_tree != null and not (host_tree.get_node("Sprite") as CanvasItem).visible})
	await msg("chop")
	var tree: Node2D = chop.trees[my_key]
	var hits: int = chop.fell_hits(my_key)
	for i in hits:
		chop.strike({"key": my_key, "kind": "tree"}, root.get_node("GameClock").day_number, 1, tree.global_position + Vector2.LEFT * 30)
		await create_timer(0.2).timeout
	say("guest_fell", {"hits": hits})
	# 35) Dormir: deita depois do anfitrião; acorda quando o dia vira.
	var sleep := await msg("sleep", 60.0)
	var clock := root.get_node("GameClock")
	ENERGY.restore(self, -ENERGY.MAX)
	var day := int(sleep.get("day", 1))
	scene.sleep_until_morning()
	var sleep_net: Node = scene.get_node("NetSleep")
	check(await wait_until(func() -> bool: return int(clock.day_number) == day + 1 and not bool(sleep_net.sleeping), 15.0), "convidado acorda no dia seguinte")
	say("woke", {"day": clock.day_number, "hour": clock.get_hour(), "full": ENERGY.current(self) == ENERGY.MAX,
		"checks": checks, "failures": failures})
	await create_timer(1.0).timeout
	quit(0)

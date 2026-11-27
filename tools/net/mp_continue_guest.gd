extends SceneTree
## Convidado do test_mp_continue: entra, confere a bolsa guardada, pega 2 gravetos e sai.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const RESULT := "user://mp_continue_guest_result.json"
var checks: Array[String] = []
var failures := 0


func check(ok: bool, what: String) -> void:
	checks.append(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func wait_until(cond: Callable, seconds: float) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		if cond.call(): return true
		await process_frame
	return false


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var port := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 24731
	var net := root.get_node("NetSession")
	check(net.join_enet("127.0.0.1", port).is_empty(), "conecta ao anfitrião")
	check(await wait_until(func() -> bool: return bool(net.connected), 30.0), "recebe as boas-vindas")
	check(await wait_until(func() -> bool: return current_scene != null and current_scene.scene_file_path.contains("Floresta"), 30.0), "entra direto no mapa do anfitrião")
	check(BAG.count_item(self, "pedra_polida") == 3, "volta com a bolsa guardada (3 pedras polidas, tem %d)" % BAG.count_item(self, "pedra_polida"))
	BAG.add_item(self, "graveto", 2)
	for i in 150: await process_frame  # ~2 s: a bolsa nova sai na próxima conferência
	net.leave()
	for i in 20: await process_frame
	var file := FileAccess.open(RESULT, FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "checks": checks}))
	file.close()
	quit()

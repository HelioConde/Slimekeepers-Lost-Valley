extends SceneTree
## Anéis da dica da coleta (benchmark rodada 2, 2026-11-27): só o que ainda falta, até
## 3 por tipo e de mais longe; antes eram os 6 mais perto de qualquer tipo.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_tutorial_targets.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HUD := preload("res://scripts/ui/tutorial_hud.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	set_meta("tutorial_step", 1)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	var tutorial: Node = null
	for n in region.find_children("*", "", true, false):
		if n.get_script() == HUD: tutorial = n
	check(tutorial != null, "dica na tela")
	if tutorial:
		var targets: Array = tutorial.call("_targets", "pick")
		var kinds := {}
		for t: Array in targets: kinds[t[2]] = int(kinds.get(t[2], 0)) + 1
		check(int(kinds.get("graveto", 0)) <= 3 and int(kinds.get("pedra_pequena", 0)) <= 3, "até 3 anéis por tipo (%s)" % kinds)
		check(kinds.has("graveto") and kinds.has("pedra_pequena"), "gravetos e pedrinhas marcados juntos (%s)" % kinds)
		BAG.add_item(self, "graveto", 8)
		targets = tutorial.call("_targets", "pick")
		check(not targets.is_empty() and targets.all(func(t: Array) -> bool: return t[2] == "pedra_pequena"), "com 8 gravetos, só pedrinhas ficam marcadas")
	print("TUTORIAL_TARGETS: %d failures" % failures)
	quit(1 if failures else 0)

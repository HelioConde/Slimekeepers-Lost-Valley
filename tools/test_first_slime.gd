extends SceneTree
## Primeiro slime cedo (benchmark 2026-11-27): ao terminar a dica da coleta, um Brotinho
## visita a beira da clareira e o Aren avisa num balão.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_first_slime.gd

const Forest := preload("res://scripts/world/forest_layout.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func visitor(region: Node) -> Node2D:
	for slime: Node2D in region.get("slimes"):
		if is_instance_valid(slime) and str(slime.get("persistent_id")) == "brotinho/H00/0": return slime
	return null


func run() -> void:
	set_meta("tutorial_step", 1)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	check(visitor(region) == null and not get_meta("first_slime_visit", false), "antes de acabar a coleta, sem visitante")
	set_meta("tutorial_step", 2)
	for i in 10: await process_frame
	var slime := visitor(region)
	check(bool(get_meta("first_slime_visit", false)), "coleta concluída libera o visitante")
	check(slime != null, "Brotinho visitante apareceu")
	if slime:
		check(slime.global_position.distance_to(Forest.SPAWN) < 400.0, "na beira da clareira (%.0f px do início)" % slime.global_position.distance_to(Forest.SPAWN))
	var speech: Control = region.get("speech")
	check(is_instance_valid(speech) and speech.visible and _text(speech).contains("Brotinho"), "o Aren avisa no balão")
	print("FIRST_SLIME: %d failures" % failures)
	quit(1 if failures else 0)


func _text(node: Node) -> String:
	var text := ""
	for label in node.find_children("*", "Label", true, false): text += (label as Label).text
	return text

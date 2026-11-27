extends SceneTree
## Playtest ID 46: com o baú aberto, mudança que chega pela rede (NetWorld grava a chave da
## sessão) aparece na janela sem fechar e abrir de novo.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_chest_live.gd

const CHEST := preload("res://scripts/systems/chest_storage.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


## Quantidade desenhada no primeiro espaço do baú (playtest ID 45: grade de espaços).
func _shown(panel: Control) -> String:
	var slot: Node = panel.find_child("Chest0", true, false)
	var out := ""
	if slot: for label: Label in slot.find_children("*", "Label", true, false): out += label.text
	return out


func run() -> void:
	for k in [CHEST.KEY, CHEST.PLACED_KEY]:
		if has_meta(k): remove_meta(k)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var panel: Control = preload("res://scripts/ui/chest_panel.gd").new()  # como o test_close_buttons
	panel.player = region.get("player")
	region.get_node("HUD/Interface").add_child(panel)
	panel.call("open", "")
	for i in 3: await process_frame
	check(panel.call("entries", 1).is_empty(), "baú começa sem madeira")
	set_meta(CHEST.KEY, {"madeira": 7})  # como o NetWorld grava o que o outro jogador guardou
	for i in 3: await process_frame
	check(_shown(panel) == "7", "madeira do outro jogador aparece sem reabrir")
	set_meta(CHEST.KEY, {"madeira": 2})
	for i in 3: await process_frame
	check(_shown(panel) == "2", "retirada do outro jogador atualiza na hora")
	panel.call("close")
	print("CHEST_LIVE: %d failures" % failures)
	quit(1 if failures else 0)

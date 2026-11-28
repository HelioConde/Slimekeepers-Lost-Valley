extends SceneTree
## ADMIN (remover junto com scripts/debug/): confere os comandos de teste do [F1].
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_admin_commands.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var admin: Node = region.get_node_or_null("AdminCommands")
	check(admin != null, "comandos de admin existem em build de depuração")
	admin.call("run", "kit")
	check(BAG.count_item(self, "machado") == 1 and BAG.count_item(self, "bancada") == 1 and BAG.count_item(self, "graveto") == 10, "kit cabe inteiro na mochila")
	check(str(admin.call("run", "item graveto 3")).begins_with("+3"), "item dá a quantidade pedida")
	check(str(admin.call("run", "item nada")) == "Item desconhecido.", "item desconhecido avisa")
	set_meta("player_energy", 10)
	admin.call("run", "energia")
	check(int(get_meta("player_energy")) == 100, "energia enche")
	admin.call("run", "hora 18")
	check(root.get_node("GameClock").get_hour() == 18, "hora muda")
	admin.call("run", "tutorial fim")
	check(int(get_meta("tutorial_step")) >= 12, "tutorial termina")
	check(str(admin.call("run", "amigos")).contains("amigos"), "amigos responde")
	print("ADMIN: %d failures" % failures)
	quit(1 if failures else 0)

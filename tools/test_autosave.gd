extends SceneTree
## Autosave ao amanhecer (relatório de playtest ID 57) e Continuar (ID 56), no jogo real:
## às 06:00 grava uma vez por dia, sem cama; o save restaura o último amanhecer.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_autosave.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var Save: GDScript = load("res://scripts/systems/save_game.gd")
	Save.prefix = "user://test_autosave_%d_" % Time.get_ticks_usec()  # nunca os saves do jogador
	Save.use_slot(1)
	var clock: Node = root.get_node("GameClock")
	if has_meta("autosave_day"): remove_meta("autosave_day")
	clock.set_time(5, 50)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	current_scene = region
	for i in 20: await process_frame
	check(not Save.has_save(), "antes do amanhecer não há save")
	BAG.add_item(self, "graveto", 7)
	clock.advance_minutes(15.0)  # 06:05
	for i in 3: await process_frame
	check(Save.has_save(), "às 06:00 o jogo salva sozinho (sem cama)")
	var day: int = clock.day_number
	check(int(Save.info(1).day) == day, "save marca o dia %d" % day)
	var first: int = int(Save.read().saved_at)
	BAG.add_item(self, "graveto", 5)  # depois do autosave: fica de fora
	clock.advance_minutes(60.0)
	for i in 3: await process_frame
	check(int(Save.read().saved_at) == first and BAG.count_item(self, "graveto") == 12, "um autosave por dia")
	var region_path := region.scene_file_path
	region.queue_free()
	for i in 3: await process_frame
	var opened: String = Save.restore(self, clock)
	check(opened == region_path, "Continuar abre a região salva")
	check(BAG.count_item(self, "graveto") == 7, "restaura o estado do último amanhecer (7 gravetos, %d)" % BAG.count_item(self, "graveto"))
	Save.delete()
	print("AUTOSAVE: %d failures" % failures)
	quit(1 if failures else 0)

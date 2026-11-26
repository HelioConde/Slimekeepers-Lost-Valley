extends SceneTree
## Exaustão (relatório de playtest IDs 35 e 39), no jogo real:
## - sem energia, insistir 3 vezes numa ação faz dormir no lugar;
## - acorda às 06:00 do dia seguinte com 50% da energia, no mesmo lugar;
## - a virada do dia acordado não devolve energia.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_exhaustion.gd

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var Save: GDScript = load("res://scripts/systems/save_game.gd")
	Save.prefix = "user://test_exhaustion_%d_" % Time.get_ticks_usec()  # autosave longe dos saves do jogador
	var energy: GDScript = load("res://scripts/systems/energy_state.gd")
	var clock: Node = root.get_node("GameClock")
	clock.set_time(10, 0)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	current_scene = region
	for i in 20: await process_frame
	var day: int = clock.day_number
	var player: Node2D = region.get("player")
	var spot: Vector2 = player.global_position
	set_meta(energy.KEY, 0)
	check(not energy.spend(self, "chop") and not energy.spend(self, "chop"), "sem energia, a ação é negada")
	await create_timer(0.5).timeout
	check(clock.day_number == day, "duas tentativas ainda não fazem dormir")
	energy.spend(self, "chop")  # terceira insistência
	await create_timer(0.6).timeout
	check(clock.day_number == day + 1 and clock.get_hour() == 6, "dormiu no lugar e acordou às 06:00 do dia seguinte (dia %d, %02d:%02d)" % [clock.day_number, clock.get_hour(), clock.get_minute()])
	check(energy.current(self) == energy.MAX / 2, "acordou com metade da energia (%d)" % energy.current(self))
	check(player.global_position.distance_to(spot) < 2.0, "continua no mesmo lugar")
	# ID 39: atravessar a meia-noite acordado não recarrega.
	set_meta(energy.KEY, 30)
	clock.set_time(23, 50)
	clock.advance_minutes(5.0)  # 23:55, ainda acordado antes do desmaio
	check(energy.current(self) == 30, "a noite acordada não devolve energia (%d)" % energy.current(self))
	for n in range(1, Save.SLOTS + 1):
		Save.use_slot(n)
		Save.delete()
	print("EXHAUSTION: %d failures" % failures)
	quit(1 if failures else 0)

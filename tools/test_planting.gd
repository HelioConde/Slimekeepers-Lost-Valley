extends SceneTree
## Playtest ID 11: plantar tem animação e duração. A semente só entra quando a mão toca a
## terra (pose pick_small), uma semente por plantio, e repetir o [F] no meio não duplica.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_planting.gd

const FARM := preload("res://scripts/systems/farm_state.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	set_meta("tutorial_step", 99)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	current_scene = region
	for i in 20: await process_frame
	var player: CharacterBody2D = region.get("player")
	var farm: Node2D = region.get("farm")
	check(farm != null, "a Floresta tem plantio livre")
	player.facing = "south"
	await physics_frame
	var cell: Vector2i = farm.call("target_cell", player)
	var field: String = farm.get("field_id")
	FARM.till(self, cell, field)
	BAG.add_item(self, "semente_cenoura", 3)
	HOTBAR.select(self, HOTBAR.slots(self).find("semente_cenoura"))
	await process_frame
	var seeds := BAG.count_item(self, "semente_cenoura")
	var message: String = farm.call("interact", player)
	check(message == "Plantando..." and player.is_using_tool(), "[F] começa a pose de plantar (%s)" % message)
	check(FARM.crop(self, cell, field).is_empty() and BAG.count_item(self, "semente_cenoura") == seeds, "a semente ainda não entrou no instante do [F]")
	# [F] de novo no meio da pose: a região ignora (o jogador está ocupado).
	check(region.call("handle_farming", farm) == true and BAG.count_item(self, "semente_cenoura") == seeds, "repetir o [F] no meio da pose não gasta outra semente")
	await create_timer(0.6).timeout
	check(FARM.crop(self, cell, field) == "cenoura", "a semente entra quando a mão toca a terra")
	check(BAG.count_item(self, "semente_cenoura") == seeds - 1, "uma semente por plantio (%d -> %d)" % [seeds, BAG.count_item(self, "semente_cenoura")])
	var wait := 0.0
	while player.is_using_tool() and wait < 2.0:
		await process_frame
		wait += get_root().get_process_delta_time()
	check(not player.is_using_tool() and wait > 0.0, "a pose termina e devolve o controle")
	print("PLANTING: %d failures" % failures)
	quit(1 if failures else 0)

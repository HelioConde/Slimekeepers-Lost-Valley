extends SceneTree
## Mapa da fazenda: carrega, tem casa sólida, campo próprio, dormir vira o dia e
## recupera energia, e o caminho Vale <-> fazenda funciona.
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
func _initialize(): call_deferred("run")
func settle() -> void:
	for i in 12: await process_frame
func run() -> void:
	var Travel = load("res://scripts/world/region_travel.gd")
	var Save = load("res://scripts/systems/save_game.gd")
	Save.path = "user://test_farm_region_save.txt"
	Save.delete()
	change_scene_to_file(Travel.FARM)
	await settle()
	var farm: Node2D = current_scene
	check(farm != null and farm.name == "Fazenda", "Fazenda carrega")
	var field = farm.get_node_or_null("FarmField")
	check(field != null and field.field_id == "fazenda" and field.size_cells == Vector2i(16, 10), "Campo grande próprio")
	check(farm.get_node_or_null("MapArt/House/SolidBase") != null, "Casa tem base sólida")
	check(farm.get_node("VegetationHigh").get_child_count() > 30, "Borda de árvores")
	check(farm.get_node_or_null("HUD/Interface/Hotbar") != null and farm.get_node_or_null("HUD/Interface/EnergyBar") != null, "Barra e energia no HUD")
	var shadows = farm.get_node("DayNightLighting/DayShadows")
	check(shadows.has_caster(farm.get_node("MapArt/House/Sprite")), "Casa projeta sombra")
	# Dormir: dia seguinte às 06:00, energia cheia.
	var clock := root.get_node("GameClock")
	var day: int = clock.day_number
	set_meta("player_energy", 10)
	farm.sleep()
	check(clock.day_number == day + 1 and clock.get_hour() == 6, "Dormir leva ao dia seguinte 06:00")
	check(int(get_meta("player_energy")) == 100, "Dormir recupera energia")
	check(Save.has_save() and Save.read().region == Travel.FARM, "Dormir salva o jogo na fazenda")
	Save.delete()
	# Vale <-> fazenda.
	farm.player.global_position = farm.WEST_GATE
	Travel.travel(farm, Travel.VALLEY, "valley_farm_gate")
	await settle()
	var valley: Node2D = current_scene
	check(valley.name == "ValeDasNascentes" and valley.player.position.distance_to(valley.FARM_GATE) < 60, "Chega no Vale junto à placa")
	Travel.travel(valley, Travel.FARM, "farm_west")
	await settle()
	check(current_scene.name == "Fazenda" and current_scene.player.position.distance_to(current_scene.WEST_GATE) < 90, "Volta pela entrada oeste")
	print("FARM_REGION: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

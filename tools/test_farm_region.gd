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
	# Sem casa inicial: constrói a casa (arraste) e a mobília com materiais.
	var House = load("res://scripts/systems/house_state.gd")
	var Bag = load("res://scripts/systems/forest_bag.gd")
	if has_meta(House.KEY): remove_meta(House.KEY)
	var rect := Rect2i(12, 5, 9, 7)
	for item in House.rect_cost(rect): Bag.add_item(self, item, int(House.rect_cost(rect)[item]))
	var furniture := {Vector2i(14, 7): "cama", Vector2i(17, 8): "mesa", Vector2i(18, 8): "cadeira",
		Vector2i(19, 7): "bau", Vector2i(16, 9): "tapete", Vector2i(13, 10): "planta"}
	for cell in furniture:
		var cost: Dictionary = House.FURNITURE_COSTS[furniture[cell]]
		for item in cost: Bag.add_item(self, item, int(cost[item]))
	check(House.build(self, "fazenda", rect) == "", "Casa construída com materiais (arraste)")
	for cell in furniture: House.place_furniture(self, cell, furniture[cell])
	change_scene_to_file(Travel.FARM)
	await settle()
	var farm: Node2D = current_scene
	check(farm != null and farm.name == "Fazenda", "Fazenda carrega")
	var field = farm.get_node_or_null("FarmField")
	check(field != null and field.field_id == "fazenda" and field.size_cells == Vector2i(16, 10), "Campo grande próprio")
	var house = farm.get_node_or_null("PlayerHouse")
	check(house != null and house.get_node("HouseCollision").get_child_count() > 20, "Casa construída tem paredes sólidas")
	check(house.get_node("Furniture").get_child_count() >= 5, "Casa mobiliada")
	check(house.get_node("Walls").get_child_count() > 3, "Paredes em fileiras ordenadas por Y")
	check(farm.get_node("VegetationHigh").get_child_count() > 30, "Borda de árvores")
	check(farm.get_node_or_null("HUD/Interface/Hotbar") != null and farm.get_node_or_null("HUD/Interface/EnergyBar") != null, "Barra e energia no HUD")
	var shadows = farm.get_node("DayNightLighting/DayShadows")
	# Dormir na cama: o jogador perto da cama recebe a ação.
	farm.player.global_position = Vector2(14 * 32 + 16, 9 * 32)
	check(house.near_bed(farm.player), "Jogador ao lado da cama pode dormir")
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

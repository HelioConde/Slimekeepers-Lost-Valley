extends "res://scripts/world/clearing_region.gd"
const Valley = preload("res://scripts/world/valley_layout.gd")
const Travel = preload("res://scripts/world/region_travel.gd")
const Living = preload("res://scripts/world/living_region.gd")
const BAG_HUD := preload("res://scripts/ui/forest_bag_hud.gd")
const GARDEN_BED := preload("res://scripts/world/valley_garden_bed.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
const COOKING_STATION := preload("res://scripts/world/valley_cooking_station.gd")
var ecosystem: Node2D
var habitat_manager: Node2D
var environmental_audio: Node2D
var elapsed := 0.0
var reduce_motion := false
var found_zones: Dictionary = {}
var bag_hud: Node
var garden_beds: Array[Node2D] = []
var cooking_station: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	y_sort_enabled = true
	player = $Player
	player.position = Valley.SPAWN
	player.world_bounds = Rect2(24,44,3152,3132)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_right = 3200
	camera.limit_bottom = 3200
	camera.reset_smoothing()
	_create_hud()
	_compact_hud()
	bag_hud = BAG_HUD.new()
	$HUD/Interface.add_child(bag_hud)
	hud_title.text = "VALE DAS NASCENTES"
	found_zones = get_tree().get_meta("valley_discoveries",{}).duplicate()
	hud_goal.text = "Siga as águas e explore as margens" if found_zones.is_empty() else "Recantos descobertos: %d / 5" % found_zones.size()
	var cfg := ConfigFile.new()
	if cfg.load("user://presentation.cfg") == OK:
		reduce_motion = cfg.get_value("accessibility","reduce_motion",false)
	if has_node("UnderwaterLife"):$UnderwaterLife.set_reduced_motion(reduce_motion)
	for fall in $Waterfalls.get_children():
		var life:=fall.get_node_or_null("LivingFoam")
		if life:life.set_reduced_motion(reduce_motion)
	if get_tree().has_meta("region_arrival"): get_tree().remove_meta("region_arrival")
	_setup_living_valley()
	preload("res://scripts/world/visual_rules.gd").new().apply(self,Valley.routes())
	var art := preload("res://scripts/world/map_art_enrichment.gd").new()
	art.region_kind = "valley"
	add_child(art)
	_spawn_starter_garden()
	_spawn_cooking_station()

func _spawn_starter_garden() -> void:
	var garden := Node2D.new()
	garden.name = "StarterGarden"
	add_child(garden)
	for plot in [
		{"id": "norte", "at": Vector2(1440, 560)},
		{"id": "sul", "at": Vector2(1390, 625)},
	]:
		var bed := GARDEN_BED.new()
		bed.configure(str(plot["id"]), plot["at"])
		garden.add_child(bed)
		garden_beds.append(bed)

func _spawn_cooking_station() -> void:
	cooking_station = COOKING_STATION.new()
	cooking_station.position = Vector2(1515, 460)
	add_child(cooking_station)

func _handle_cooking_interaction() -> bool:
	if not is_instance_valid(cooking_station):
		return false
	if player.global_position.distance_to(cooking_station.global_position) >= 68.0:
		return false
	var check: Dictionary = COOKING.availability(get_tree())
	hud_hint.text = "[E] Preparar porcao de folhas (teste)" if bool(check.get("available", false)) else "Preparo: falta 1 folha fresca colhida"
	if Input.is_action_just_pressed("interact"):
		var result: String = COOKING.prepare(get_tree())
		if result == "prepared":
			bag_hud.call("refresh")
			_notify("Preparo de teste pronto! Porcoes preparadas: %d" % COOKING.portions(get_tree()))
		elif result == "needs_leaves":
			_notify("Cultive e colha folhas frescas antes de preparar.")
		else:
			_notify("Nao foi possivel preparar; nenhum ingrediente foi gasto.")
	return true

func _nearest_garden_bed() -> Node2D:
	var result: Node2D = null
	var best_distance := 72.0
	for bed in garden_beds:
		if not is_instance_valid(bed):
			continue
		var distance := player.global_position.distance_to(bed.global_position)
		if distance < best_distance:
			best_distance = distance
			result = bed
	return result

func _handle_garden_interaction() -> bool:
	var bed := _nearest_garden_bed()
	if bed == null:
		return false
	var state: String = str(bed.call("phase"))
	match state:
		"empty":
			hud_hint.text = "[E] Plantar uma semente no canteiro" if BAG.seeds(get_tree()) > 0 else "Canteiro vazio · encontre sementes na floresta"
		"growing":
			hud_hint.text = "Cultivo crescendo · faltam %d minutos do jogo" % int(bed.call("remaining_minutes"))
		"ready":
			hud_hint.text = "[E] Colher folhas frescas"
		"harvested":
			hud_hint.text = "Canteiro colhido nesta partida"
	if Input.is_action_just_pressed("interact"):
		var action: String = str(bed.call("interact"))
		match action:
			"planted":
				bag_hud.call("refresh")
				_notify("Uma semente foi plantada. Volte quando crescer.")
			"collected":
				bag_hud.call("refresh")
				_notify("Folhas frescas guardadas na bolsa!")
			"needs_seed":
				_notify("A bolsa esta vazia. Recolha sementes com o Brotinho.")
	return true

func _setup_living_valley() -> void:
	var flowers: Array[Vector2] = []
	for prop in $LowVegetation.get_children():
		if "flower" in str(prop.name).to_lower(): flowers.append(prop.global_position)
	var water: Array[Vector2] = []
	for at in Valley.FALLS: water.append(at)
	for basin in Valley.basins(): water.append(basin[0])
	ecosystem = preload("res://scripts/world/forest_life.gd").new()
	ecosystem.name = "ValleyLife"
	ecosystem.configure(player,flowers,water)
	var routes := Valley.routes()
	ecosystem.open_area_test = func(at: Vector2) -> bool: return Valley.route_distance(at,routes)<90
	environmental_audio = Living.connect_environment(self,ecosystem,[$TreesBack,$TreesFront],[$LowVegetation,$WaterDecorations],water,Rect2(32,32,3136,3136),func(_at: Vector2) -> String: return "Vale das Nascentes")
	habitat_manager = preload("res://scripts/world/forest_habitats.gd").new()
	habitat_manager.name = "AquaticHabitatManager"
	add_child(habitat_manager)
	habitat_manager.slime_spawned.connect(_on_water_slime)
	var habitats: Array[Dictionary] = []
	for i in Valley.HABITATS.size():
		var center: Vector2 = Valley.HABITATS[i]
		habitats.append({"id":"V%02d"%(i+1),"center":center,"radius":130.0,
			"population":2 if i<2 else 1,"species_slots":["bolhinha","bolhinha"] if i<2 else ["bolhinha"],
			"spawn_points":[center+Vector2(-32,0),center+Vector2(32,0)],
			"water_points":[center,center+Vector2(0,30)],"flower_points":[center+Vector2(20,-20)]})
	var water_outlines: Array[PackedVector2Array] = []
	for polygon in $Water.get_children():
		if polygon is Polygon2D: water_outlines.append(polygon.polygon)
	var water_bodies := preload("res://scripts/world/region_surfaces.gd").classify_water(self)
	habitat_manager.configure(self,player,Valley.SPAWN,habitats,{"world_bounds":Rect2(32,32,3136,3136),"exclusion_radius":350.0,"max_population":8,"session_key":"valley_slime_friends","water_bodies":water_bodies,"water_outlines":water_outlines})
	habitat_manager.set_environment_state(get_tree().get_meta("environment_conditions",{}))
	_update_living_goal()

func _on_water_slime(slime: Node2D) -> void:
	slimes.append(slime)
	ecosystem.register_reactor(slime)
	slime.tree_exiting.connect(func(): slimes.erase(slime))
	_update_living_goal()

func _update_living_goal() -> void:
	friends_count = 0
	for friend in get_tree().get_meta("valley_slime_friends",{}).values():
		if friend: friends_count += 1
	hud_goal.text = "Amizades %d/8 · recantos %d/5" % [friends_count,found_zones.size()]

func set_environment_conditions(period: String, rain: float=0.0, wind: float=1.0, fog: float=0.0) -> void:
	Living.conditions(self,period,rain,wind,fog)

func _process(delta: float) -> void:
	elapsed += delta
	if message_time > 0:
		message_time -= delta
		if message_time <= 0: popup.text = ""
	hud_hint.text = "WASD / Setas: andar   •   Shift: correr   •   E: observar"
	if player.position.distance_to(Vector2(1600,70)) < 100:
		hud_hint.text = "[E] Voltar à Floresta do Despertar"
		if Input.is_action_just_pressed("interact"):
			Travel.travel(self,Travel.CLEARING,"clearing_south")
			return
	elif player.position.distance_to(Vector2(1780,3160)) < 100:
		hud_hint.text = "[E] Observar o caminho ao sul"
		if Input.is_action_just_pressed("interact"):
			_notify("O caminho segue pela ilha. Uma nova região chegará em breve.")
	else:
		if not _handle_cooking_interaction() and not _handle_garden_interaction():
			var closest := _closest_slime()
			if closest != null:
				hud_hint.text = "[E] Fazer amizade com "+closest.display_name() if not closest.befriended else "[E] Cumprimentar "+closest.display_name()
				if Input.is_action_just_pressed("interact"):
					closest.make_friend()
					_update_living_goal()
					_notify("Bolhinha salta e espalha pequenas gotas de alegria.")
			else:
				for marker: Marker2D in $PointsOfInterest.get_children():
					if player.position.distance_to(marker.position)<90:
						hud_hint.text = "[E] " + str(marker.get_meta("label"))
						if Input.is_action_just_pressed("interact"):
							_notify(marker.get_meta("description"))
							found_zones[marker.name] = true
							_update_living_goal()
						break
	if not reduce_motion:
		for water: Polygon2D in $Water.get_children():
			if water.material is ShaderMaterial:
				water.material.set_shader_parameter("elapsed",floor(elapsed*8)/8)
		if has_node("WaterBankTiles"):
			$WaterBankTiles.material.set_shader_parameter("elapsed",floor(elapsed*8)/8)
		for fall: Node2D in $Waterfalls.get_children():
			fall.get_node("Cascade").material.set_shader_parameter("elapsed",floor(elapsed*8)/8)

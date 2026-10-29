extends "res://scripts/world/clearing_region.gd"
const Valley = preload("res://scripts/world/valley_layout.gd")
const Travel = preload("res://scripts/world/region_travel.gd")
const Living = preload("res://scripts/world/living_region.gd")
var ecosystem: Node2D
var habitat_manager: Node2D
var environmental_audio: Node2D
var elapsed := 0.0
var reduce_motion := false
var found_zones: Dictionary = {}

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

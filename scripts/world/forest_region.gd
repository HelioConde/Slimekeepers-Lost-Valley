extends "res://scripts/world/clearing_region.gd"
## Runtime for expanded map; legacy clearing remains untouched.
const Forest = preload("res://scripts/world/forest_layout.gd")
const Living = preload("res://scripts/world/living_region.gd")
var found_places: Dictionary = {}
var ecosystem: Node2D
var habitat_manager: Node2D
var environmental_audio: Node2D
var _last_zone := ""
var _last_water_time := -1.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	y_sort_enabled = true
	player = $Player
	player.position = $SpawnPoints/PlayerSpawn.global_position
	player.world_bounds = Rect2(Vector2(24,44),Forest.WORLD_SIZE-Vector2(48,68))
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 6400
	camera.limit_bottom = 6400
	if get_tree().get_meta("region_arrival","") == "clearing_south":
		get_tree().remove_meta("region_arrival")
		player.position = Forest.SOUTH_ARRIVAL
	camera.reset_smoothing()
	found_places = get_tree().get_meta("forest_places",{}).duplicate()
	_create_hud()
	_compact_hud()
	hud_title.text = "FLORESTA DO DESPERTAR"
	_update_hud()
	for area in $Exits.get_children(): area.body_entered.connect(_on_exit_entered.bind(area.name))
	_setup_ecosystem()
	$PointsOfInterest/leaves.set_meta("description",Forest.points_of_interest()[0].description)
	habitat_manager = preload("res://scripts/world/forest_habitats.gd").new()
	habitat_manager.name = "HabitatManager"
	add_child(habitat_manager)
	habitat_manager.slime_spawned.connect(_on_forest_slime)
	var habitats := Forest.habitats()
	for h in habitats:
		h.flower_points = [h.center+Vector2(-60,-45),h.center+Vector2(60,30)]
		h.shade_points = [h.center+Vector2(-45,-35)]
		h.mushroom_points = [h.center+Vector2(45,40)]
		if h.id in ["H02","H04"]:
			h.species_slots = ["brotinho","brotinho","musguinho"]
		var marker := $SlimeHabitats.get_node_or_null(h.id)
		if marker: marker.position = h.center
	habitat_manager.configure(self,player,Forest.SPAWN,habitats)
	habitat_manager.set_environment_state(get_tree().get_meta("environment_conditions",{}))
	_add_habitat_flora(habitats)
	preload("res://scripts/world/visual_rules.gd").new().apply(self,Forest.trails())
	_arrange_pond_banks()
	var art := preload("res://scripts/world/map_art_enrichment.gd").new()
	art.region_kind = "forest"
	add_child(art)

func _arrange_pond_banks() -> void:
	# The inherited pond moved in the expanded map; its old ground props did not.
	var water: Polygon2D = $NaturalSpring/Pool/Water
	var rock: Node2D = $Decorations/MossyRock_1317
	if Geometry2D.is_point_in_polygon(water.to_local(rock.global_position), water.polygon):
		# Move the complete prop, including its fern and physical footprint.
		rock.global_position = water.global_position + Vector2(-75, -65)
	var layer: TileMapLayer = $VegetationLow
	var shoreline := PackedVector2Array()
	for vertex in water.polygon: shoreline.append(water.to_global(vertex))
	for cell in layer.get_used_cells():
		var data := layer.get_cell_tile_data(cell)
		var foot := layer.to_global(layer.map_to_local(cell) + Vector2(0, data.y_sort_origin))
		if not Geometry2D.is_point_in_polygon(foot, shoreline): continue
		var source := layer.get_cell_source_id(cell)
		var coords := layer.get_cell_atlas_coords(cell)
		var alternative := layer.get_cell_alternative_tile(cell)
		var atlas := layer.tile_set.get_source(source) as TileSetAtlasSource
		var used := atlas.texture.get_image().get_used_rect()
		var placed := false
		for radius in range(1, 6):
			if placed: break
			for dy in range(-radius, radius + 1):
				if placed: break
				for dx in range(-radius, radius + 1):
					if maxi(absi(dx), absi(dy)) != radius: continue
					var destination := cell + Vector2i(dx, dy)
					if layer.get_cell_source_id(destination) != -1: continue
					var center := layer.to_global(layer.map_to_local(destination) - Vector2(data.texture_origin))
					var bounds := Rect2(center - Vector2(atlas.texture_region_size) * .5 + Vector2(used.position), Vector2(used.size)).grow(10)
					var rectangle := PackedVector2Array([bounds.position, bounds.position + Vector2(bounds.size.x, 0), bounds.end, bounds.position + Vector2(0, bounds.size.y)])
					if not Geometry2D.intersect_polygons(rectangle, shoreline).is_empty(): continue
					layer.set_cell(destination, source, coords, alternative)
					layer.erase_cell(cell)
					placed = true
					break

func _add_habitat_flora(habitats: Array[Dictionary]) -> void:
	# A few reused plants mark the two new resting spots along existing trails.
	# They have no collision, leave the trail center clear and keep every painted tile.
	var group := Node2D.new()
	group.name = "HabitatFlora"
	group.z_index = -2
	add_child(group)
	var flower := preload("res://assets/menu/environment/flowers.png")
	var fern := preload("res://assets/world/forest/fern.png")
	for habitat in habitats:
		if habitat.id not in ["H01","H03"]: continue
		for index in 6:
			var sprite := Sprite2D.new()
			sprite.texture = flower if index%2==0 else fern
			sprite.position = habitat.center+Vector2([-100,80,-66,105,-115,120][index],[-90,-80,95,90,25,15][index])
			sprite.offset.y = -sprite.texture.get_height()/2.0
			sprite.material = ecosystem.get_wind_material("plant")
			group.add_child(sprite)

func _on_forest_slime(slime: Node2D) -> void:
	slimes.append(slime)
	ecosystem.register_reactor(slime)
	slime.tree_exiting.connect(func(): slimes.erase(slime))
	_update_hud()

func _setup_ecosystem() -> void:
	var flowers: Array[Vector2] = []
	for at in get_meta("flower_points",PackedVector2Array()): flowers.append(at)
	var water: Array[Vector2] = []
	for at in get_meta("water_points",PackedVector2Array()): water.append(at)
	ecosystem = preload("res://scripts/world/forest_life.gd").new()
	ecosystem.name = "ForestLife"
	ecosystem.configure(player,flowers,water)
	ecosystem.open_area_test = func(at:Vector2)->bool: return Forest.open_area(at)
	environmental_audio = Living.connect_environment(self,ecosystem,[$VegetationHigh,$ExpandedForest],[$FlowerClusters,$WoodlandDetails],water,Rect2(32,32,6336,6336),Forest.zone)

func set_environment_conditions(period: String, rain: float=0.0, wind: float=1.0, fog: float=0.0) -> void:
	Living.conditions(self,period,rain,wind,fog)

func _process(delta: float) -> void:
	# The base world manages interaction/friendship; skip legacy map exit coordinates.
	var water_time: float = ecosystem.shared_wind_material.get_shader_parameter("wind_time")
	if water_time != _last_water_time:
		_last_water_time = water_time
		$SouthernBrook/Water.material.set_shader_parameter("elapsed",water_time)
	var zone_name := Forest.zone(player.position)
	if zone_name != _last_zone:
		_last_zone = zone_name
		hud_title.text = zone_name.to_upper()
	if message_time > 0:
		message_time -= delta
		if message_time <= 0: popup.text = ""
	var closest := _closest_slime()
	if closest != null:
		hud_hint.text = "[E] Fazer amizade com "+closest.display_name() if not closest.befriended else "[E] Cumprimentar "+closest.display_name()
		if Input.is_action_just_pressed("interact"):
			if not closest.befriended:
				closest.make_friend()
				_update_hud()
			_notify(closest.display_name()+" parece feliz com sua visita.")
		return
	hud_hint.text = "WASD / setas · explorar    Shift · correr    E · interagir"
	if player.position.distance_to(Forest.SOUTH_EXIT)<115:
		hud_hint.text = "[E] Viajar para o Vale das Nascentes"
		if Input.is_action_just_pressed("interact"):
			get_tree().set_meta("forest_places",found_places.duplicate())
			var travel = preload("res://scripts/world/region_travel.gd")
			travel.travel(self,travel.VALLEY,"valley_north")
		return
	var spring := get_node("NaturalSpring")
	if spring.can_examine(player.global_position):
		hud_hint.text = "[E] Examinar lago"
		if Input.is_action_just_pressed("interact"): _notify("Um pequeno lago de água cristalina repousa entre as árvores.")
		return
	for marker in $PointsOfInterest.get_children():
		if marker.position.distance_to(player.position)<100:
			hud_hint.text = "[E] Observar · "+marker.get_meta("title")
			if Input.is_action_just_pressed("interact"):
				found_places[str(marker.name)] = true
				_notify(marker.get_meta("description"))
				_update_hud()
			return

func _update_hud() -> void:
	if hud_goal == null: return
	# Count identities rather than spawn events: a restored friend remains one friend.
	friends_count = 0
	for befriended in get_tree().get_meta("forest_slime_friends",{}).values():
		if befriended: friends_count += 1
	var population := 10 if ResourceLoader.exists("res://assets/slimes/living_v3/musguinho/frames.tres") else 8
	hud_goal.text = "Amizades %d/%d · recantos %d/8" % [friends_count,population,found_places.size()]

func _on_exit_entered(body: Node2D, exit_name: StringName) -> void:
	if body != player or _visited_exits.has(exit_name): return
	_visited_exits[exit_name] = true
	var messages := {"North":"A Mata Antiga segue pelas colinas. Explore os caminhos ao redor.","East":"O Refúgio Verde se espalha pelos bosques floridos.","South":"Vale das Nascentes · pressione E para seguir pelas águas."}
	_notify(messages[str(exit_name)])

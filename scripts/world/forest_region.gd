extends "res://scripts/world/clearing_region.gd"
## Runtime for expanded map; legacy clearing remains untouched.
const Forest = preload("res://scripts/world/forest_layout.gd")
const Living = preload("res://scripts/world/living_region.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const FOOD := preload("res://scripts/systems/slime_food_session.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
const SEED_PATCH := preload("res://scripts/world/forest_seed_patch.gd")
const BAG_HUD := preload("res://scripts/ui/forest_bag_hud.gd")
const SEED_SITES := [
	{"id": "jardim_folhas", "at": Vector2(4480, 3270)},
	{"id": "bosque_cogumelos", "at": Vector2(2100, 2860)},
	{"id": "campo_brotos", "at": Vector2(3350, 4580)}
]
const FEEDING := preload("res://scripts/systems/slime_feeding.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const ENERGY := preload("res://scripts/systems/energy_state.gd")
const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
var found_places: Dictionary = {}
var ecosystem: Node2D
var habitat_manager: Node2D
var environmental_audio: Node2D
var _last_zone := ""
var _last_water_time := -1.0
var seed_patches: Array[Node2D] = []
var bag_hud: Node
var forage: Node2D
var crafting_panel: Control
var choppable: Node
var placer: Node2D
var intro: Node
## Pontos de coleta na Clareira (ajustável): o bastante para machado e bancada.
## A fibra vem de todo o mato do chão (forage_spots.add_mato).
const FORAGE_PLAN := {"graveto": 6, "pedra_pequena": 8}
var ground_detail: Node2D
var _pull_id := ""  # ponto sendo arrancado com [E] segurado
var _pull_time := 0.0
var _spawn_light: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	y_sort_enabled = true
	add_child(PauseOverlay.new())
	player = $Player
	player.position = $SpawnPoints/PlayerSpawn.global_position
	# Foco de luz sobre o início da aventura (Clareira do Despertar), preso ao mundo.
	_spawn_light = preload("res://scripts/world/spawn_light.gd").new()
	add_child(_spawn_light)
	_spawn_light.setup($SpawnPoints/PlayerSpawn.global_position)
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
	bag_hud = BAG_HUD.new()
	$HUD/Interface.add_child(bag_hud)
	crafting_panel = preload("res://scripts/ui/crafting_panel.gd").new()
	crafting_panel.player = player
	$HUD/Interface.add_child(crafting_panel)
	crafting_panel.crafted.connect(func(_id: String) -> void: bag_hud.call("refresh"))
	# Novo Jogo confirmado: o protagonista escolhido desperta sentado no início.
	if PROTAGONIST.intro_pending(get_tree()):
		player.position = $SpawnPoints/PlayerSpawn.global_position
		intro = preload("res://scripts/world/intro_wake.gd").new()
		add_child(intro)
		crafting_panel.set_process_unhandled_input(false)
		intro.finished.connect(func() -> void: crafting_panel.set_process_unhandled_input(true))
		intro.start.call_deferred(player, [$HUD/Interface])
	hud_title.text = "FLORESTA DO DESPERTAR"
	_update_hud()
	for area in $Exits.get_children(): area.body_entered.connect(_on_exit_entered.bind(area.name))
	_setup_ecosystem()
	_add_ground_detail()
	preload("res://scripts/world/ground_art.gd").apply(self, [$VegetationHigh, $ExpandedForest], func(at: Vector2) -> bool: return Forest.open_area(at))
	if $Ground.material is ShaderMaterial:
		$Ground.material.set_shader_parameter("grass_soften", 1.0)  # grama mais leve e menos repetida (ref. V9)
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
	var pond_magic := preload("res://scripts/world/pond_magic.gd").new()
	pond_magic.setup($NaturalSpring, $Decorations)
	$NaturalSpring.add_child(pond_magic)
	var art := preload("res://scripts/world/map_art_enrichment.gd").new()
	art.region_kind = "forest"
	add_child(art)
	_spawn_seed_patches()
	_spawn_forage.call_deferred()
	# Árvores cortáveis (CRIACAO.md): nunca em habitats de slimes nem pontos de interesse.
	choppable = preload("res://scripts/world/choppable_trees.gd").new()
	add_child(choppable)
	choppable.setup([$VegetationHigh, $ExpandedForest], func(at: Vector2) -> bool:
		for h in Forest.habitats():
			if at.distance_to(h.center) < float(h.radius) + 80.0: return true
		for p in Forest.points_of_interest():
			if at.distance_to(p.at) < 160.0: return true
		return false)
	choppable.apply_day(GameClock.day_number)
	# Bancadas colocadas pelo jogador (CRIACAO.md, etapa 4).
	placer = preload("res://scripts/world/station_placer.gd").new()
	add_child(placer)
	var pond: Vector2 = $NaturalSpring.global_position
	placer.blocked = func(at: Vector2) -> bool: return at.distance_to(pond) < 150.0
	placer.setup(scene_file_path)
	GameClock.day_changed.connect(choppable.apply_day)

## Coleta manual na Clareira do Despertar (CRIACAO.md): fibra, graveto e pedra.
func _spawn_forage() -> void:
	await get_tree().physics_frame
	forage = preload("res://scripts/world/forage_spots.gd").new()
	$Decorations.add_child(forage)
	var space := get_world_2d().direct_space_state
	var probe := CircleShape2D.new()
	probe.radius = 12
	var pond: Vector2 = $NaturalSpring.global_position
	forage.setup(Forest.SPAWN, 70.0, 430.0, FORAGE_PLAN, func(at: Vector2) -> bool:
		if at.distance_to(pond) < 150.0: return false
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = probe
		query.transform = Transform2D(0, at)
		query.collision_mask = 2
		return space.intersect_shape(query, 1).is_empty())
	if is_instance_valid(ground_detail): forage.add_mato(ground_detail)
	forage.add_mato_tiles($VegetationLow, preload("res://assets/menu/environment/grass.png"))
	forage.refresh(GameClock.day_number)
	GameClock.day_changed.connect(forage.refresh)

func _spawn_seed_patches() -> void:
	for site in SEED_SITES:
		var patch = SEED_PATCH.new()
		patch.configure(str(site["id"]), site["at"])
		add_child(patch)
		seed_patches.append(patch)

func _nearest_seed_patch() -> Node2D:
	var nearest: Node2D = null
	var max_distance := 78.0
	for patch in seed_patches:
		if not is_instance_valid(patch) or bool(patch.get("collected")):
			continue
		var distance := player.global_position.distance_to(patch.global_position)
		if distance < max_distance:
			nearest = patch
			max_distance = distance
	return nearest

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

## V6: detalhe de chão por terreno em toda a Clareira (área vazia = Clareira inteira).
func _add_ground_detail() -> void:
	var detail := preload("res://scripts/world/ground_detail.gd").new()
	for tree in $VegetationHigh.get_children():
		if tree is Node2D and tree.visible: detail.tree_feet.append((tree as Node2D).position)
	detail.wind_material = ecosystem.get_wind_material("plant")
	detail.bush_parent = $Decorations
	var pond := $NaturalSpring as Node2D
	detail.avoid.append({"center": pond.global_position - detail.position, "radius": Vector2(86, 46)})
	detail.build()
	add_child(detail)
	ground_detail = detail

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
	if is_instance_valid(_spawn_light): _spawn_light.apply_time(GameClock.get_hour() * 60.0 + GameClock.get_minute(), delta)
	# The base world manages interaction/friendship; skip legacy map exit coordinates.
	var water_time: float = ecosystem.shared_wind_material.get_shader_parameter("wind_time")
	if water_time != _last_water_time:
		_last_water_time = water_time
		$SouthernBrook/Water.material.set_shader_parameter("elapsed",water_time)
		var night := preload("res://scripts/world/ambient_lights.gd").night_factor(GameClock.get_hour() * 60.0 + GameClock.get_minute())
		for water_material: ShaderMaterial in [$NaturalSpring/Pool/Water.material, $SouthernBrook/Water.material]:
			water_material.set_shader_parameter("elapsed", water_time)
			water_material.set_shader_parameter("night", night)
	var zone_name := Forest.zone(player.position)
	if zone_name != _last_zone:
		_last_zone = zone_name
		hud_title.text = zone_name.to_upper()
	if message_time > 0:
		message_time -= delta
		if message_time <= 0: popup.text = ""
	if is_instance_valid(intro):  # despertar em andamento: nada de interações
		hud_hint.text = ""
		return
	if is_instance_valid(crafting_panel) and crafting_panel.visible:
		hud_hint.text = ""
		return
	if is_instance_valid(placer):
		var station_hint: String = placer.update(player, Input.is_action_just_pressed("interact"), func() -> void: crafting_panel.open("bancada"))
		if station_hint == "placed":
			bag_hud.call("refresh")
			_notify("Bancada de trabalho montada! Use [E] nela para fabricar ferramentas.")
			return
		if not station_hint.is_empty():
			hud_hint.text = station_hint
			return
	var closest := _closest_slime()
	if closest != null:
		hud_hint.text = ("[E] Fazer amizade com " if not closest.befriended else "[E] Cumprimentar ") + closest.display_name() + "   [F] Dar comida (item da barra)"
		if Input.is_action_just_pressed("feed"):
			_offer_prototype_food(closest)
			return
		if Input.is_action_just_pressed("interact"):
			if not closest.befriended:
				closest.make_friend()
				_update_hud()
			_notify(closest.display_name()+" parece feliz com sua visita.")
		return
	var seeds := _nearest_seed_patch()
	if seeds != null:
		hud_hint.text = "[E] Recolher sementes com ajuda do Brotinho" if BAG.has_brotinho_friend(get_tree()) else "Conheça um Brotinho para aprender a recolher estas sementes"
		if Input.is_action_just_pressed("interact"):
			if bool(seeds.call("harvest")):
				bag_hud.call("refresh")
				_notify("Sementes silvestres guardadas na bolsa. Brotinho ajudou na coleta!")
			else:
				_notify("Primeiro, faça amizade com um Brotinho da floresta.")
		return
	# Machado na mão e árvore ao alcance: cortar vem antes de arrancar o mato em volta.
	if is_instance_valid(choppable) and HOTBAR.selected_item(get_tree()) == "machado" and _axe_interaction():
		_pull_id = ""
		return
	if is_instance_valid(forage):
		var spot: Dictionary = forage.nearest(player.global_position, GameClock.day_number)
		if not spot.is_empty():
			var item_name := str(ITEMS.info(spot.item).name).to_lower()
			var hold: float = forage.pull_seconds(spot.item)
			if hold > 0.0:
				# Mato: segurar [E] até arrancar; soltar ou sair de perto recomeça.
				if Input.is_action_just_pressed("interact"):
					_pull_id = spot.id
					_pull_time = 0.0
				elif Input.is_action_pressed("interact") and _pull_id == spot.id:
					_pull_time += delta
				else:
					_pull_id = ""
				if _pull_id != spot.id:
					hud_hint.text = "[Segure E] Arrancar o mato (%d s)" % int(hold)
					return
				player.hold_still(0.1)
				hud_hint.text = "Arrancando o mato... %d%%" % mini(99, int(_pull_time / hold * 100.0))
				if _pull_time < hold: return
				_pull_id = ""
			else:
				hud_hint.text = "[E] Pegar " + item_name
				if not Input.is_action_just_pressed("interact"): return
			var problem: String = forage.take(spot, GameClock.day_number)
			bag_hud.call("refresh")
			_notify(problem if not problem.is_empty() else "Você pegou %s." % item_name)
			return
		_pull_id = ""
	if is_instance_valid(choppable) and _axe_interaction():
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

## Machado na mão perto de árvore comum ou tronco caído: golpe com [E].
func _axe_interaction() -> bool:
	var t: Dictionary = choppable.target(player.global_position)
	if t.is_empty() or BAG.count_item(get_tree(), "machado") <= 0:
		return false
	if HOTBAR.selected_item(get_tree()) != "machado":
		hud_hint.text = "Selecione o machado na barra para " + ("cortar a árvore" if t.kind == "tree" else "processar o tronco")
		return true
	var total: int = choppable.HITS_TO_FELL if t.kind == "tree" else choppable.HITS_TO_PROCESS
	hud_hint.text = "[E] %s (%d/%d)" % ["Cortar árvore" if t.kind == "tree" else "Processar tronco em madeira", choppable.hits(t.key), total]
	if Input.is_action_just_pressed("interact") and not player.is_using_tool():
		if not ENERGY.spend(get_tree(), "chop" if t.kind == "tree" else "process"):
			_notify("Cansada demais para isso. Durma para recuperar a energia.")
			return true
		player.play_tool("axe")
		match choppable.strike(t, GameClock.day_number):
			"felled": _notify("A árvore caiu! Processe o tronco com o machado.")
			"processed":
				bag_hud.call("refresh")
				_notify("Você conseguiu %d madeiras." % choppable.WOOD_PER_LOG)
	return true

func _offer_prototype_food(slime: Node2D) -> void:
	# [F] dá ao slime a comida selecionada na barra (colheita ou porção cozida).
	var item: String = HOTBAR.selected_item(get_tree())
	if FEEDING.is_food(item):
		var fed: String = FEEDING.feed(get_tree(), str(slime.get("persistent_id")), bool(slime.get("befriended")), item, GameClock.day_number)
		if item == COOKING.RECIPE_ID and fed == "fed":
			FOOD.offer(get_tree(), str(slime.get("persistent_id")), true)  # registro da primeira porção
		match fed:
			"fed":
				slime.set("_happy_time", 2.4)
				var hearts := FEEDING.hearts(get_tree(), str(slime.get("persistent_id")))
				_notify("%s comeu %s! Laço: %d/%d corações." % [slime.display_name(), str(ITEMS.info(item).name).to_lower(), hearts, FEEDING.MAX_HEARTS])
			"needs_friendship": _notify("Primeiro conheça este slime usando E.")
			"already_fed": _notify(slime.display_name() + " já comeu hoje.")
			_: _notify("Você não tem " + str(ITEMS.info(item).name).to_lower() + ".")
		return
	var result: String = FOOD.offer(get_tree(), str(slime.get("persistent_id")), bool(slime.get("befriended")))
	match result:
		"offered":
			bag_hud.call("refresh")
			slime.set("_happy_time", 2.4)
			_notify("Uma porcao de teste foi oferecida a " + slime.display_name() + ".")
		"needs_friendship":
			_notify("Primeiro conheca este slime usando E.")
		"already_offered":
			_notify("Este slime ja recebeu uma porcao nesta partida.")
		"needs_portion":
			_notify("Cozinhe folhas frescas no Vale antes de oferecer comida.")
		_:
			_notify("Nao foi possivel oferecer a porcao; nenhum alimento foi gasto.")

func _update_hud() -> void:
	if hud_goal == null: return
	# Count identities rather than spawn events: a restored friend remains one friend.
	friends_count = 0
	for befriended in get_tree().get_meta("forest_slime_friends",{}).values():
		if befriended: friends_count += 1
	# Sem missões no HUD: a amizade continua contando, mas não vira objetivo na tela.

func _on_exit_entered(body: Node2D, exit_name: StringName) -> void:
	if body != player or _visited_exits.has(exit_name): return
	_visited_exits[exit_name] = true
	var messages := {"North":"A Mata Antiga segue pelas colinas. Explore os caminhos ao redor.","East":"O Refúgio Verde se espalha pelos bosques floridos.","South":"Vale das Nascentes · pressione E para seguir pelas águas."}
	_notify(messages[str(exit_name)])

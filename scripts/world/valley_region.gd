extends "res://scripts/world/clearing_region.gd"
const Valley = preload("res://scripts/world/valley_layout.gd")
const Travel = preload("res://scripts/world/region_travel.gd")
const Living = preload("res://scripts/world/living_region.gd")
const BAG_HUD := preload("res://scripts/ui/forest_bag_hud.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const FOOD := preload("res://scripts/systems/slime_food_session.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
## Placa do caminho para a fazenda, a leste da chegada da Floresta.
const RECIPE_PANEL := preload("res://scripts/ui/valley_recipe_panel.gd")
const FEEDING := preload("res://scripts/systems/slime_feeding.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
var ecosystem: Node2D
var habitat_manager: Node2D
var environmental_audio: Node2D
var elapsed := 0.0
var reduce_motion := false
var found_zones: Dictionary = {}
var bag_hud: Node
var crafting_panel: Control  # [B] fabricar (como na Floresta)
var placer: Node2D  # bancadas colocadas pelo jogador (como na Floresta)
var gathering: Node  # region_gathering.gd: corte e coleta (como na Floresta)
var house: Node2D  # casa do jogador ([B] construir; uma só no jogo)
var farm: Node2D  # plantio livre: arar com a enxada em qualquer chão livre
var recipe_panel: PanelContainer

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	y_sort_enabled = true
	add_child(PauseOverlay.new())
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
	crafting_panel = preload("res://scripts/ui/crafting_panel.gd").new()
	crafting_panel.player = player
	$HUD/Interface.add_child(crafting_panel)
	crafting_panel.crafted.connect(func(_id: String) -> void: bag_hud.call("refresh"))
	add_inventory_panel()
	add_tutorial()
	recipe_panel = RECIPE_PANEL.new()
	$HUD/Interface.add_child(recipe_panel)
	hud_title.text = "VALE DAS NASCENTES"
	found_zones = get_tree().get_meta("valley_discoveries",{}).duplicate()
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
	preload("res://scripts/world/ground_art.gd").apply(self, [$TreesBack, $TreesFront], Callable(), 1)
	# Vale à noite: chão mais escuro (ref. V11 da ponte) para a água se destacar.
	for node in [$Ground, get_node_or_null("WaterBankTiles")] + $Elevations.get_children():
		if node is CanvasItem and node.material is ShaderMaterial:
			node.material.set_shader_parameter("night_value", VALLEY_NIGHT_GROUND)
			node.material.set_shader_parameter("night_tint", VALLEY_NIGHT_TINT)
	if $Ground.material is ShaderMaterial:
		$Ground.material.set_shader_parameter("night_forest_lift", 1.0)  # mata sob as árvores sem bloco preto
	_lanterns = preload("res://scripts/world/lantern_flowers.gd").new()
	var bridge_rects: Array[Rect2] = []
	for bridge in $Bridges.get_children():
		var frame := bridge.get_node_or_null("Frame") as Polygon2D
		if frame == null: continue
		var box := Rect2(frame.polygon[0], Vector2.ZERO)
		for point in frame.polygon: box = box.expand(point)
		bridge_rects.append(Rect2(frame.global_transform * box.position, box.size))
	_lanterns.setup(bridge_rects, $Decorations)
	# Mundo sem humanos: travessias naturais no lugar das pontes de tábuas.
	_natural_bridges = preload("res://scripts/world/natural_bridges.gd").apply($Bridges)
	_tree_glow = preload("res://scripts/world/tree_glow.gd").new()
	_tree_glow.setup([$TreesBack, $TreesFront], preload("res://scripts/world/valley_layout.gd").BRIDGES)
	add_child(_tree_glow)
	var flora := preload("res://scripts/world/river_flora.gd").new()
	var waters: Array = $Water.get_children().filter(func(n): return n is Polygon2D)
	flora.setup(waters, preload("res://scripts/world/valley_layout.gd").BRIDGES, $Decorations, $WaterDecorations)
	add_child(flora)
	add_child(_lanterns)  # árvores esparsas: sombra de mata sob cada uma
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
	_setup_gathering()
	placer = preload("res://scripts/world/station_placer.gd").new()
	add_child(placer)
	placer.blocked = func(_at: Vector2) -> bool: return false  # colisão (água, árvores) já bloqueia
	placer.setup(scene_file_path)
	house = add_player_house("vale")
	farm = add_free_farm("vale", house)
	hide_forage_on_farm(farm, gathering.forage)
	add_item_drops(farm, gathering)

func _on_water_slime(slime: Node2D) -> void:
	slimes.append(slime)
	ecosystem.register_reactor(slime)
	slime.tree_exiting.connect(func(): slimes.erase(slime))
	_update_living_goal()

func _offer_prototype_food(slime: Node2D) -> void:
	# [F] dá ao slime a comida selecionada na barra (colheita ou porção cozida).
	var item: String = HOTBAR.selected_item(get_tree())
	if FEEDING.is_food(item):
		var fed: String = FEEDING.feed(get_tree(), str(slime.get("persistent_id")), bool(slime.get("befriended")), item, GameClock.day_number, str(slime.get("slime_type")))
		if item == COOKING.RECIPE_ID and fed == "fed":
			FOOD.offer(get_tree(), str(slime.get("persistent_id")), true, false)  # só registra a primeira porção
		match fed:
			"fed":
				if slime.has_method("react"): slime.call("react", "comer")
				else: slime.set("_happy_time", 2.4)
				var hearts := FEEDING.hearts(get_tree(), str(slime.get("persistent_id")))
				_notify("%s comeu %s! Laço: %d/%d corações." % [slime.display_name(), str(ITEMS.info(item).name).to_lower(), hearts, FEEDING.MAX_HEARTS])
			"needs_friendship": _notify("Primeiro conheça este slime usando F.")
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
			_notify("Primeiro conheca este slime usando F.")
		"already_offered":
			_notify("Este slime ja recebeu uma porcao nesta partida.")
		"needs_portion":
			_notify("Cozinhe folhas frescas no Vale antes de oferecer comida.")
		_:
			_notify("Nao foi possivel oferecer a porcao; nenhum alimento foi gasto.")

## Corte e coleta no Vale: árvores de TreesBack/TreesFront e o mato de
## LowVegetation (ids e estado com prefixo "vale_"). Sem corte nos habitats de
## slimes, pontos de interesse e chegada.
func _setup_gathering() -> void:
	var keep: Array[Vector2] = [Valley.SPAWN, Vector2(1600, 70)]
	for marker in $PointsOfInterest.get_children(): keep.append((marker as Node2D).position)
	gathering = preload("res://scripts/world/region_gathering.gd").new()
	add_child(gathering)
	gathering.setup(self, [$TreesBack, $TreesFront], func(at: Vector2) -> bool:
		for h in Valley.HABITATS:
			if at.distance_to(h) < 130.0 + 80.0: return true
		for k in keep:
			if at.distance_to(k) < 140.0: return true
		return false, "vale_", self)
	gathering.forage.add_mato_props($LowVegetation, "vale_")
	_spawn_valley_forage.call_deferred()

## Gravetos e pedras pequenas em volta da chegada do Vale (chão livre, longe da água).
func _spawn_valley_forage() -> void:
	await get_tree().physics_frame
	var space := get_world_2d().direct_space_state
	var probe := CircleShape2D.new()
	probe.radius = 12
	var pools: Array[Polygon2D] = []
	for polygon in $Water.get_children():
		if polygon is Polygon2D: pools.append(polygon)
	var free_at := func(at: Vector2) -> bool:
		for pool in pools:  # nada dentro da água (nem a 20 px da margem)
			for nudge in [Vector2.ZERO, Vector2(20, 0), Vector2(-20, 0), Vector2(0, 20), Vector2(0, -20)]:
				if Geometry2D.is_point_in_polygon(pool.to_local(at + nudge), pool.polygon): return false
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = probe
		query.transform = Transform2D(0, at)
		query.collision_mask = 2
		return space.intersect_shape(query, 1).is_empty()
	gathering.forage.setup(Valley.SPAWN, 90.0, 700.0, {"graveto": 5, "pedra_pequena": 6}, free_at, "vale_")
	# Recursos básicos e pedras pelo Vale todo (pedido do usuário).
	gathering.forage.setup(Valley.SIZE * 0.5, 300.0, 1550.0, {"graveto": 30, "pedra_pequena": 30}, free_at, "vale_w_", 140.0)
	gathering.forage.refresh(GameClock.day_number)
	var routes := Valley.routes()  # pedra não tranca caminho
	gathering.add_rocks(self, Rect2(Vector2(80, 80), Valley.SIZE - Vector2(160, 160)), {"medium": 18, "large": 6}, func(at: Vector2) -> bool:
		for center: Vector2 in Valley.HABITATS:  # margem dos slimes aquáticos fica livre
			if at.distance_to(center) < 190.0: return false
		return at.distance_to(Valley.SPAWN) > 240.0 and Valley.route_distance(at, routes) > 60.0 and free_at.call(at), "vale_")
	if is_instance_valid(item_drops) and is_instance_valid(gathering.rocks): gathering.rocks.drop = Callable(item_drops, "spawn")

## Bancada no Vale (como na Floresta): prévia/colocar com ela na barra; [F] nela abre
## a fabricação da bancada.
func _handle_station() -> bool:
	if not is_instance_valid(placer): return false
	var station_hint: String = placer.update(player, Input.is_action_just_pressed("interact"), func() -> void: crafting_panel.open("bancada"))
	if station_hint == "placed":
		bag_hud.call("refresh")
		_notify("Bancada de trabalho montada! Use [F] nela para fabricar ferramentas.")
		return true
	if station_hint.is_empty(): return false
	hud_hint.text = station_hint
	return true

func _update_living_goal() -> void:
	friends_count = 0
	for friend in get_tree().get_meta("valley_slime_friends",{}).values():
		if friend: friends_count += 1
	# Sem missões no HUD: amizades e recantos continuam registrados, sem objetivo na tela.

func set_environment_conditions(period: String, rain: float=0.0, wind: float=1.0, fog: float=0.0) -> void:
	Living.conditions(self,period,rain,wind,fog)

func _process(delta: float) -> void:
	elapsed += delta
	if message_time > 0:
		message_time -= delta
		if message_time <= 0: popup.text = ""
	if is_instance_valid(recipe_panel):
		recipe_panel.hide()
	hud_hint.text = "WASD / Setas: andar   •   Shift: correr   •   F: observar   •   B: construir casa"
	if window_open():
		hud_hint.text = ""
	elif _handle_station():
		pass  # bancada: prévia/colocar ou [F] fabricar
	elif handle_player_house(house):
		pass  # casa: modo construir ou dormir na cama
	elif player.position.distance_to(Vector2(1600,70)) < 100:
		hud_hint.text = "[F] Voltar à Floresta do Despertar"
		if Input.is_action_just_pressed("interact"):
			Travel.travel(self,Travel.CLEARING,"clearing_south")
			return
	elif player.position.distance_to(Vector2(1780,3160)) < 100:
		hud_hint.text = "[F] Observar o caminho ao sul"
		if Input.is_action_just_pressed("interact"):
			_notify("O caminho segue pela ilha. Uma nova região chegará em breve.")
	else:
		if not handle_farming(farm):
			var closest := _closest_slime()
			if closest == null and is_instance_valid(gathering) and gathering.update(delta):
				pass  # cortar árvore / arrancar mato
			elif closest != null:
				var food := slime_food_hint(closest)
				hud_hint.text = food if not food.is_empty() else ("[F] Fazer amizade com " if not closest.befriended else "[F] Cumprimentar ") + closest.display_name()
				if not food.is_empty() and Input.is_action_just_pressed("interact"):
					_offer_prototype_food(closest)
				elif Input.is_action_just_pressed("interact"):
					closest.make_friend()
					_update_living_goal()
					if closest.has_method("react"): closest.call("react", "receber_carinho")
					var hearts := FEEDING.hearts(get_tree(), str(closest.get("persistent_id")))
					_notify("%s salta e espalha pequenas gotas de alegria. Laço: %d/%d corações." % [closest.display_name(), hearts, FEEDING.MAX_HEARTS])
			else:
				for marker: Marker2D in $PointsOfInterest.get_children():
					if player.position.distance_to(marker.position)<90:
						hud_hint.text = "[F] " + str(marker.get_meta("label"))
						if Input.is_action_just_pressed("interact"):
							_notify(marker.get_meta("description"))
							found_zones[marker.name] = true
							_update_living_goal()
						break
				if hud_hint.text.begins_with("WASD") and Input.is_action_just_pressed("interact"):
					eat_selected()  # [F] sem nada por perto: come a comida da barra
	var water_night := preload("res://scripts/world/ambient_lights.gd").night_factor(GameClock.get_hour() * 60.0 + GameClock.get_minute())
	if is_instance_valid(_lanterns): _lanterns.apply_time(water_night, get_process_delta_time())
	if is_instance_valid(_tree_glow): _tree_glow.apply_time(water_night, elapsed)
	if has_node("WaterBankTiles"):
		$WaterBankTiles.material.set_shader_parameter("night_dim", water_night)
	for level in $Elevations.get_children():
		if level is CanvasItem and level.material is ShaderMaterial:
			level.material.set_shader_parameter("night_dim", water_night)
	# Copas e arbustos: mais escuros e frios à noite (ref. V11). Fontes mágicas
	# são aditivas e não escurecem.
	var foliage_night := Color(1, 1, 1).lerp(VALLEY_NIGHT_FOLIAGE, water_night)
	for group in [$TreesBack, $TreesFront, $LowVegetation]:
		(group as CanvasItem).modulate = foliage_night
	# Pontes naturais (tronco, pedras, raízes, istmo): mesma noite fria da vegetação.
	for natural in $Bridges.get_children():
		if natural.name.begins_with("Natural") or natural.name.begins_with("BridgeTuft"): (natural as CanvasItem).modulate = foliage_night
	for fall in $Waterfalls.get_children():
		var cascade := fall.get_node_or_null("Cascade") as CanvasItem
		if cascade and cascade.material is ShaderMaterial:
			cascade.material.set_shader_parameter("night", water_night)
	for water in $Water.get_children():
		if water is Polygon2D and water.material is ShaderMaterial:
			water.material.set_shader_parameter("night", water_night)
	if not reduce_motion:
		for water in $Water.get_children():
			if water is Polygon2D and water.material is ShaderMaterial:
				water.material.set_shader_parameter("elapsed",floor(elapsed*8)/8)
		if has_node("WaterBankTiles"):
			$WaterBankTiles.material.set_shader_parameter("elapsed",floor(elapsed*8)/8)
		for fall: Node2D in $Waterfalls.get_children():
			fall.get_node("Cascade").material.set_shader_parameter("elapsed",floor(elapsed*8)/8)


var _lanterns: Node2D  # plantas-lanterna nas pontes
var _tree_glow: Node  # árvores encantadas (tronco quente e vagalumes)
var _natural_bridges: Array[Sprite2D] = []
const VALLEY_NIGHT_GROUND := 0.55
const VALLEY_NIGHT_TINT := Vector3(0.5, 1.0, 1.35)  # azul-petróleo (ref. V11)
const VALLEY_NIGHT_FOLIAGE := Color(0.66, 0.9, 0.98)

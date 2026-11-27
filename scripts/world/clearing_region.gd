extends "res://scripts/world.gd"
## The editable map is baked in ClareiraDoDespertar.tscn. Reuse existing friendship/HUD.
const PauseOverlay := preload("res://scripts/ui/pause_overlay.gd")
const Layout = preload("res://scripts/world/clearing_layout.gd")
var _visited_exits: Dictionary = {}
var speech: Control  ## balão de fala contextual (ID 48)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	y_sort_enabled = true
	add_child(PauseOverlay.new())
	player = $Player
	player.position = $SpawnPoints/PlayerSpawn.position
	player.world_bounds = Rect2(Vector2(24, 44), Layout.WORLD_SIZE - Vector2(48, 68))
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(Layout.WORLD_SIZE.x)
	camera.limit_bottom = int(Layout.WORLD_SIZE.y)
	camera.reset_smoothing()
	for i in Layout.SLIME_POSITIONS.size():
		_spawn_slime(["gelito", "brotinho", "brasinha"][i], Layout.SLIME_POSITIONS[i])
	_create_hud()
	_compact_hud()
	hud_title.text = "CLAREIRA DO DESPERTAR"
	_update_hud()
	for exit_area: Area2D in $Exits.get_children():
		exit_area.body_entered.connect(_on_exit_entered.bind(exit_area.name))
	preload("res://scripts/world/region_travel.gd").restore_clearing(self)

func _process(delta: float) -> void:
	super._process(delta)
	if player.position.distance_to(Vector2(1610,3120)) < 110:
		hud_hint.text = "[F] Viajar para o Vale das Nascentes"
		if Input.is_action_just_pressed("interact"):
			var travel = preload("res://scripts/world/region_travel.gd")
			travel.travel(self,travel.VALLEY,"valley_north")
			return
	var spring := get_node_or_null("NaturalSpring")
	if spring != null and _closest_slime() == null and spring.can_examine(player.global_position):
		hud_hint.text = "[F] Examinar lago"
		if Input.is_action_just_pressed("interact"):
			_notify("Um pequeno lago de água cristalina repousa entre as árvores.")

func _on_exit_entered(body: Node2D, exit_name: StringName) -> void:
	if body != player or _visited_exits.has(exit_name):
		return
	_visited_exits[exit_name] = true
	var messages := {
		"North": "Trilha das montanhas · esta região chegará em uma próxima etapa.",
		"East": "Trilha dos slimes · mais descobertas chegarão em uma próxima etapa.",
		"South": "Vale das Nascentes · pressione E para seguir pelas águas."
	}
	_notify(messages[exit_name])

func _update_hud() -> void:
	# Sem missões: o jogo é livre (cultivar, explorar, fazer amizades no seu ritmo).
	pass

func _compact_hud() -> void:
	var panel: PanelContainer = $HUD/Interface/MissionPanel
	# Nome do lugar no alto, ao centro: o canto esquerdo é do retrato e das barras.
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_bottom = 16
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.set_content_margin_all(6)
	style.content_margin_left = 9
	style.content_margin_right = 9
	panel.add_theme_stylebox_override("panel",style)
	hud_title.add_theme_font_size_override("font_size",15)
	hud_goal.add_theme_font_size_override("font_size",13)
	# O painel encolhe até o texto: sem quebra automática (senão vira uma coluna).
	hud_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	hud_goal.autowrap_mode = TextServer.AUTOWRAP_OFF
	# Linha de objetivos removida: o painel mostra só o nome do lugar.
	hud_goal.hide()
	# Painéis ficam translúcidos quando o jogador passa por baixo deles.
	var fade := preload("res://scripts/ui/hud_overlap_fade.gd").new()
	fade.name = "HudOverlapFade"
	fade.target = player
	$HUD/Interface.add_child(fade)
	# Barra rápida de itens embaixo, no lugar da linha de teclas; mostra a ação
	# disponível ([F] ...) no título quando houver.
	var hotbar := preload("res://scripts/ui/hotbar_hud.gd").new()
	hotbar.hint_source = hud_hint
	$HUD/Interface.add_child(hotbar)
	# Nome do lugar só na chegada, depois some (menos poluição na tela).
	var title_fade := create_tween()
	title_fade.tween_interval(3.0)
	title_fade.tween_property(panel, "modulate:a", 0.0, 0.8)
	title_fade.tween_callback(panel.hide)
	# ADMIN (remover): comandos de teste em [F1], só em build de depuração.
	# Ver scripts/debug/admin_commands.gd para remover tudo antes de lançar.
	if OS.is_debug_build():
		var admin: Node = preload("res://scripts/debug/admin_commands.gd").new()
		admin.set("region", self)
		add_child(admin)
	# /ADMIN (remover)
	# Retrato, vida e energia no canto (e o outro jogador abaixo no multijogador).
	$HUD/Interface.add_child(preload("res://scripts/ui/player_status_hud.gd").new())
	speech = preload("res://scripts/ui/speech_bubble.gd").new()  # balões contextuais (ID 48)
	speech.region = self
	$HUD/Interface.add_child(speech)
	# Slime por perto: retrato, nome e corações do laço (exemplo de HUD do usuário).
	# Multijogador: mostra o outro jogador e envia a posição deste (net_presence.gd).
	var presence := preload("res://scripts/net/net_presence.gd").new()
	presence.player = player
	add_child(presence)
	var world_sync := preload("res://scripts/net/net_world.gd").new()  # fazenda, coleta, pedras e árvores
	world_sync.region = self
	add_child(world_sync)
	var sleep_sync := preload("res://scripts/net/net_sleep.gd").new()  # o dia vira quando todos dormem (ID 35)
	sleep_sync.region = self
	add_child(sleep_sync)
	var bond := preload("res://scripts/ui/slime_bond_hud.gd").new()
	bond.source = _closest_slime
	$HUD/Interface.add_child(bond)
	var hint: PanelContainer = $HUD/Interface/InteractionHint
	hint.hide()  # tutorial de teclas removido; ações aparecem na barra de itens
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.offset_left = -292
	hint.offset_right = 292
	hint.offset_top = -44
	hint.offset_bottom = -12
	var hint_style := hint.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	hint_style.set_content_margin_all(7)
	hint.add_theme_stylebox_override("panel",hint_style)
	hud_hint.add_theme_font_size_override("font_size",14)
	# Abaixo dos pés, acima da barra: no alto (90 px) o aviso "+1 graveto" ficava atrás do
	# balão da dica, que fica sobre a cabeça (benchmark 2026-11-27).
	popup.offset_top = 320
	popup.offset_bottom = 368
	popup.add_theme_font_size_override("font_size",18)


## Casa construída pelo jogador nesta região (CASA.md): sem casa inicial; [B] abre a
## fabricação e o botão "Construir casa" entra no modo construir em qualquer lugar
## livre do mapa (não sobre árvore, pedra ou água).
func add_player_house(region_id: String) -> Node2D:
	var builder: Node2D = preload("res://scripts/world/house_builder.gd").new()
	builder.player = player
	builder.region_id = region_id
	var space := get_world_2d().direct_space_state
	var box := RectangleShape2D.new()
	box.size = Vector2(28, 28)
	builder.blocked_world = func(cell: Vector2i) -> bool:
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = box
		query.transform = Transform2D(0, Vector2(cell * 32) + Vector2(16, 16))
		query.collision_mask = 2
		query.exclude = [builder.get_node("HouseCollision").get_rid()]
		return not space.intersect_shape(query, 1).is_empty()
	builder.footprint_changed.connect(_clear_under_house)
	add_child(builder)
	_player_house = builder
	var panel: Variant = get("crafting_panel")
	if panel is Node and is_instance_valid(panel):
		panel.set("builder", builder)
		panel.set("placer", get("placer"))  # bancada/baú: a fabricação abre a prévia da planta
	if not GameClock.time_changed.is_connected(_on_time_for_faint):
		GameClock.time_changed.connect(_on_time_for_faint)
	if not GameClock.time_changed.is_connected(_on_time_for_autosave):
		GameClock.time_changed.connect(_on_time_for_autosave)
	var tired := Timer.new()  # exaustão (ID 35): as regiões não chamam o _process da base
	tired.name = "ExhaustionCheck"
	tired.wait_time = 0.25
	tired.autostart = true
	tired.timeout.connect(_check_exhaustion)
	add_child(tired)
	return builder


var _player_house: Node2D
const FAINT_HOUR := 0  # meia-noite (BACKLOG P2)
const FAINT_ENERGY := 50


func _exit_tree() -> void:
	if GameClock.time_changed.is_connected(_on_time_for_faint):
		GameClock.time_changed.disconnect(_on_time_for_faint)
	if GameClock.time_changed.is_connected(_on_time_for_autosave):
		GameClock.time_changed.disconnect(_on_time_for_autosave)


## Autosave a cada amanhecer (relatório de playtest ID 57): uma vez por dia, a partir das
## 06:00, depois da virada e da reposição do dia. Independe de ter cama.
const AUTOSAVE_HOUR := 6
const AUTOSAVE_KEY := "autosave_day"


func _on_time_for_autosave(day: int, hour: int, _minute: int) -> void:
	if hour < AUTOSAVE_HOUR or not is_inside_tree(): return
	if int(get_tree().get_meta(AUTOSAVE_KEY, -1)) == day: return
	get_tree().set_meta(AUTOSAVE_KEY, day)  # antes de gravar: o save já sai com o dia marcado
	if preload("res://scripts/systems/save_game.gd").save(get_tree(), GameClock, scene_file_path):
		_notify("Jogo salvo (dia %d)." % day)


## Acordado depois da meia-noite: desmaia e acorda às 06:00 ao lado da cama (se a
## casa estiver nesta região), com metade da energia. Dormir na cama evita.
func _on_time_for_faint(_day: int, hour: int, _minute: int) -> void:
	if hour < FAINT_HOUR or hour >= 6 or not is_inside_tree(): return
	var net := get_node_or_null("NetSleep")
	if net != null and bool(net.get("sleeping")): return  # já dormindo, esperando o parceiro
	faint()


## Exaustão (relatório de playtest ID 35): insistiu em ações sem energia → dorme onde está,
## acorda às 06:00 do dia seguinte com metade da energia. Não pede energia para dormir.
## No multijogador dorme no lugar enquanto o parceiro joga; o dia vira quando os dois
## dormirem (scripts/net/net_sleep.gd).
func _check_exhaustion() -> void:
	if not is_inside_tree() or not preload("res://scripts/systems/energy_state.gd").exhausted(get_tree()): return
	exhausted_sleep()


func exhausted_sleep() -> void:
	if _net_sleep_waits(true): return
	var minutes := GameClock.get_hour() * 60.0 + GameClock.get_minute()
	var until := 360.0 - minutes if minutes < 360.0 else (1440.0 - minutes) + 360.0  # próximas 06:00
	GameClock.advance_minutes(until)
	wake_up(true)


## Multijogador: entrega o pedido ao NetSleep (espera os outros). false = modo solo.
func _net_sleep_waits(forced: bool) -> bool:
	var net := get_node_or_null("NetSleep")
	return net != null and bool(net.call("request", forced))


## Acordou: na cama, energia cheia e salva; exausto, metade da energia.
func wake_up(forced: bool) -> void:
	if forced:
		preload("res://scripts/systems/energy_state.gd").wake_from_forced_sleep(get_tree())
		_notify("Sem forças, você dormiu ali mesmo e acordou com metade da energia.")
		return
	preload("res://scripts/systems/energy_state.gd").restore(get_tree())
	var saved: bool = preload("res://scripts/systems/save_game.gd").save(get_tree(), GameClock, scene_file_path)
	_notify("Bom dia! Dia %d." % GameClock.day_number + ("  Jogo salvo." if saved else ""))


func faint() -> void:
	var minutes := GameClock.get_hour() * 60.0 + GameClock.get_minute()
	GameClock.advance_minutes(360.0 - minutes)  # até 06:00 (já passou da meia-noite)
	preload("res://scripts/systems/energy_state.gd").wake_from_forced_sleep(get_tree())  # 50%
	var bed := _bed_position()
	if bed != Vector2.INF:
		player.global_position = bed
		_notify("Você desmaiou de cansaço e acordou em casa. Durma antes da meia-noite!")
	else:
		_notify("Você desmaiou de cansaço no meio do caminho... Construa uma casa com cama.")


## Ao lado (embaixo) da cama da casa desta região, ou INF se não houver.
func _bed_position() -> Vector2:
	if not is_instance_valid(_player_house): return Vector2.INF
	var furniture: Dictionary = _player_house.house().furniture
	for origin in furniture:
		if furniture[origin] == "cama":
			return Vector2((origin + Vector2i(1, 1)) * 32) + Vector2(16, 16)
	return Vector2.INF


var _house_hidden: Array = []  # [CanvasItem] escondidos sob a casa
var _house_tiles: Array = []  # [layer, cell, source, atlas, alternative] apagados


## Sob a casa não ficam mato, flores, gravetos nem itens coletáveis (voltam ao
## demolir). Árvores e pedras já impedem a construção (colisão).
const HOUSE_DECOR_GROUPS := ["Decorations", "WoodlandDetails", "FlowerClusters", "GroundDetail", "LowVegetation", "VegetationHigh"]
var _house_area := Rect2(-1, -1, 0, 0)


func _clear_under_house(area: Rect2) -> void:
	var gathering_node: Node = get("gathering")
	if is_instance_valid(gathering_node) and is_instance_valid(gathering_node.forage):
		gathering_node.forage.excluded = area
		gathering_node.forage.refresh(GameClock.day_number)  # coletáveis sob a casa somem
	if area == _house_area: return  # mobília mudou; a área da casa não
	_house_area = area
	for item: CanvasItem in _house_hidden:
		if is_instance_valid(item):
			item.visible = true
			item.process_mode = Node.PROCESS_MODE_INHERIT
	_house_hidden.clear()
	for t in _house_tiles:
		if is_instance_valid(t[0]): (t[0] as TileMapLayer).set_cell(t[1], t[2], t[3], t[4])
	_house_tiles.clear()
	if not area.has_area(): return
	var grown := area.grow(-2)
	for child in find_children("*", "", true, false):
		if child is TileMapLayer and str(child.name) in ["VegetationLow", "GroundDetails"]:
			var layer := child as TileMapLayer
			for cell in layer.get_used_cells():
				if grown.has_point(layer.to_global(layer.map_to_local(cell))):
					_house_tiles.append([layer, cell, layer.get_cell_source_id(cell), layer.get_cell_atlas_coords(cell), layer.get_cell_alternative_tile(cell)])
					layer.erase_cell(cell)
		elif child is Node2D and child.visible and str(child.get_parent().name) in HOUSE_DECOR_GROUPS:
			var node := child as Node2D  # decoração (mato, flores, gravetos, moitas, árvores)
			if not (node is Sprite2D or node.has_node("Sprite")): continue
			var at := node.global_position
			if node.has_node("Sprite"): at = (node.get_node("Sprite") as Node2D).global_position
			if grown.has_point(node.global_position) or grown.has_point(at):
				node.visible = false
				node.process_mode = Node.PROCESS_MODE_DISABLED  # sem colisão sob a casa
				_house_hidden.append(node)


var inventory_panel: Control
const INVENTORY_WINDOWS := preload("res://scripts/ui/inventory_panel.gd").WINDOWS


## Mochila ([E]): janela em grade dos 10 espaços (scripts/ui/inventory_panel.gd).
func add_inventory_panel() -> Control:
	inventory_panel = preload("res://scripts/ui/inventory_panel.gd").new()
	inventory_panel.player = player
	get_node("HUD/Interface").add_child(inventory_panel)
	inventory_panel.changed.connect(func() -> void:
		var bag_node: Node = get("bag_hud")
		if is_instance_valid(bag_node): bag_node.call("refresh"))
	return inventory_panel


## Balão de fala do personagem (scripts/ui/speech_bubble.gd); um por situação, com intervalo.
func say(situation: String, text: String) -> void:
	if is_instance_valid(speech): speech.say(situation, text)


## Dicas do tutorial inicial (scripts/ui/tutorial_hud.gd); some quando termina.
func add_tutorial() -> Control:
	var tutorial: Control = preload("res://scripts/ui/tutorial_hud.gd").new()
	tutorial.set("region", self)
	get_node("HUD/Interface").add_child(tutorial)
	return tutorial


## Alguma janela (mochila, fabricação, baú) aberta: o mundo não recebe [F] nem clique.
func window_open() -> bool:
	if not has_node("HUD/Interface"): return false
	if is_instance_valid(slime_disc) and slime_disc.visible: return true
	for child in get_node("HUD/Interface").get_children():
		if child is PanelContainer and child.visible and str(child.name) in INVENTORY_WINDOWS:
			return true
	return false


## Casa: modo construir ou dormir na cama. true quando tomou o HUD neste quadro.
func handle_player_house(builder: Node2D) -> bool:
	if not is_instance_valid(builder): return false
	if is_instance_valid(_chest_panel) and _chest_panel.visible:
		hud_hint.text = ""
		return true
	if not str(builder.message).is_empty():
		_notify(builder.message)
		builder.message = ""
	if builder.building:
		hud_hint.text = builder.build_hint()
		return true
	if builder.near_bed(player):
		hud_hint.text = "[F] Dormir até amanhã   •   [B] Fabricar e construir"
		if Input.is_action_just_pressed("interact"): sleep_until_morning()
		return true
	if builder.near_furniture(player, "bau"):
		hud_hint.text = "[F] Abrir o baú"
		if Input.is_action_just_pressed("interact"): open_chest()
		return true
	if builder.near_furniture(player, "fogao"):
		# Cozinhar no fogão da casa: janela de receitas (data/crafting/recipes.gd, "fogao").
		hud_hint.text = "[F] Cozinhar"
		var panel: Control = get("crafting_panel")
		if Input.is_action_just_pressed("interact") and is_instance_valid(panel): panel.call("open", "fogao")
		return true
	return false


## Dorme até 06:00 do dia seguinte: o dia vira, a energia volta cheia e o jogo salva.
## No multijogador espera todos dormirem; [F] de novo levanta (scripts/net/net_sleep.gd).
func sleep_until_morning() -> void:
	if _net_sleep_waits(false): return
	var minutes := GameClock.get_hour() * 60.0 + GameClock.get_minute()
	GameClock.advance_minutes((1440.0 - minutes) + 360.0)
	wake_up(false)


## Plantio livre (FAZENDA.md): com a enxada, ara qualquer chão livre da região (sem
## colisão — árvore, pedra, água, casa — e fora do piso da casa); planta, rega e colhe.
func add_free_farm(field_id: String, house_builder: Node2D) -> Node2D:
	var farm: Node2D = preload("res://scripts/world/farm_field.gd").new()
	farm.field_id = field_id
	farm.free_area = true
	farm.player = player
	var space := get_world_2d().direct_space_state
	var box := RectangleShape2D.new()
	box.size = Vector2(26, 26)
	farm.farmable = func(cell: Vector2i) -> bool:
		if is_instance_valid(house_builder) and house_builder.house().floor.has(cell): return false
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = box
		query.transform = Transform2D(0, Vector2(cell * 32) + Vector2(16, 16))
		query.collision_mask = 2
		return space.intersect_shape(query, 1).is_empty()
	var pools: Array[Polygon2D] = []
	for node in find_children("Water", "Polygon2D", true, false): pools.append(node)
	if has_node("Water"):
		for node in get_node("Water").get_children():
			if node is Polygon2D: pools.append(node)
	farm.water_at = func(at: Vector2) -> bool:  # regador enche no lago/riacho
		for pool in pools:
			if is_instance_valid(pool) and Geometry2D.is_point_in_polygon(pool.to_local(at), pool.polygon): return true
		return false
	add_child(farm)
	return farm


## [F] do plantio quando o jogador olha para terra arada ou usa enxada/regador/semente.
func handle_farming(farm: Node2D) -> bool:
	if not is_instance_valid(farm) or not farm.wants(player): return false
	hud_hint.text = farm.hint(player)
	if player.is_using_tool(): return true  # termina o golpe antes de outro [F]
	# Comida na mão e nada a fazer com ela na terra à frente: [F] come.
	var held: String = preload("res://scripts/systems/hotbar_state.gd").selected_item(get_tree())
	if Input.is_action_just_pressed("interact") and preload("res://scripts/systems/item_catalog.gd").energy(held) > 0 			and not farm.can_fill(player) and str(farm.action_with(farm.target_cell(player), held)).is_empty():
		eat_selected()
		return true
	if Input.is_action_just_pressed("interact"):
		var message: String = farm.interact(player)
		if not message.is_empty(): _notify(message)
		var bag_node: Node = get("bag_hud")
		if is_instance_valid(bag_node): bag_node.call("refresh")
	return true


## Mato coletável em cima de terra arada não é oferecido.
func hide_forage_on_farm(farm: Node2D, forage: Node2D) -> void:
	if not is_instance_valid(farm) or not is_instance_valid(forage): return
	var farm_state := preload("res://scripts/systems/farm_state.gd")
	forage.hidden_at = func(at: Vector2) -> bool: return farm_state.is_tilled(get_tree(), farm.cell_at(at), farm.field_id)


var _chest_panel: Control


## Janela do baú da casa (guarda itens sem o limite da bolsa).
func open_chest(id: String = "") -> void:
	if not is_instance_valid(_chest_panel):
		_chest_panel = preload("res://scripts/ui/chest_panel.gd").new()
		_chest_panel.player = player
		get_node("HUD/Interface").add_child(_chest_panel)
		_chest_panel.changed.connect(func() -> void:
			var bag_node: Node = get("bag_hud")
			if is_instance_valid(bag_node): bag_node.call("refresh"))
	_chest_panel.open(id)


## Dica de [F] perto de um slime amigo quando a barra tem comida ("" = sem comida).
func slime_food_hint(slime: Node2D) -> String:
	var feeding := preload("res://scripts/systems/slime_feeding.gd")
	var item: String = preload("res://scripts/systems/hotbar_state.gd").selected_item(get_tree())
	if not feeding.is_food(item): return ""  # amigo ou não: comida conquista a amizade
	var items := preload("res://scripts/systems/item_catalog.gd")
	return "[F] Dar %s a %s" % [str(items.info(item).name).to_lower(), slime.call("display_name")]


## Machado/picareta na mão e árvore/pedra ao alcance: o golpe vem antes de usar a
## bancada ou o baú ao lado (senão a bancada perto de uma árvore impede cortar).
const ITEM_TOOLS := preload("res://scripts/systems/item_catalog.gd")


func tool_target_near() -> bool:
	var g: Node = get("gathering")
	if not is_instance_valid(g) or not is_instance_valid(player): return false
	var item: String = preload("res://scripts/systems/hotbar_state.gd").selected_item(get_tree())
	if item in ITEM_TOOLS.AXES and is_instance_valid(g.get("choppable")): return not (g.choppable.target(player.global_position) as Dictionary).is_empty()
	if item in ITEM_TOOLS.PICKS and is_instance_valid(g.get("rocks")): return not (g.rocks.target(player.global_position) as Dictionary).is_empty()
	return false


## Disco de ações do slime (scripts/ui/slime_action_disc.gd).
var slime_disc: Control
func add_slime_disc() -> void:
	slime_disc = preload("res://scripts/ui/slime_action_disc.gd").new()
	slime_disc.set("region", self)
	get_node("HUD/Interface").add_child(slime_disc)


func open_slime_disc(slime: Node2D) -> void:
	if not is_instance_valid(slime_disc): return
	if int(slime_disc.get("closed_frame")) >= Engine.get_process_frames() - 1: return  # o [F] que fechou
	slime_disc.call("open", slime)


## Ação escolhida no disco. arg: comida escolhida ou baú do Carreguim ("" = mais perto).
func slime_action(slime: Node2D, action: String, arg: String) -> void:
	var tree := get_tree()
	var species := str(slime.get("slime_type"))
	match action:
		"carinho":
			greet_slime(slime)
		"comida":
			if arg.is_empty():
				_notify("Você não tem comida. Colha ou cozinhe algo para oferecer.")
				return
			var bar := preload("res://scripts/systems/hotbar_state.gd")
			bar.select(tree, bar.slots(tree).find(arg))
			if has_method("_offer_prototype_food"): call("_offer_prototype_food", slime)
		"trabalho":
			if species == "carreguim":
				tree.set_meta("carreguim_chest", arg)
				_notify("%s vai levar as coisas para %s." % [slime.call("display_name"), "o baú mais perto" if arg.is_empty() else "o baú escolhido"])
				return
			var off: Dictionary = (tree.get_meta("slime_work_off", {}) as Dictionary).duplicate()
			off[species] = not bool(off.get(species, false))
			tree.set_meta("slime_work_off", off)
			_notify("%s %s." % [slime.call("display_name"), "parou de trabalhar" if off[species] else "voltou a trabalhar"])
		"seguir":
			var farm_map: Dictionary = (tree.get_meta("slime_at_farm", {}) as Dictionary).duplicate()
			farm_map[species] = not bool(farm_map.get(species, true))
			tree.set_meta("slime_at_farm", farm_map)
			_notify("%s %s." % [slime.call("display_name"), "foi para a fazenda" if farm_map[species] else "vai ficar em casa"])


## Slime por perto sem comida na mão: amigo aceita carinho; desconhecido desconfia
## e só vira amigo comendo (pedido do usuário). Devolve a dica do HUD.
func slime_greet_hint(slime: Node2D) -> String:
	if bool(slime.get("befriended")): return "[F] Ações com " + str(slime.call("display_name"))
	return "%s está desconfiado · [F] oferecer comida" % slime.call("display_name")


## [F] sem comida: carinho no amigo; o desconhecido se afasta um pouco.
func greet_slime(slime: Node2D) -> void:
	var feeding := preload("res://scripts/systems/slime_feeding.gd")
	if not bool(slime.get("befriended")):
		if slime.has_method("react"): slime.call("react", "blink")
		_notify("%s ainda não confia em você. Faça comida e ofereça para ganhar a amizade." % slime.call("display_name"))
		return
	if slime.has_method("react"): slime.call("react", "receber_carinho")
	var hearts := feeding.hearts(get_tree(), str(slime.get("persistent_id")))
	_notify("%s adora o carinho. Laço: %d/%d corações." % [slime.call("display_name"), hearts, feeding.MAX_HEARTS])


## [F] sem slime por perto: come a comida selecionada na barra e recupera energia
## (colheita +12, porção +30). Energia cheia: não come.
func eat_selected() -> bool:
	var energy := preload("res://scripts/systems/energy_state.gd")
	var items := preload("res://scripts/systems/item_catalog.gd")
	var bag := preload("res://scripts/systems/forest_bag.gd")
	var item: String = preload("res://scripts/systems/hotbar_state.gd").selected_item(get_tree())
	var gain := items.energy(item)
	if gain <= 0: return false
	if energy.current(get_tree()) >= energy.MAX:
		_notify("Energia já está cheia.")
		return false
	if not bag.spend_item(get_tree(), item, 1): return false
	energy.restore(get_tree(), gain)
	var bag_node: Node = get("bag_hud")
	if is_instance_valid(bag_node): bag_node.call("refresh")
	_notify("Você comeu %s. Energia +%d (%d/%d)." % [str(items.info(item).name).to_lower(), gain, energy.current(get_tree()), energy.MAX])
	return true


var item_drops: Node2D


## Itens caem no chão ao coletar, cortar e colher e o ímã leva à bolsa (item_drops).
func add_item_drops(farm: Node2D, gathering_node: Node) -> void:
	item_drops = preload("res://scripts/world/item_drops.gd").new()
	item_drops.player = player
	add_child(item_drops)
	var spawn := Callable(item_drops, "spawn")
	item_drops.picked.connect(func(item: String, amount: int) -> void:
		var bag_node: Node = get("bag_hud")
		if is_instance_valid(bag_node): bag_node.call("refresh")
		var items := preload("res://scripts/systems/item_catalog.gd")
		_notify("+%d %s" % [amount, str(items.info(item).name).to_lower()]))
	if is_instance_valid(farm): farm.drop = spawn
	preload("res://scripts/world/farm_helpers.gd").drop = spawn  # Colhita deixa a colheita no chão
	if is_instance_valid(gathering_node):
		if is_instance_valid(gathering_node.forage): gathering_node.forage.drop = spawn
		if is_instance_valid(gathering_node.choppable): gathering_node.choppable.drop = spawn
		if is_instance_valid(gathering_node.get("rocks")): gathering_node.rocks.drop = spawn


## Clique esquerdo = [F] no ponto clicado (pedido do usuário, como em jogos de
## fazenda): dentro do alcance, o personagem vira para o clique e age; segurar o
## botão = segurar [F] (arrancar mato). O modo construir e as janelas pegam o clique antes.
const CLICK_REACH := 96.0
var _click_holding := false
## Ponto clicado enquanto o botão está apertado (coleta/corte miram nele); INF = sem clique.
var click_point := Vector2.INF


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT: return
	if not mouse.pressed:
		if _click_holding:
			_click_holding = false
			click_point = Vector2.INF
			Input.action_release("interact")
		return
	if bool(get_tree().get_meta("build_mode", false)) or not is_instance_valid(player) or window_open(): return
	var at: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * mouse.position  # ponto do mundo clicado
	if player.global_position.distance_to(at) > CLICK_REACH: return
	if player.has_method("is_using_tool") and player.is_using_tool(): return
	if at.distance_to(player.global_position) > 4.0:
		player.facing = player._get_direction_name(at - player.global_position)
	_click_holding = true
	click_point = at
	Input.action_press("interact")
	get_viewport().set_input_as_handled()

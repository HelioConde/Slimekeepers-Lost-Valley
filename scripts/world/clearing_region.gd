extends "res://scripts/world.gd"
## The editable map is baked in ClareiraDoDespertar.tscn. Reuse existing friendship/HUD.
const PauseOverlay := preload("res://scripts/ui/pause_overlay.gd")
const Layout = preload("res://scripts/world/clearing_layout.gd")
var _visited_exits: Dictionary = {}

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
	panel.anchor_right = 0.0
	panel.offset_right = 18
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
	$HUD/Interface.add_child(preload("res://scripts/ui/energy_hud.gd").new())
	# Slime por perto: retrato, nome e corações do laço (exemplo de HUD do usuário).
	# Multijogador: mostra o outro jogador e envia a posição deste (net_presence.gd).
	var presence := preload("res://scripts/net/net_presence.gd").new()
	presence.player = player
	add_child(presence)
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
	popup.offset_top = 90
	popup.offset_bottom = 138
	popup.add_theme_font_size_override("font_size",18)


## Casa construída pelo jogador nesta região (CASA.md): sem casa inicial; [B] abre o
## modo construir em qualquer lugar livre do mapa (não sobre árvore, pedra ou água).
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
	if not GameClock.time_changed.is_connected(_on_time_for_faint):
		GameClock.time_changed.connect(_on_time_for_faint)
	return builder


var _player_house: Node2D
const FAINT_HOUR := 0  # meia-noite (BACKLOG P2)
const FAINT_ENERGY := 50


func _exit_tree() -> void:
	if GameClock.time_changed.is_connected(_on_time_for_faint):
		GameClock.time_changed.disconnect(_on_time_for_faint)


## Acordado depois da meia-noite: desmaia e acorda às 06:00 ao lado da cama (se a
## casa estiver nesta região), com metade da energia. Dormir na cama evita.
func _on_time_for_faint(_day: int, hour: int, _minute: int) -> void:
	if hour < FAINT_HOUR or hour >= 6 or not is_inside_tree(): return
	faint()


func faint() -> void:
	var minutes := GameClock.get_hour() * 60.0 + GameClock.get_minute()
	GameClock.advance_minutes(360.0 - minutes)  # até 06:00 (já passou da meia-noite)
	var energy := preload("res://scripts/systems/energy_state.gd")
	get_tree().set_meta(energy.KEY, FAINT_ENERGY)
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


## Alguma janela (mochila, fabricação, baú) aberta: o mundo não recebe [F] nem clique.
func window_open() -> bool:
	if not has_node("HUD/Interface"): return false
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
		hud_hint.text = "[F] Dormir até amanhã   •   [B] Construir"
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
func sleep_until_morning() -> void:
	var minutes := GameClock.get_hour() * 60.0 + GameClock.get_minute()
	GameClock.advance_minutes((1440.0 - minutes) + 360.0)
	preload("res://scripts/systems/energy_state.gd").restore(get_tree())
	var saved: bool = preload("res://scripts/systems/save_game.gd").save(get_tree(), GameClock, scene_file_path)
	_notify("Bom dia! Dia %d." % GameClock.day_number + ("  Jogo salvo." if saved else ""))


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
func open_chest() -> void:
	if not is_instance_valid(_chest_panel):
		_chest_panel = preload("res://scripts/ui/chest_panel.gd").new()
		_chest_panel.player = player
		get_node("HUD/Interface").add_child(_chest_panel)
		_chest_panel.changed.connect(func() -> void:
			var bag_node: Node = get("bag_hud")
			if is_instance_valid(bag_node): bag_node.call("refresh"))
	_chest_panel.open()


## Dica de [F] perto de um slime amigo quando a barra tem comida ("" = sem comida).
func slime_food_hint(slime: Node2D) -> String:
	var feeding := preload("res://scripts/systems/slime_feeding.gd")
	var item: String = preload("res://scripts/systems/hotbar_state.gd").selected_item(get_tree())
	if not bool(slime.get("befriended")) or not feeding.is_food(item): return ""
	var items := preload("res://scripts/systems/item_catalog.gd")
	return "[F] Dar %s a %s" % [str(items.info(item).name).to_lower(), slime.call("display_name")]


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

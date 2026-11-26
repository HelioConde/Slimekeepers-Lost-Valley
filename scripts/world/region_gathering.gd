extends Node
## Coleta e corte compartilhados pelas regiões (Floresta e Vale das Nascentes):
## árvores cortáveis com o machado e pontos de coleta (um toque em [F] ou clique
## começa a pegar e continua sozinho; andar cancela). Segurar [F]/clique continua
## golpeando árvores e pedras. A região chama update(delta) no _process; devolve
## true quando a interação tomou o HUD neste quadro.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const ENERGY := preload("res://scripts/systems/energy_state.gd")

var region: Node  # clearing_region: player, hud_hint, bag_hud, _notify()
var choppable: Node
var forage: Node2D
var rocks: Node2D  # breakable_rocks.gd: pedras médias e grandes (picareta)
var _pull_id := ""  # ponto sendo pego (começou com um toque; andar cancela)
var _pull_spot: Dictionary = {}
var _pull_time := 0.0
const MOVES := ["move_left", "move_right", "move_up", "move_down"]


func _init() -> void:
	name = "Gathering"


## Cria o corte e a coleta da região (sem pontos ainda): árvores dos grupos dados
## (prefixo separa o estado salvo de cada mapa) e um ForageSpots vazio em `parent`.
func setup(owner_region: Node, tree_groups: Array, protected: Callable, prefix: String, parent: Node) -> void:
	region = owner_region
	choppable = preload("res://scripts/world/choppable_trees.gd").new()
	owner_region.add_child(choppable)
	choppable.setup(tree_groups, protected, prefix, prefix != "")
	choppable.apply_day(GameClock.day_number)
	GameClock.day_changed.connect(choppable.apply_day)
	forage = preload("res://scripts/world/forage_spots.gd").new()
	forage.name = "ForageSpots"
	parent.add_child(forage)
	GameClock.day_changed.connect(forage.refresh)


## Usa corte e coleta já criados pela região (Floresta).
func attach(owner_region: Node, chop: Node, spots: Node2D) -> void:
	region = owner_region
	choppable = chop
	forage = spots


## Onde procurar: o ponto clicado (mouse) ou os pés do jogador ([F]).
func _focus() -> Vector2:
	var clicked: Vector2 = region.get("click_point") if region.get("click_point") != null else Vector2.INF
	return clicked if clicked.is_finite() else region.player.global_position


func update(delta: float) -> bool:
	if not _pull_id.is_empty():
		_forage_interaction(_pull_spot, delta)  # continua no mesmo ponto até terminar ou andar
		return true
	# Machado na mão e árvore ao alcance: cortar vem antes de arrancar o mato em volta.
	if is_instance_valid(choppable) and HOTBAR.selected_item(get_tree()) in ITEMS.AXES and _axe_interaction():
		_pull_id = ""
		return true
	if HOTBAR.selected_item(get_tree()) in ITEMS.PICKS and _rock_interaction():
		_pull_id = ""
		return true
	if is_instance_valid(forage):
		var spot: Dictionary = forage.nearest(_focus(), GameClock.day_number)
		if not spot.is_empty():
			_forage_interaction(spot, delta)
			return true
	_pull_id = ""
	if _rock_interaction(): return true
	return is_instance_valid(choppable) and _axe_interaction()


## Ferramenta da família `tools` a usar: sempre a melhor da bolsa (a troca é automática).
func _best(tools: Array) -> String:
	for tool: String in tools:
		if BAG.count_item(get_tree(), tool) > 0: return tool
	return ""


## Pedras médias (picareta) e grandes (picareta de pedra polida).
func _rock_interaction() -> bool:
	if not is_instance_valid(rocks): return false
	var r: Dictionary = rocks.target(_focus())
	if r.is_empty(): return false
	var player: Node2D = region.player
	var tool := _best(ITEMS.PICKS)
	# Playtest ID 54: qualquer picareta quebra qualquer pedra; a rudimentar só leva mais golpes.
	if tool.is_empty():
		region.hud_hint.text = "Pedra média · precisa de uma picareta (fabrique na bancada)"
		return true
	if not _equip(tool): return true
	region.hud_hint.text = "[F] Quebrar pedra (%d/%d)%s" % [rocks.hits(r.id), int(rocks.HITS[r.kind]),
		" · grande: uma picareta melhor quebra mais rápido" if str(r.kind) == "large" and int(ITEMS.POWER.get(tool, 1)) < 2 else ""]
	if Input.is_action_pressed("interact") and not player.is_using_tool():  # segurar = golpes seguidos
		if not ENERGY.spend(get_tree(), "chop"):
			region._notify(preload("res://scripts/systems/protagonist.gd").tired_message(get_tree()))
			return true
		player.facing = player._get_direction_name(r.at - player.global_position)
		var swing := "pickaxe_polished" if int(ITEMS.POWER.get(tool, 1)) >= 2 else "pickaxe"
		if player.play_tool(swing) <= 0.0 and player.play_tool("pickaxe") <= 0.0: player.play_tool("hoe")  # sem arte própria
		if rocks.strike(r, GameClock.day_number, int(ITEMS.POWER.get(tool, 1))) == "broken":
			region._notify("A pedra quebrou!")
	return true


## Troca automática de ferramenta (elogiada no Fae Farm): com o alvo à frente e a
## ferramenta na mochila, [F]/clique a escolhe na barra sozinho. Devolve true quando ela
## já está na mão (o golpe segue no mesmo quadro).
func _equip(tool: String) -> bool:
	if HOTBAR.selected_item(get_tree()) == tool: return true
	var slot: int = HOTBAR.slots(get_tree()).find(tool)
	if slot < 0: return false
	if Input.is_action_just_pressed("interact"):
		HOTBAR.select(get_tree(), slot)
		return true
	region.hud_hint.text = "[F] Usar %s" % str(ITEMS.info(tool).name).to_lower()
	return false


## Espalha pedras médias e grandes pela região (chamado pela região depois do setup).
func add_rocks(owner_region: Node, area: Rect2, plan: Dictionary, free: Callable, prefix: String = "") -> void:
	rocks = preload("res://scripts/world/breakable_rocks.gd").new()
	var parent: Node = owner_region.get_node("Decorations") if owner_region.has_node("Decorations") else owner_region
	parent.add_child(rocks)
	rocks.scatter(area, 220.0, plan, free, prefix)
	rocks.refresh(GameClock.day_number)
	GameClock.day_changed.connect(rocks.refresh)


## Foice (pedido do usuário, 2026-11-23): corta o mato de um golpe; só ela solta
## sementes, com chance SEED_CHANCE (com a mão, só fibra).
const SEED_CHANCE := 0.10
const SICKLE_SEEDS := ["semente_cenoura", "semente_beterraba", "semente_repolho", "sementes_silvestres"]
var rng := RandomNumberGenerator.new()


func _sickle_cut(spot: Dictionary) -> void:
	var player: Node2D = region.player
	region.hud_hint.text = "[F] Cortar o mato com a foice"
	if not Input.is_action_pressed("interact") or player.is_using_tool(): return
	player.facing = player._get_direction_name(spot.at - player.global_position)
	if player.play_tool("sickle") <= 0.0: player.play_tool("hoe")  # sem arte de foice ainda
	var problem: String = forage.take(spot, GameClock.day_number)
	if not problem.is_empty():
		region._notify(problem)
		return
	if rng.randf() < SEED_CHANCE:
		var seed_id: String = SICKLE_SEEDS[rng.randi() % SICKLE_SEEDS.size()]
		if forage.drop.is_valid(): forage.drop.call(seed_id, 1, spot.at)
		else: BAG.add_item(get_tree(), seed_id, 1)
	region.bag_hud.call("refresh")


func _forage_interaction(spot: Dictionary, delta: float) -> void:
	var player: Node2D = region.player
	if str(spot.item) == "fibra" and HOTBAR.selected_item(get_tree()) == "foice" and _pull_id.is_empty():
		_sickle_cut(spot)
		return
	var item_name := str(ITEMS.info(spot.item).name).to_lower()
	var hold: float = forage.pull_seconds(spot.item)
	if hold > 0.0:
		# Um toque começa; continua sozinho até soltar do chão. Andar cancela.
		if _pull_id == spot.id and MOVES.any(func(m: String) -> bool: return Input.is_action_pressed(m)):
			_pull_id = ""
			player.release_pose()
		elif _pull_id == spot.id:
			_pull_time += delta
		elif Input.is_action_just_pressed("interact") and not player.is_using_tool():
			_pull_id = spot.id
			_pull_spot = spot
			_pull_time = 0.0
		var pulling: bool = str(spot.item) == "fibra"
		var verb: String = "Arrancar o mato" if pulling else "Pegar " + item_name
		if _pull_id != spot.id:
			region.hud_hint.text = "[F] %s" % verb
			return
		# Mato: duas mãos, agachado; graveto e pedra: uma mão, ajoelhado. Fazendo força
		# (puxa e solta) até soltar do chão.
		player.facing = player._get_direction_name(spot.at - player.global_position)
		if pulling: player.hold_pose("pick_big", player.PICK_BIG_GROUND)
		else: player.hold_pose("pick_small", player.PICK_SMALL_GROUND)
		region.hud_hint.text = "%s... %d%% · andar cancela" % ["Arrancando o mato" if pulling else "Pegando " + item_name, mini(99, int(_pull_time / hold * 100.0))]
		if _pull_time < hold: return
		_pull_id = ""
		player.release_pose()  # levanta com o mato na mão
	else:
		region.hud_hint.text = "[F] Pegar " + item_name
		if not Input.is_action_just_pressed("interact") or player.is_using_tool(): return
		# Item pequeno: ajoelha e pega com uma mão.
		player.facing = player._get_direction_name(spot.at - player.global_position)
		player.play_tool("pick_small")
	var problem: String = forage.take(spot, GameClock.day_number)
	region.bag_hud.call("refresh")
	if not problem.is_empty(): region._notify(problem)
	elif not forage.drop.is_valid(): region._notify("Você pegou %s." % item_name)  # com drop, avisa ao pegar


func _axe_interaction() -> bool:
	var player: Node2D = region.player
	var t: Dictionary = choppable.target(_focus())
	var tool := _best(ITEMS.AXES)
	if t.is_empty() or tool.is_empty():
		return false
	var power := int(ITEMS.POWER.get(tool, 1))
	# Playtest ID 54: qualquer machado derruba qualquer árvore; o rudimentar só leva mais golpes.
	if not _equip(tool): return true
	var total: int = choppable.fell_hits(t.key) if t.kind == "tree" else choppable.HITS_TO_PROCESS
	region.hud_hint.text = "[F] %s (%d/%d)%s" % ["Cortar árvore" if t.kind == "tree" else "Processar tronco em madeira", choppable.hits(t.key), total,
		" · grande: um machado melhor corta mais rápido" if t.kind == "tree" and not choppable.is_small(t.key) and power < 2 else ""]
	if Input.is_action_pressed("interact") and not player.is_using_tool():  # segurar = golpes seguidos
		if not ENERGY.spend(get_tree(), "chop" if t.kind == "tree" else "process"):
			region._notify(preload("res://scripts/systems/protagonist.gd").tired_message(get_tree()))
			return true
		if power < 2 or player.play_tool("axe_polished") <= 0.0: player.play_tool("axe")
		match choppable.strike(t, GameClock.day_number, power):
			"felled": region._notify("A árvore caiu! Processe o tronco com o machado.")
			"processed":
				region.bag_hud.call("refresh")
				region._notify("Você conseguiu %d madeiras." % choppable.wood(t.key))
	return true

extends Node
## Coleta e corte compartilhados pelas regiões (Floresta e Vale das Nascentes):
## árvores cortáveis com o machado e pontos de coleta (mato com [F] segurado,
## graveto/pedra com um toque). A região chama update(delta) no _process; devolve
## true quando a interação tomou o HUD neste quadro.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const ENERGY := preload("res://scripts/systems/energy_state.gd")

var region: Node  # clearing_region: player, hud_hint, bag_hud, _notify()
var choppable: Node
var forage: Node2D
var rocks: Node2D  # breakable_rocks.gd: pedras médias e grandes (picareta)
var _pull_id := ""  # ponto sendo arrancado com [F] segurado
var _pull_time := 0.0


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
	var player: Node2D = region.player
	# Machado na mão e árvore ao alcance: cortar vem antes de arrancar o mato em volta.
	if is_instance_valid(choppable) and HOTBAR.selected_item(get_tree()) == "machado" and _axe_interaction():
		_pull_id = ""
		return true
	if HOTBAR.selected_item(get_tree()) == "picareta" and _rock_interaction():
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


## Pedras médias (picareta) e grandes (picareta melhor, ainda não existe).
func _rock_interaction() -> bool:
	if not is_instance_valid(rocks): return false
	var r: Dictionary = rocks.target(_focus())
	if r.is_empty(): return false
	var player: Node2D = region.player
	if str(r.kind) == "large":
		region.hud_hint.text = "Pedra grande · precisa de uma picareta melhor"
		return true
	if BAG.count_item(get_tree(), "picareta") <= 0:
		region.hud_hint.text = "Pedra média · precisa de uma picareta (fabrique na bancada)"
		return true
	if HOTBAR.selected_item(get_tree()) != "picareta":
		region.hud_hint.text = "Selecione a picareta na barra para quebrar a pedra"
		return true
	region.hud_hint.text = "[F] Quebrar pedra (%d/%d)" % [rocks.hits(r.id), int(rocks.HITS[r.kind])]
	if Input.is_action_just_pressed("interact") and not player.is_using_tool():
		if not ENERGY.spend(get_tree(), "chop"):
			region._notify(preload("res://scripts/systems/protagonist.gd").tired_message(get_tree()))
			return true
		player.facing = player._get_direction_name(r.at - player.global_position)
		if player.play_tool("pickaxe") <= 0.0: player.play_tool("hoe")  # protagonista sem arte de picareta
		if rocks.strike(r, GameClock.day_number) == "broken":
			region._notify("A pedra quebrou!")
	return true


## Espalha pedras médias e grandes pela região (chamado pela região depois do setup).
func add_rocks(owner_region: Node, area: Rect2, plan: Dictionary, free: Callable, prefix: String = "") -> void:
	rocks = preload("res://scripts/world/breakable_rocks.gd").new()
	var parent: Node = owner_region.get_node("Decorations") if owner_region.has_node("Decorations") else owner_region
	parent.add_child(rocks)
	rocks.scatter(area, 220.0, plan, free, prefix)
	rocks.refresh(GameClock.day_number)
	GameClock.day_changed.connect(rocks.refresh)


func _forage_interaction(spot: Dictionary, delta: float) -> void:
	var player: Node2D = region.player
	var item_name := str(ITEMS.info(spot.item).name).to_lower()
	var hold: float = forage.pull_seconds(spot.item)
	if hold > 0.0:
		# Segurar [F] até soltar do chão; soltar ou sair de perto recomeça.
		if Input.is_action_just_pressed("interact"):
			_pull_id = spot.id
			_pull_time = 0.0
		elif Input.is_action_pressed("interact") and _pull_id == spot.id:
			_pull_time += delta
		else:
			_pull_id = ""
		var pulling: bool = str(spot.item) == "fibra"
		var verb: String = "Arrancar o mato" if pulling else "Pegar " + item_name
		if _pull_id != spot.id:
			region.hud_hint.text = "[Segure F] %s (%d s)" % [verb, int(ceil(hold))]
			return
		# Mato: duas mãos, agachado; graveto e pedra: uma mão, ajoelhado. Fazendo força
		# (puxa e solta) até soltar do chão.
		player.facing = player._get_direction_name(spot.at - player.global_position)
		if pulling: player.hold_pose("pick_big", player.PICK_BIG_GROUND)
		else: player.hold_pose("pick_small", player.PICK_SMALL_GROUND)
		region.hud_hint.text = "%s... %d%%" % ["Arrancando o mato" if pulling else "Pegando " + item_name, mini(99, int(_pull_time / hold * 100.0))]
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
	if t.is_empty() or BAG.count_item(get_tree(), "machado") <= 0:
		return false
	if HOTBAR.selected_item(get_tree()) != "machado":
		region.hud_hint.text = "Selecione o machado na barra para " + ("cortar a árvore" if t.kind == "tree" else "processar o tronco")
		return true
	if t.kind == "tree" and not choppable.is_small(t.key):
		# Machado de pedra só derruba árvores pequenas; as grandes esperam machados melhores.
		region.hud_hint.text = "Árvore grande demais para o machado rudimentar · precisa de um machado melhor"
		return true
	var total: int = choppable.HITS_TO_FELL if t.kind == "tree" else choppable.HITS_TO_PROCESS
	region.hud_hint.text = "[F] %s (%d/%d)" % ["Cortar árvore" if t.kind == "tree" else "Processar tronco em madeira", choppable.hits(t.key), total]
	if Input.is_action_just_pressed("interact") and not player.is_using_tool():
		if not ENERGY.spend(get_tree(), "chop" if t.kind == "tree" else "process"):
			region._notify(preload("res://scripts/systems/protagonist.gd").tired_message(get_tree()))
			return true
		player.play_tool("axe")
		match choppable.strike(t, GameClock.day_number):
			"felled": region._notify("A árvore caiu! Processe o tronco com o machado.")
			"processed":
				region.bag_hud.call("refresh")
				region._notify("Você conseguiu %d madeiras." % choppable.WOOD_PER_LOG)
	return true

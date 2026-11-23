extends SceneTree
const NEW_GAME := preload("res://tools/new_game_helper.gd")
## Validacao nativa: Brotinho -> sementes -> arar com a enxada no Vale -> plantar ->
## regar -> crescer -> colher -> cozinhar -> alimentar -> viajar -> reset.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const FARM := preload("res://scripts/systems/farm_state.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
const FOOD := preload("res://scripts/systems/slime_food_session.gd")
const PROGRESS := preload("res://scripts/systems/session_progress_session.gd")
const VALLEY_LAYOUT := preload("res://scripts/world/valley_layout.gd")
const FOREST := "res://scenes/regions/FlorestaDoDespertarV2.tscn"
const VALLEY := "res://scenes/regions/ValeDasNascentes.tscn"
var clock
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

func _settle() -> void:
	for i in 6:
		await physics_frame
	await process_frame
	await process_frame

func _press_e() -> void:
	Input.action_press("interact")
	await process_frame
	await process_frame
	Input.action_release("interact")
	await _settle()

func _press_f() -> void:
	Input.action_press("interact")
	await process_frame
	await process_frame
	Input.action_release("interact")
	await _settle()

## Seleciona o item na barra e usa [E] (espera o golpe/rega acabar).
func _use(item: String) -> void:
	HOTBAR.select(self, HOTBAR.slots(self).find(item))
	await process_frame
	await _press_e()
	await create_timer(1.5).timeout


func _bag_text(region: Node2D) -> String:
	var panel: Node = region.get_node_or_null("HUD/Interface/ForagingBagPanel")
	return str(panel.get_node("InventoryCount").text) if panel != null else ""

func _travel_to_valley() -> void:
	current_scene.player.position = Vector2(3220, 6280)
	await _settle()
	await _press_e()

func _travel_to_forest() -> void:
	current_scene.player.position = Vector2(1600, 70)
	await _settle()
	await _press_e()

func _run() -> void:
	clock = root.get_node("GameClock")
	clock.reset_new_game()
	_check(BAG.seeds(self) == 0 and BAG.leaves(self) == 0, "A bolsa comeca sem sementes e folhas")
	_check(PROGRESS.count(self) == 0, "Marcos da sessao iniciam vazios")
	var forest := load(FOREST).instantiate() as Node2D
	root.add_child(forest)
	current_scene = forest
	await _settle()
	var friend: Node2D = null
	for slime in forest.slimes:
		if slime.slime_type == "brotinho":
			friend = slime
			break
	_check(friend != null, "Brotinho existe na floresta jogavel")
	if friend == null:
		_finish()
		return
	forest.player.global_position = friend.global_position + Vector2(0, 24)
	await _settle()
	await _hold_food()
	await _press_e()
	HOTBAR.select(self, -1)
	_check(BAG.has_brotinho_friend(self), "Amizade verdadeira libera habilidade de coleta")
	for id in ["bosque_cogumelos", "jardim_folhas"]:
		var patch: Node2D = null
		for candidate in forest.seed_patches:
			if str(candidate.patch_id) == id:
				patch = candidate
				break
		_check(patch != null, "Planta silvestre encontrada: " + id)
		if patch == null:
			_finish()
			return
		forest.player.global_position = patch.global_position
		await _settle()
		await _press_e()
		_check(bool(patch.get("collected")), "Coleta pela tecla E: " + id)
	_check(BAG.seeds(self) == 2, "Duas sementes na bolsa antes de viajar")
	_check(PROGRESS.is_marked(self, PROGRESS.SEEDS_COLLECTED) and PROGRESS.count(self) == 1,
		"Coletar dois locais registra apenas um marco real de coleta")
	await _travel_to_valley()
	_check(current_scene != null and current_scene.scene_file_path == VALLEY, "Chegou ao Vale das Nascentes")
	if current_scene == null or current_scene.scene_file_path != VALLEY:
		_finish()
		return
	_check(current_scene.get_node_or_null("StarterGarden") == null, "Vale sem canteiros de teste")
	_check(_bag_text(current_scene).contains("2/3"), "Vale mostra sementes trazidas da floresta")
	_check(PROGRESS.count(self) == 1, "Progresso da coleta permanece entre as regioes")
	_check(current_scene.get_node_or_null("CookingStation") == null and current_scene.get_node_or_null("FarmGate") == null,
		"Vale sem fogueira e sem portao da fazenda (cozinhar é no fogão da casa)")
	_check(COOKING.prepare(self) != "prepared" and COOKING.portions(self) == 0 and BAG.leaves(self) == 0,
		"Tentar preparar sem ingredientes nao cria porcao")
	# Plantio livre: enxada e regador (feitos na bancada) aram e regam a grama do Vale.
	for tool in ["enxada", "regador"]: BAG.add_item(self, tool)
	var farm: Node2D = current_scene.farm
	var spot := Vector2i(-1, -1)
	var here: Vector2i = farm.cell_at(current_scene.player.global_position)
	for r in range(2, 16):
		for dx in range(-r, r + 1):
			var c := here + Vector2i(dx, r)
			if farm.contains(c) and farm.contains(c + Vector2i(1, 0)) and farm.contains(c + Vector2i(0, -1)) and farm.contains(c + Vector2i(1, -1)):
				spot = c
				break
		if spot.x != -1: break
	_check(spot.x != -1, "Chao livre aravel no Vale")
	var cells := [spot, spot + Vector2i(1, 0)]
	current_scene.player.facing = "south"
	for cell in cells:
		current_scene.player.global_position = Vector2((cell + Vector2i(0, -1)) * 32) + Vector2(16, 16)
		await _settle()
		await _use("enxada")
		await _use("sementes_silvestres")
	_check(FARM.is_tilled(self, cells[0], farm.field_id) and FARM.crop(self, cells[0], farm.field_id) == "folhas_silvestres",
		"Enxada ara e semente silvestre e plantada com E")
	_check(PROGRESS.is_marked(self, PROGRESS.GARDEN_PLANTED) and PROGRESS.count(self) == 2,
		"Plantio real adiciona um marco sem apagar o anterior")
	_check(BAG.seeds(self) == 0, "Cada plantio consome exatamente uma semente")
	var days := 0
	while not FARM.is_ready(self, cells[1], farm.field_id) and days < 8:
		for cell in cells:
			current_scene.player.global_position = Vector2((cell + Vector2i(0, -1)) * 32) + Vector2(16, 16)
			await _settle()
			await _use("regador")
		clock.advance_minutes(24 * 60.0)
		await _settle()
		days += 1
	_check(FARM.is_ready(self, cells[0], farm.field_id) and FARM.is_ready(self, cells[1], farm.field_id),
		"Regadas todo dia, as folhas ficam prontas (%d dias)" % days)
	await _travel_to_forest()
	_check(current_scene.scene_file_path == FOREST and FARM.is_ready(self, cells[0], "vale"), "Plantio preservado fora do Vale")
	await _travel_to_valley()
	for cell in cells:
		current_scene.player.global_position = Vector2((cell + Vector2i(0, -1)) * 32) + Vector2(16, 16)
		await _settle()
		await _press_e()
	current_scene.item_drops.collect_all()  # as folhas caem no chão (item_drops)
	_check(BAG.leaves(self) == 2, "Duas colheitas de folhas frescas na bolsa")
	_check(PROGRESS.is_marked(self, PROGRESS.GARDEN_HARVESTED) and PROGRESS.count(self) == 3,
		"Colheita de folhas confirma o terceiro marco sem duplicar")
	_check(_bag_text(current_scene).contains("folhas frescas 2"), "HUD atualiza a colheita")
	# Cozinhar (no fogão da casa; a interação real está em tools/capture_house.gd).
	_check(COOKING.prepare(self) == "prepared" and BAG.leaves(self) == 1 and COOKING.portions(self) == 1,
		"Primeiro preparo gasta exatamente uma folha e registra uma porcao")
	_check(PROGRESS.is_marked(self, PROGRESS.FOOD_PREPARED) and PROGRESS.count(self) == 4,
		"Preparo efetivo completa os quatro marcos da sessao")
	await _travel_to_forest()
	_check(current_scene.scene_file_path == FOREST and COOKING.portions(self) == 1 and BAG.leaves(self) == 1,
		"Porcao e folha restante persistem na viagem ao mapa anterior")
	await _travel_to_valley()
	_check(COOKING.prepare(self) == "prepared" and BAG.leaves(self) == 0 and COOKING.portions(self) == 2,
		"Segundo preparo consome so a ultima folha sem duplicar refeicao")
	_check(COOKING.prepare(self) != "prepared" and COOKING.portions(self) == 2,
		"Tentar preparar sem folhas nao gera saldo negativo nem porcoes extras")
	_check(BAG.count_item(self, COOKING.RECIPE_ID) == 2, "Dois preparos viram duas porcoes reais na bolsa")
	_check(PROGRESS.count(self) == 4, "Preparo repetido e viagem preservam marcos sem duplicacao")
	await _travel_to_forest()
	_check(current_scene.scene_file_path == FOREST, "Refeicoes preparadas chegam intactas a floresta")
	_check(BAG.count_item(self, COOKING.RECIPE_ID) == 2, "Duas porcoes preservadas entre regioes")
	var fed_slime: Node2D = null
	for candidate in current_scene.slimes:
		if candidate.slime_type == "brotinho" and candidate.befriended:
			fed_slime = candidate
			break
	_check(fed_slime != null, "Brotinho amigo segue disponivel para oferta")
	if fed_slime != null:
		current_scene.player.global_position = fed_slime.global_position + Vector2(0, 24)
		await _settle()
		var hotbar := preload("res://scripts/systems/hotbar_state.gd")
		hotbar.select(self, hotbar.slots(self).find(COOKING.RECIPE_ID))  # porção na mão
		await _settle()
		_check(current_scene.hud_hint.text.contains("[F]"), "HUD oferece F para alimentar slime proximo")
		await _press_f()
		_check(BAG.count_item(self, COOKING.RECIPE_ID) == 1, "Primeira oferta consome apenas uma porcao")
		_check(FOOD.first_food_for(self, fed_slime.persistent_id) == COOKING.RECIPE_ID,
			"Primeira oferta registrada na identidade persistente certa")
		await _press_f()
		_check(BAG.count_item(self, COOKING.RECIPE_ID) == 1,
			"Repetir F no mesmo slime nao consome alimento adicional")
		_check(fed_slime.befriended, "Dar alimento nao desfaz amizade existente")
		await _travel_to_valley()
		_check(current_scene.scene_file_path == VALLEY and BAG.count_item(self, COOKING.RECIPE_ID) == 1,
			"Porcao nao oferecida permanece na bolsa ao voltar ao Vale")
	_change_to_menu()
	await _settle()
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/start_menu.tscn",
		"Menu e acessivel apos o ciclo de cultivo")
	if current_scene != null and current_scene.has_method("_start_game"):
		current_scene._start_game()
		await NEW_GAME.through_selection(self)
		await _settle()
		_check(current_scene.scene_file_path == FOREST, "Novo Jogo retorna a floresta")
		_check(BAG.seeds(self) == 0 and BAG.leaves(self) == 0, "Novo Jogo limpa sementes e folhas")
		_check(COOKING.portions(self) == 0, "Novo Jogo limpa o registro de preparos da sessao")
		_check(BAG.count_item(self, COOKING.RECIPE_ID) == 0 and not has_meta(FOOD.OFFERS_KEY),
			"Novo Jogo limpa porcoes e ofertas, sem conservar saldo de partida anterior")
		_check(FARM.cells(self, "vale").is_empty(), "Novo Jogo limpa a terra arada e as plantas")
		_check(clock.day_number == 1 and clock.get_hour() == 7, "Novo Jogo tambem reinicia o relogio")
		_check(PROGRESS.count(self) == 0 and not has_meta(PROGRESS.KEY),
			"Novo Jogo remove os quatro marcos sem afetar o proximo ciclo")
	_finish()

func _change_to_menu() -> void:
	change_scene_to_file("res://scenes/start_menu.tscn")

func _finish() -> void:
	print("VALLEY_GARDEN: %d checks; %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)


## Amizade é pela comida (2026-11-23): segura uma folha fresca na barra antes do [F].
func _hold_food() -> void:
	var bag := preload("res://scripts/systems/forest_bag.gd")
	var bar := preload("res://scripts/systems/hotbar_state.gd")
	bag.add_item(self, "folhas_frescas", 1)
	bar.select(self, bar.slots(self).find("folhas_frescas"))
	await process_frame

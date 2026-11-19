extends SceneTree
## Validacao nativa: Brotinho -> sementes -> plantar -> crescer -> colher -> viajar -> reset.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const GARDEN := preload("res://scripts/systems/valley_starter_garden.gd")
const VALLEY_LAYOUT := preload("res://scripts/world/valley_layout.gd")
const FOREST := "res://scenes/regions/FlorestaDoDespertarV2.tscn"
const VALLEY := "res://scenes/regions/ValeDasNascentes.tscn"
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
	GameClock.reset_new_game()
	_check(BAG.seeds(self) == 0 and BAG.leaves(self) == 0, "A bolsa comeca sem sementes e folhas")
	_check(not GARDEN.plant(self, GameClock, "norte"), "Nao planta sem sementes")
	_check(not GARDEN.plant(self, GameClock, "invalido"), "Canteiro desconhecido nao consome sementes")
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
	await _press_e()
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
	await _travel_to_valley()
	_check(current_scene != null and current_scene.scene_file_path == VALLEY, "Chegou ao Vale das Nascentes")
	if current_scene == null or current_scene.scene_file_path != VALLEY:
		_finish()
		return
	_check(current_scene.garden_beds.size() == 2, "Dois canteiros estao presentes na cena")
	for bed in current_scene.garden_beds:
		_check(VALLEY_LAYOUT.route_distance(bed.position, VALLEY_LAYOUT.routes()) < 80,
			"Canteiro esta proximo do caminho percorrivel: " + str(bed.get("bed_id")))
	_check(_bag_text(current_scene).contains("2/3"), "Vale mostra sementes trazidas da floresta")
	var north: Node2D = current_scene.garden_beds[0]
	current_scene.player.global_position = north.global_position
	await _settle()
	_check(current_scene.hud_hint.text.contains("Plantar"), "Interface oferece plantar com E")
	await _press_e()
	_check(GARDEN.phase(self, GameClock, "norte") == "growing", "Semente plantada inicia crescimento")
	_check(BAG.seeds(self) == 1, "Plantio consome exatamente uma semente")
	_check(_bag_text(current_scene).contains("1/3"), "Bolsa atualiza imediatamente apos plantio")
	await _press_e()
	_check(BAG.seeds(self) == 1 and GARDEN.phase(self, GameClock, "norte") == "growing",
		"Repetir E durante crescimento nao gasta outra semente")
	GameClock.advance_minutes(60.0)
	_check(GARDEN.phase(self, GameClock, "norte") == "growing", "Uma hora ainda nao amadurece o cultivo")
	_check(GARDEN.minutes_remaining(self, GameClock, "norte") <= 60, "HUD pode consultar tempo restante")
	await _travel_to_forest()
	_check(current_scene.scene_file_path == FOREST, "Voltar a floresta preserva o canteiro")
	_check(BAG.seeds(self) == 1 and GARDEN.phase(self, GameClock, "norte") == "growing",
		"Sementes e crescimento preservados fora do Vale")
	GameClock.advance_minutes(61.0)
	_check(GARDEN.phase(self, GameClock, "norte") == "ready", "Cultivo amadurece mesmo fora do Vale")
	await _travel_to_valley()
	_check(current_scene.scene_file_path == VALLEY, "Volta ao Vale para a colheita")
	north = current_scene.garden_beds[0]
	_check(str(north.call("phase")) == "ready", "Canteiro recriado exibe a planta madura")
	current_scene.player.global_position = north.global_position
	await _settle()
	_check(current_scene.hud_hint.text.contains("Colher"), "HUD oferece colher o produto")
	await _press_e()
	_check(GARDEN.phase(self, GameClock, "norte") == "harvested", "Colheita atualiza canteiro")
	_check(BAG.leaves(self) == 1 and BAG.seeds(self) == 1, "Folhas frescas entram na bolsa sem gastar mais sementes")
	_check(_bag_text(current_scene).contains("folhas frescas 1"), "HUD mostra a colheita")
	await _press_e()
	_check(BAG.leaves(self) == 1 and not GARDEN.harvest(self, GameClock, "norte"),
		"Mesma plantacao nao pode ser colhida duas vezes")
	var south: Node2D = current_scene.garden_beds[1]
	current_scene.player.global_position = south.global_position
	await _settle()
	await _press_e()
	_check(BAG.seeds(self) == 0 and GARDEN.phase(self, GameClock, "sul") == "growing",
		"Segundo canteiro consome a ultima semente")
	_check(not GARDEN.plant(self, GameClock, "norte") and BAG.seeds(self) == 0,
		"Nao reutiliza canteiro antigo sem sementes")
	GameClock.advance_minutes(121.0)
	_check(GARDEN.phase(self, GameClock, "sul") == "ready", "Segundo cultivo cresce pelo GameClock")
	await _press_e()
	_check(BAG.leaves(self) == 2 and BAG.seeds(self) == 0, "Bolsa recebe segunda colheita")
	_check(_bag_text(current_scene).contains("folhas frescas 2"), "HUD atualiza segunda colheita")
	_change_to_menu()
	await _settle()
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/start_menu.tscn",
		"Menu e acessivel apos o ciclo de cultivo")
	if current_scene != null and current_scene.has_method("_start_game"):
		current_scene._start_game()
		await _settle()
		_check(current_scene.scene_file_path == FOREST, "Novo Jogo retorna a floresta")
		_check(BAG.seeds(self) == 0 and BAG.leaves(self) == 0, "Novo Jogo limpa sementes e folhas")
		_check(GARDEN.phase(self, GameClock, "norte") == "empty" and
			GARDEN.phase(self, GameClock, "sul") == "empty", "Novo Jogo reinicia ambos os canteiros")
		_check(GameClock.day_number == 1 and GameClock.get_hour() == 7, "Novo Jogo tambem reinicia o relogio")
	_finish()

func _change_to_menu() -> void:
	change_scene_to_file("res://scenes/start_menu.tscn")

func _finish() -> void:
	print("VALLEY_GARDEN: %d checks; %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)

extends Node2D
## Slimes amigos ajudam na fazenda (pedido do usuário, 2026-11-23): cada espécie tem
## uma função com animação própria. Brotinho planta sementes da bolsa na terra arada
## vazia, Bolhinha rega culturas com sede e Musguinho aduba (cultura adubada e regada
## cresce dois estágios na virada). De dia, um ajudante por espécie amiga anda até a
## cova, toca a animação da função e aplica o efeito. Energia (como no Palworld,
## decisão do usuário 2026-11-23): cada tarefa gasta TASK_COST; trabalham enquanto houver
## energia e ela enche quando o dia vira (dormem à noite).
## shortcut: o ajudante é um sprite à parte, não o slime do habitat; trocar quando os
## slimes amigos puderem seguir o jogador até a fazenda.

const FARM := preload("res://scripts/systems/farm_state.gd")
const CROPS := preload("res://scripts/systems/crop_catalog.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const SPECIES := preload("res://scripts/world/slime_species.gd")
const VARIANTS := preload("res://scripts/systems/slime_variants.gd")
const KEY := "farm_helpers_done"
const FRIEND_KEYS := ["forest_slime_friends", "valley_slime_friends"]
const ROLES := {"brotinho": "plantar", "bolhinha": "regar", "musguinho": "adubar",
	"colhita": "colher", "carreguim": "carregar"}
const CHEST := preload("res://scripts/systems/chest_storage.gd")
const PLACER := preload("res://scripts/world/station_placer.gd")
const CARRY_RADIUS := 360.0  ## Carreguim junta o que está no chão até essa distância da fazenda
const ENERGY_MAX := 100
const TASK_COST := 15  ## ~6 tarefas por dia por espécie
## shortcut: energia por espécie ajudante (um ajudante por espécie hoje); passar a ser por
## slime quando cada slime amigo trabalhar sozinho.
const SPEED := 42.0
const WORK_SECONDS := 1.6
const DAY_HOURS := Vector2i(6, 19)
const NONE := Vector2i(-99999, -99999)

var farm: Node2D  ## farm_field.gd (field_id, refresh)
## Solta a colheita da Colhita no chão (item_drops.spawn); vazio = direto na bolsa.
static var drop: Callable
var _helpers: Dictionary = {}  # species -> {sprite, cell, timer}
var _scan := 0.0


func _init() -> void:
	name = "FarmHelpers"
	y_sort_enabled = true


## Espécies com função que o jogador já fez amizade (em qualquer região).
static func helpers(tree: SceneTree) -> Array:
	var found: Array = []
	for key in FRIEND_KEYS:
		var friends: Dictionary = tree.get_meta(key, {})
		for identity in friends:
			var species := str(identity).get_slice("/", 0)
			if bool(friends[identity]) and ROLES.has(species) and not found.has(species):
				# Disco de ações: "Ficar em casa" tira o ajudante da fazenda.
				if bool((tree.get_meta("slime_at_farm", {}) as Dictionary).get(species, true)): found.append(species)
	return found


## Energia do ajudante da espécie hoje (dia novo = cheia).
static func energy(tree: SceneTree, species: String, day: int) -> int:
	var book: Dictionary = tree.get_meta(KEY, {})
	var entry: Dictionary = book.get(species, {})
	return int(entry.get("energy", ENERGY_MAX)) if int(entry.get("day", -1)) == day else ENERGY_MAX


static func can_work(tree: SceneTree, species: String, day: int) -> bool:
	return energy(tree, species, day) >= TASK_COST


static func _spend(tree: SceneTree, species: String, day: int) -> void:
	var book: Dictionary = tree.get_meta(KEY, {}).duplicate(true)
	book[species] = {"day": day, "energy": energy(tree, species, day) - TASK_COST}
	tree.set_meta(KEY, book)


static func _seed_crop(tree: SceneTree) -> String:
	for id in CROPS.CROPS:
		if BAG.count_item(tree, str(CROPS.CROPS[id].seed)) > 0: return str(id)
	return ""


## Próxima cova onde a espécie pode trabalhar, ou NONE. Cova reservada por outro
## ajudante fica de fora (`taken`).
static func job(tree: SceneTree, field: String, species: String, taken: Array = []) -> Vector2i:
	if species == "brotinho" and _seed_crop(tree).is_empty(): return NONE
	var cells: Array = FARM.cells(tree, field).keys()
	cells.sort()
	for cell: Vector2i in cells:
		if taken.has(cell): continue
		var planted := not FARM.crop(tree, cell, field).is_empty()
		match species:
			"brotinho":
				if not planted: return cell
			"bolhinha":
				if planted and not FARM.is_ready(tree, cell, field) and not FARM.is_watered(tree, cell, field): return cell
			"musguinho":
				if planted and not FARM.is_ready(tree, cell, field) and not FARM.is_fertilized(tree, cell, field): return cell
			"colhita":
				if FARM.is_ready(tree, cell, field): return cell
	return NONE


## Aplica a função da espécie na cova; devolve se algo mudou.
static func apply(tree: SceneTree, field: String, species: String, cell: Vector2i, day: int) -> bool:
	if not can_work(tree, species, day): return false  # cansado: espera a noite
	var ok := false
	match species:
		"brotinho":
			var id := _seed_crop(tree)
			ok = not id.is_empty() and FARM.plant(tree, cell, id, field)
		"bolhinha":
			ok = FARM.water(tree, cell, field)
		"musguinho":
			ok = FARM.fertilize(tree, cell, field)
		"colhita":  # colhe e deixa no chão (o Carreguim leva ao baú)
			var crop := CROPS.get_crop(FARM.crop(tree, cell, field))
			ok = FARM.harvest(tree, cell, field, false)
			if ok and drop.is_valid(): drop.call(str(crop.harvest), 1, Vector2(cell * 32) + Vector2(16, 16))
			elif ok: BAG.add_item(tree, str(crop.harvest), 1)
	if ok: _spend(tree, species, day)
	return ok


func _process(delta: float) -> void:
	if farm == null or not is_instance_valid(farm): return
	var tree := get_tree()
	var day := GameClock.day_number
	var daytime := GameClock.get_hour() >= DAY_HOURS.x and GameClock.get_hour() < DAY_HOURS.y
	_scan -= delta
	if _scan <= 0.0:
		_scan = 1.0
		var wanted := helpers(tree)
		for species: String in wanted:
			if not _helpers.has(species): _spawn(species)
		for species: String in _helpers.keys():
			if not wanted.has(species):  # foi para casa
				(_helpers[species].sprite as Node).queue_free()
				_helpers.erase(species)
	for species: String in _helpers:
		var h: Dictionary = _helpers[species]
		var sprite: AnimatedSprite2D = h.sprite
		if species == "carreguim":
			_carry_step(tree, h, day, daytime, delta)
			continue
		if h.cell == NONE:
			var resting := bool((tree.get_meta("slime_work_off", {}) as Dictionary).get(species, false))  # "Parar de trabalhar"
			if daytime and not resting and can_work(tree, species, day):
				h.cell = job(tree, farm.field_id, species, _taken())
			if h.cell == NONE:
				_play(sprite, "idle")
				continue
		var goal := Vector2(h.cell * 32) + Vector2(16, 22)
		var pace: float = VARIANTS.WORK_SPEED[VARIANTS.best_friend(tree, species, FRIEND_KEYS)]  # raro: 1,5x
		if sprite.position.distance_to(goal) > 2.0:
			sprite.position = sprite.position.move_toward(goal, SPEED * pace * delta)
			sprite.flip_h = goal.x < sprite.position.x
			_play(sprite, "move")
			continue
		_play(sprite, ROLES[species])
		h.timer += delta * pace
		if h.timer < WORK_SECONDS: continue
		if apply(tree, farm.field_id, species, h.cell, day): farm.refresh()
		h.timer = 0.0
		h.cell = NONE


## Carreguim: vai até o item no chão mais perto, leva dentro do corpo até o baú escolhido
## (disco de ações) ou ao mais perto, e deposita. Cada viagem gasta energia.
func _carry_step(tree: SceneTree, h: Dictionary, day: int, daytime: bool, delta: float) -> void:
	var sprite: AnimatedSprite2D = h.sprite
	var drops: Node = drop.get_object() if drop.is_valid() else null
	var pace: float = VARIANTS.WORK_SPEED[VARIANTS.best_friend(tree, "carreguim", FRIEND_KEYS)]
	var resting := bool((tree.get_meta("slime_work_off", {}) as Dictionary).get("carreguim", false))
	if not h.has("cargo"): h.cargo = {}
	var goal := Vector2.INF
	if (h.cargo as Dictionary).is_empty():
		if not daytime or resting or not can_work(tree, "carreguim", day) or not is_instance_valid(drops):
			_play(sprite, "idle")
			return
		goal = drops.call("nearest_ready", sprite.global_position, CARRY_RADIUS)
		if not goal.is_finite():
			_play(sprite, "idle")
			return
		if sprite.global_position.distance_to(goal) <= 6.0:
			h.cargo = drops.call("claim", sprite.global_position, 12.0)
			_show_cargo(sprite, h.cargo)
			return
	else:
		goal = chest_spot(tree, sprite.global_position)
		if not goal.is_finite():
			_play(sprite, "idle")  # sem baú: espera com a carga
			return
		if sprite.global_position.distance_to(goal) <= 10.0:
			CHEST.deposit(tree, str(h.cargo.item), int(h.cargo.amount), str(_chest_id))
			h.cargo = {}
			_show_cargo(sprite, {})
			_spend(tree, "carreguim", day)
			_play(sprite, "carregar")
			return
	sprite.global_position = sprite.global_position.move_toward(goal, SPEED * pace * delta)
	sprite.flip_h = goal.x < sprite.global_position.x
	_play(sprite, "move")


var _chest_id := ""
## Baú de destino do Carreguim nesta região: o escolhido no disco ou o mais perto.
func chest_spot(tree: SceneTree, from: Vector2) -> Vector2:
	var chosen := str(tree.get_meta("carreguim_chest", ""))
	var best := Vector2.INF
	var region_id := str(farm.get("field_id")) if farm else ""
	for chest: Dictionary in PLACER.chests(tree):
		if str(chest.region) != region_id: continue
		var at: Vector2 = chest.at + Vector2(0, 14)
		if str(chest.id) == chosen:
			_chest_id = str(chest.id)
			return at
		if not best.is_finite() or at.distance_to(from) < best.distance_to(from):
			best = at
			_chest_id = str(chest.id)
	return best


## O que o Carreguim leva aparece flutuando dentro do corpo (ícone pequeno).
static func _show_cargo(sprite: AnimatedSprite2D, cargo: Dictionary) -> void:
	var icon := sprite.get_node_or_null("Cargo") as Sprite2D
	if cargo.is_empty():
		if icon: icon.queue_free()
		return
	if icon == null:
		icon = Sprite2D.new()
		icon.name = "Cargo"
		icon.position = Vector2(0, -4)
		icon.scale = Vector2(0.45, 0.45)
		icon.modulate = Color(1, 1, 1, 0.8)
		sprite.add_child(icon)
	icon.texture = preload("res://scripts/systems/item_catalog.gd").icon(str(cargo.item))


func _taken() -> Array:
	var cells: Array = []
	for species in _helpers: cells.append(_helpers[species].cell)
	return cells


func _spawn(species: String) -> void:
	var info := SPECIES.definition(species)
	if info.is_empty(): return
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Helper_" + species
	sprite.sprite_frames = load(str(info.frames))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * float(info.get("scale", 1.0))
	var cells: Array = FARM.cells(get_tree(), farm.field_id).keys()
	var start: Vector2 = Vector2(cells[0] * 32) if not cells.is_empty() else farm.player.global_position if farm.get("player") else Vector2.ZERO
	sprite.position = start + Vector2(48 + 24 * _helpers.size(), 40)
	add_child(sprite)
	_helpers[species] = {"sprite": sprite, "cell": NONE, "timer": 0.0}


static func _play(sprite: AnimatedSprite2D, anim: String) -> void:
	if not sprite.sprite_frames.has_animation(anim): anim = "idle"
	if sprite.animation != anim or not sprite.is_playing(): sprite.play(anim)

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
const ROLES := {"brotinho": "plantar", "bolhinha": "regar", "musguinho": "adubar"}
const ENERGY_MAX := 100
const TASK_COST := 15  ## ~6 tarefas por dia por espécie
## shortcut: energia por espécie ajudante (um ajudante por espécie hoje); passar a ser por
## slime quando cada slime amigo trabalhar sozinho.
const SPEED := 42.0
const WORK_SECONDS := 1.6
const DAY_HOURS := Vector2i(6, 19)
const NONE := Vector2i(-99999, -99999)

var farm: Node2D  ## farm_field.gd (field_id, refresh)
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
				found.append(species)
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
		for species: String in helpers(tree):
			if not _helpers.has(species): _spawn(species)
	for species: String in _helpers:
		var h: Dictionary = _helpers[species]
		var sprite: AnimatedSprite2D = h.sprite
		if h.cell == NONE:
			if daytime and can_work(tree, species, day):
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

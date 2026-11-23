extends RefCounted
## Estado da fazenda na sessão (meta da SceneTree, como a bolsa): células aradas,
## regadas, cultura e estágio. Sem save em disco por enquanto, igual aos demais
## sistemas da sessão.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const CROPS := preload("res://scripts/systems/crop_catalog.gd")
const KEY := "farm_cells"
const STARTER_KEY := "farm_starter_seeds_given"
const LAST_DAY_KEY := "farm_last_day"
## Regador com carga d'água (BACKLOG P2): cada rega gasta 1; enche na água (lago, riacho).
const CAN_KEY := "watering_can_water"
const CAN_MAX := 20
## Kit inicial enquanto não existe loja.
const STARTER_SEEDS := {"semente_cenoura": 8, "semente_beterraba": 6, "semente_repolho": 4}


## Campos separados (Vale, fazenda...): meta KEY = {campo: {célula: dados}}.
static func _fields(tree: SceneTree) -> Dictionary:
	return tree.get_meta(KEY, {}).duplicate(true)


static func cells(tree: SceneTree, field: String = "vale") -> Dictionary:
	return tree.get_meta(KEY, {}).get(field, {})


static func _cells(tree: SceneTree, field: String) -> Dictionary:
	return cells(tree, field).duplicate(true)


static func _save(tree: SceneTree, data: Dictionary, field: String) -> void:
	var fields := _fields(tree)
	fields[field] = data
	tree.set_meta(KEY, fields)


static func cell_data(tree: SceneTree, cell: Vector2i, field: String = "vale") -> Dictionary:
	return cells(tree, field).get(cell, {})


static func is_tilled(tree: SceneTree, cell: Vector2i, field: String = "vale") -> bool:
	return not cell_data(tree, cell, field).is_empty()


static func is_watered(tree: SceneTree, cell: Vector2i, field: String = "vale") -> bool:
	return bool(cell_data(tree, cell, field).get("watered", false))


static func crop(tree: SceneTree, cell: Vector2i, field: String = "vale") -> String:
	return str(cell_data(tree, cell, field).get("crop", ""))


static func stage(tree: SceneTree, cell: Vector2i, field: String = "vale") -> int:
	return int(cell_data(tree, cell, field).get("stage", 0))


static func is_ready(tree: SceneTree, cell: Vector2i, field: String = "vale") -> bool:
	var id := crop(tree, cell, field)
	return not id.is_empty() and stage(tree, cell, field) >= CROPS.last_stage(id)


## O que [F] faz nesta célula: colher > regar > plantar > arar.
static func action_for(tree: SceneTree, cell: Vector2i, seed_crop: String, field: String = "vale") -> String:
	if not is_tilled(tree, cell, field):
		return "till"
	if not crop(tree, cell, field).is_empty():
		if is_ready(tree, cell, field):
			return "harvest"
		return "water" if not is_watered(tree, cell, field) else "wait"
	return "plant"


static func till(tree: SceneTree, cell: Vector2i, field: String = "vale") -> bool:
	if is_tilled(tree, cell, field):
		return false
	var cells := _cells(tree, field)
	cells[cell] = {"watered": false, "crop": "", "stage": 0}
	_save(tree, cells, field)
	return true


static func plant(tree: SceneTree, cell: Vector2i, crop_id: String, field: String = "vale") -> bool:
	var info := CROPS.get_crop(crop_id)
	if info.is_empty() or not is_tilled(tree, cell, field) or not crop(tree, cell, field).is_empty():
		return false
	if not BAG.spend_item(tree, str(info.seed), 1):
		return false
	var cells := _cells(tree, field)
	var data: Dictionary = cells[cell]
	data.crop = crop_id
	data.stage = 0
	cells[cell] = data
	_save(tree, cells, field)
	return true


static func water(tree: SceneTree, cell: Vector2i, field: String = "vale") -> bool:
	if not is_tilled(tree, cell, field) or is_watered(tree, cell, field):
		return false
	var cells := _cells(tree, field)
	cells[cell].watered = true
	_save(tree, cells, field)
	return true


## to_bag false: não põe na bolsa (o chamador solta o item no chão; item_drops).
static func harvest(tree: SceneTree, cell: Vector2i, field: String = "vale", to_bag: bool = true) -> bool:
	if not is_ready(tree, cell, field):
		return false
	var info := CROPS.get_crop(crop(tree, cell, field))
	if to_bag and not BAG.add_item(tree, str(info.harvest), 1):
		return false
	var cells := _cells(tree, field)
	cells[cell].crop = ""
	cells[cell].stage = 0
	_save(tree, cells, field)
	return true


## Virada do dia: cultura regada sobe um estágio; toda a terra seca de novo.
## Terra arada vazia volta a ser grama depois de tantos dias seguidos sem planta
## (BACKLOG P3). Regar conta como cuidado e zera a contagem.
const IDLE_DAYS_TO_GRASS := 3


static func advance_day(tree: SceneTree) -> void:
	var fields := _fields(tree)
	for field in fields:
		var cells: Dictionary = fields[field]
		for cell in cells.keys():
			var data: Dictionary = cells[cell]
			var id := str(data.get("crop", ""))
			if not id.is_empty() and bool(data.get("watered", false)):
				data.stage = mini(int(data.stage) + 1, CROPS.last_stage(id))
			if id.is_empty() and not bool(data.get("watered", false)):
				data["idle"] = int(data.get("idle", 0)) + 1
			else:
				data["idle"] = 0
			data.watered = false
			if int(data.idle) >= IDLE_DAYS_TO_GRASS:
				cells.erase(cell)  # o mato tomou de volta
			else:
				cells[cell] = data
	tree.set_meta(KEY, fields)


## Processa os dias que passaram desde a última vez (o jogador pode estar em outro
## mapa quando o dia vira). Devolve quantos dias foram aplicados.
static func catch_up(tree: SceneTree, current_day: int) -> int:
	var last := int(tree.get_meta(LAST_DAY_KEY, current_day))
	var days := maxi(0, current_day - last)
	for i in days:
		advance_day(tree)
	tree.set_meta(LAST_DAY_KEY, current_day)
	return days


static func grant_starter_seeds(tree: SceneTree) -> bool:
	if tree.get_meta(STARTER_KEY, false):
		return false
	for item in STARTER_SEEDS:
		BAG.add_item(tree, item, STARTER_SEEDS[item])
	tree.set_meta(STARTER_KEY, true)
	return true


static func can_water(tree: SceneTree) -> int:
	return int(tree.get_meta(CAN_KEY, CAN_MAX))


static func fill_can(tree: SceneTree) -> void:
	tree.set_meta(CAN_KEY, CAN_MAX)


## Gasta 1 de água do regador; false se está vazio.
static func use_can(tree: SceneTree) -> bool:
	var left := can_water(tree)
	if left <= 0: return false
	tree.set_meta(CAN_KEY, left - 1)
	return true

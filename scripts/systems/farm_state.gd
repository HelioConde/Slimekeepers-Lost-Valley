extends RefCounted
## Estado da fazenda na sessão (meta da SceneTree, como a bolsa): células aradas,
## regadas, cultura e estágio. Sem save em disco por enquanto, igual aos demais
## sistemas da sessão.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const CROPS := preload("res://scripts/systems/crop_catalog.gd")
const KEY := "farm_cells"
const STARTER_KEY := "farm_starter_seeds_given"
## Kit inicial enquanto não existe loja.
const STARTER_SEEDS := {"semente_cenoura": 8, "semente_beterraba": 6, "semente_repolho": 4}


static func _cells(tree: SceneTree) -> Dictionary:
	return tree.get_meta(KEY, {}).duplicate(true)


static func _save(tree: SceneTree, cells: Dictionary) -> void:
	tree.set_meta(KEY, cells)


static func cell_data(tree: SceneTree, cell: Vector2i) -> Dictionary:
	return tree.get_meta(KEY, {}).get(cell, {})


static func is_tilled(tree: SceneTree, cell: Vector2i) -> bool:
	return not cell_data(tree, cell).is_empty()


static func is_watered(tree: SceneTree, cell: Vector2i) -> bool:
	return bool(cell_data(tree, cell).get("watered", false))


static func crop(tree: SceneTree, cell: Vector2i) -> String:
	return str(cell_data(tree, cell).get("crop", ""))


static func stage(tree: SceneTree, cell: Vector2i) -> int:
	return int(cell_data(tree, cell).get("stage", 0))


static func is_ready(tree: SceneTree, cell: Vector2i) -> bool:
	var id := crop(tree, cell)
	return not id.is_empty() and stage(tree, cell) >= CROPS.last_stage(id)


## O que [E] faz nesta célula: colher > regar > plantar > arar.
static func action_for(tree: SceneTree, cell: Vector2i, seed_crop: String) -> String:
	if not is_tilled(tree, cell):
		return "till"
	if not crop(tree, cell).is_empty():
		if is_ready(tree, cell):
			return "harvest"
		return "water" if not is_watered(tree, cell) else "wait"
	return "plant"


static func till(tree: SceneTree, cell: Vector2i) -> bool:
	if is_tilled(tree, cell):
		return false
	var cells := _cells(tree)
	cells[cell] = {"watered": false, "crop": "", "stage": 0}
	_save(tree, cells)
	return true


static func plant(tree: SceneTree, cell: Vector2i, crop_id: String) -> bool:
	var info := CROPS.get_crop(crop_id)
	if info.is_empty() or not is_tilled(tree, cell) or not crop(tree, cell).is_empty():
		return false
	if not BAG.spend_item(tree, str(info.seed), 1):
		return false
	var cells := _cells(tree)
	var data: Dictionary = cells[cell]
	data.crop = crop_id
	data.stage = 0
	cells[cell] = data
	_save(tree, cells)
	return true


static func water(tree: SceneTree, cell: Vector2i) -> bool:
	if not is_tilled(tree, cell) or is_watered(tree, cell):
		return false
	var cells := _cells(tree)
	cells[cell].watered = true
	_save(tree, cells)
	return true


static func harvest(tree: SceneTree, cell: Vector2i) -> bool:
	if not is_ready(tree, cell):
		return false
	var info := CROPS.get_crop(crop(tree, cell))
	if not BAG.add_item(tree, str(info.harvest), 1):
		return false
	var cells := _cells(tree)
	cells[cell].crop = ""
	cells[cell].stage = 0
	_save(tree, cells)
	return true


## Virada do dia: cultura regada sobe um estágio; toda a terra seca de novo.
static func advance_day(tree: SceneTree) -> void:
	var cells := _cells(tree)
	for cell in cells:
		var data: Dictionary = cells[cell]
		var id := str(data.get("crop", ""))
		if not id.is_empty() and bool(data.get("watered", false)):
			data.stage = mini(int(data.stage) + 1, CROPS.last_stage(id))
		data.watered = false
		cells[cell] = data
	_save(tree, cells)


static func grant_starter_seeds(tree: SceneTree) -> bool:
	if tree.get_meta(STARTER_KEY, false):
		return false
	for item in STARTER_SEEDS:
		BAG.add_item(tree, item, STARTER_SEEDS[item])
	tree.set_meta(STARTER_KEY, true)
	return true

extends RefCounted
## Esquema de snapshot JSON-safe da vertical slice. NAO grava arquivo nem restaura cenas.
## A tela Continuar permanece desativada ate haver restauracao transacional + QA.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const GARDEN := preload("res://scripts/systems/valley_starter_garden.gd")
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
const FOOD := preload("res://scripts/systems/slime_food_session.gd")
const PROGRESS := preload("res://scripts/systems/session_progress_session.gd")
const VERSION := 1
const MAX_AMOUNT := 1000000
const FIELDS := [
	"version", "clock", "bag", "seed_patches", "garden", "harvests",
	"meals_prepared", "food_offers", "progress", "forest_friends", "valley_friends"
]

static func _meta(tree: SceneTree, key: String, fallback: Variant) -> Variant:
	return tree.get_meta(key) if tree.has_meta(key) else fallback

static func _safe_copy(value: Variant) -> Variant:
	if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
		return value.duplicate(true)
	return value

static func _valid_id(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING:
		return false
	var id: String = value
	return not id.is_empty() and id.length() <= 128 and id == id.strip_edges() and not id.contains("\n") and not id.contains("\r") and not id.contains("\t")

static func _int_in_range(value: Variant, low: int, high: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number := float(value)
	return is_finite(number) and number == floorf(number) and number >= low and number <= high

static func _number(value: Variant, low: float, high: float) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) >= low and float(value) <= high

static func _safe_json_value(value: Variant, depth: int = 0) -> bool:
	if depth > 8:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			if value.size() > 1024:
				return false
			for entry in value:
				if not _safe_json_value(entry, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			if value.size() > 1024:
				return false
			for key in value:
				if typeof(key) != TYPE_STRING or not _safe_json_value(value[key], depth + 1):
					return false
			return true
	return false

static func _amounts(data: Variant, allow_zero: bool = false) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	for id in data:
		if not _valid_id(id) or not _int_in_range(data[id], 0 if allow_zero else 1, MAX_AMOUNT):
			return false
	return true

static func _bool_map(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	for id in data:
		if not _valid_id(id) or typeof(data[id]) != TYPE_BOOL:
			return false
	return true

static func _valid_garden(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	for bed_id in data:
		if not GARDEN.BEDS.has(bed_id):
			return false
		var bed: Variant = data[bed_id]
		if typeof(bed) != TYPE_DICTIONARY or bed.size() != 2 or not bed.has("planted_at") or not bed.has("harvested"):
			return false
		if not _number(bed["planted_at"], 0.0, 1440000000.0) or typeof(bed["harvested"]) != TYPE_BOOL:
			return false
	return true

static func _valid_harvests(rows: Variant) -> bool:
	if typeof(rows) != TYPE_ARRAY:
		return false
	var identities := {}
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY or row.size() != 3 or not row.has("cycle") or not row.has("bed_id") or not row.has("resources"):
			return false
		if not _int_in_range(row["cycle"], 0, MAX_AMOUNT) or not GARDEN.BEDS.has(row["bed_id"]) or not _amounts(row["resources"]):
			return false
		var identity: String = "%d/%s" % [int(row["cycle"]), row["bed_id"]]
		if identities.has(identity):
			return false
		identities[identity] = true
	return true

static func _valid_offers(rows: Variant) -> bool:
	if typeof(rows) != TYPE_ARRAY:
		return false
	var seen := {}
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY or row.size() != 2 or not row.has("slime_id") or not row.has("food_id"):
			return false
		if not _valid_id(row["slime_id"]) or not String(row["slime_id"]).contains("/") or row["food_id"] != COOKING.RECIPE_ID:
			return false
		if seen.has(row["slime_id"]):
			return false
		seen[row["slime_id"]] = true
	return true

static func _valid_progress(data: Variant) -> bool:
	if not _bool_map(data):
		return false
	for id in data:
		if not PROGRESS.EVENTS.has(id) or not data[id]:
			return false
	return true

## Validação pura, sem modificar a sessão e sem aceitar objetos, paths ou campos extras.
static func validate(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not _safe_json_value(data):
		return false
	if data.size() != FIELDS.size():
		return false
	for field in FIELDS:
		if not data.has(field):
			return false
	if not _int_in_range(data["version"], VERSION, VERSION):
		return false
	var clock: Variant = data["clock"]
	if typeof(clock) != TYPE_DICTIONARY or clock.size() != 3 or not clock.has("version") or not clock.has("day") or not clock.has("minutes"):
		return false
	if not _int_in_range(clock["version"], 1, 1) or not _int_in_range(clock["day"], 1, MAX_AMOUNT) or not _number(clock["minutes"], 0.0, 1439.999999):
		return false
	return _amounts(data["bag"]) and _bool_map(data["seed_patches"]) and \
		_valid_garden(data["garden"]) and _valid_harvests(data["harvests"]) and \
		_int_in_range(data["meals_prepared"], 0, MAX_AMOUNT) and _valid_offers(data["food_offers"]) and \
		_valid_progress(data["progress"]) and _bool_map(data["forest_friends"]) and _bool_map(data["valley_friends"])

## Captura somente dados declarados. Objetos como cooking_serving_ledger viram contagens.
## Retorna {} quando QUALQUER estado escolhido estiver inválido; nunca conserta em silêncio.
static func capture(tree: SceneTree, clock: Node) -> Dictionary:
	var raw_bag: Variant = _meta(tree, BAG.INVENTORY_KEY, {})
	if not _amounts(raw_bag, true):
		return {}
	if PROGRESS.count(tree) < 0:
		return {}
	var meals: int = COOKING.portions(tree)
	if meals < 0:
		return {}
	var ledger: Dictionary = GARDEN.harvest_record(tree)
	if not ledger.has("cycles"):
		return {}
	var rows: Array = []
	var cycles: Dictionary = ledger["cycles"]
	var cycle_ids := cycles.keys()
	cycle_ids.sort()
	for cycle in cycle_ids:
		var beds: Dictionary = cycles[cycle]
		var bed_ids := beds.keys()
		bed_ids.sort()
		for bed_id in bed_ids:
			rows.append({"cycle": cycle, "bed_id": bed_id, "resources": beds[bed_id].duplicate(true)})
	var snapshot := {
		"version": VERSION,
		"clock": clock.get_save_data().duplicate(true),
		"bag": BAG.inventory_snapshot(tree),
		"seed_patches": _safe_copy(_meta(tree, BAG.PATCHES_KEY, {})),
		"garden": _safe_copy(_meta(tree, GARDEN.KEY, {})),
		"harvests": rows,
		"meals_prepared": meals,
		"food_offers": _safe_copy(_meta(tree, FOOD.OFFERS_KEY, [])),
		"progress": PROGRESS.snapshot(tree),
		"forest_friends": _safe_copy(_meta(tree, BAG.FRIENDS_KEY, {})),
		"valley_friends": _safe_copy(_meta(tree, "valley_slime_friends", {})),
	}
	return snapshot if validate(snapshot) else {}

extends RefCounted
## Canteiros iniciais da sessao: duas sementes, duas colheitas e sem save em disco.
## Reutiliza calculo de maturacao e ledger de colheitas existentes.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const CALCULATOR := preload("res://scripts/systems/crop_stage_calculator.gd")
const LEDGER := preload("res://scripts/systems/garden_harvest_ledger.gd")
const PROGRESS := preload("res://scripts/systems/session_progress_session.gd")
const KEY := "valley_starter_garden"
const LEDGER_KEY := "valley_starter_garden_harvests"
const BEDS := ["norte", "sul"]
const GROWTH_MINUTES := 120.0
const FIRST_CYCLE := 0

static func elapsed_minutes(clock: Node) -> float:
	var now: Dictionary = clock.get_save_data()
	return (int(now.get("day", 1)) - 1) * 1440.0 + float(now.get("minutes", 420.0))

static func phase(tree: SceneTree, clock: Node, bed_id: String) -> String:
	if not BEDS.has(bed_id):
		return "invalid"
	var beds: Dictionary = tree.get_meta(KEY, {})
	if not beds.has(bed_id):
		return "empty"
	var bed: Dictionary = beds[bed_id]
	if bool(bed.get("harvested", false)):
		return "harvested"
	var planted_at: float = float(bed.get("planted_at", INF))
	var stage: Dictionary = CALCULATOR.calculate(planted_at, elapsed_minutes(clock), GROWTH_MINUTES)
	return str(stage.get("phase", "invalid"))

static func minutes_remaining(tree: SceneTree, clock: Node, bed_id: String) -> int:
	if phase(tree, clock, bed_id) != "growing":
		return 0
	var beds: Dictionary = tree.get_meta(KEY, {})
	var planted_at: float = float(beds[bed_id].get("planted_at", INF))
	var stage: Dictionary = CALCULATOR.calculate(planted_at, elapsed_minutes(clock), GROWTH_MINUTES)
	return int(ceil(maxf(0.0, float(stage.get("remaining_minutes", 0.0)))))

static func plant(tree: SceneTree, clock: Node, bed_id: String) -> bool:
	if phase(tree, clock, bed_id) != "empty" or not BAG.spend_seed(tree):
		return false
	var beds: Dictionary = tree.get_meta(KEY, {}).duplicate(true)
	beds[bed_id] = {"planted_at": elapsed_minutes(clock), "harvested": false}
	tree.set_meta(KEY, beds)
	PROGRESS.mark_event(tree, PROGRESS.GARDEN_PLANTED)
	return true

static func harvest_record(tree: SceneTree) -> Dictionary:
	var data: Variant = tree.get_meta(LEDGER_KEY, {"cycles": {}})
	var ledger = LEDGER.new()
	if not ledger.load_save_data(data):
		return {}
	return ledger.get_save_data()

static func harvest(tree: SceneTree, clock: Node, bed_id: String) -> bool:
	if phase(tree, clock, bed_id) != "ready":
		return false
	var saved: Variant = tree.get_meta(LEDGER_KEY, {"cycles": {}})
	var ledger = LEDGER.new()
	if not ledger.load_save_data(saved):
		return false
	if not ledger.record_harvest(bed_id, FIRST_CYCLE, {"folhas_frescas": 1}):
		return false
	# Conferir o inventario inteiro antes de marcar o canteiro como colhido.
	if not BAG.add_item(tree, BAG.LEAVES_ID, 1):
		return false
	var beds: Dictionary = tree.get_meta(KEY, {}).duplicate(true)
	var bed: Dictionary = beds[bed_id]
	bed["harvested"] = true
	beds[bed_id] = bed
	tree.set_meta(KEY, beds)
	tree.set_meta(LEDGER_KEY, ledger.get_save_data())
	PROGRESS.mark_event(tree, PROGRESS.GARDEN_HARVESTED)
	return true

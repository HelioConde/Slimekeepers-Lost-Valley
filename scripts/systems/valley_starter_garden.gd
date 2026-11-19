extends RefCounted
## Pequeno canteiro do vale: 2 sementes -> 2 folhas frescas por partida.
## Tempo em minutos do GameClock, sem temporizadores locais nem save em disco.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const KEY := "valley_starter_garden"
const BEDS := ["norte", "sul"]
const GROWTH_MINUTES := 120.0

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
	if elapsed_minutes(clock) >= float(bed.get("planted_at", INF)) + GROWTH_MINUTES:
		return "ready"
	return "growing"

static func minutes_remaining(tree: SceneTree, clock: Node, bed_id: String) -> int:
	if phase(tree, clock, bed_id) != "growing":
		return 0
	var beds: Dictionary = tree.get_meta(KEY, {})
	var planted_at: float = float(beds[bed_id].get("planted_at", 0.0))
	return int(ceil(maxf(0.0, planted_at + GROWTH_MINUTES - elapsed_minutes(clock))))

static func plant(tree: SceneTree, clock: Node, bed_id: String) -> bool:
	if phase(tree, clock, bed_id) != "empty" or not BAG.spend_seed(tree):
		return false
	var beds: Dictionary = tree.get_meta(KEY, {}).duplicate(true)
	beds[bed_id] = {"planted_at": elapsed_minutes(clock), "harvested": false}
	tree.set_meta(KEY, beds)
	return true

static func harvest(tree: SceneTree, clock: Node, bed_id: String) -> bool:
	if phase(tree, clock, bed_id) != "ready":
		return false
	var beds: Dictionary = tree.get_meta(KEY, {}).duplicate(true)
	var bed: Dictionary = beds[bed_id]
	bed["harvested"] = true
	beds[bed_id] = bed
	tree.set_meta(KEY, beds)
	BAG.add_leaves(tree)
	return true

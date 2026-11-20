extends RefCounted
## Progresso de sessao em SceneTree, usando o validador session_progress_flags.
## Marcos nao sao inventario, conquistas persistentes nem objetivos narrativos canonicos.
const FLAGS := preload("res://scripts/systems/session_progress_flags.gd")
const KEY := "session_progress_flags"
const SEEDS_COLLECTED := "forest.seeds_collected"
const GARDEN_PLANTED := "valley.garden_planted"
const GARDEN_HARVESTED := "valley.garden_harvested"
const FOOD_PREPARED := "valley.food_prepared"
const EVENTS := [SEEDS_COLLECTED, GARDEN_PLANTED, GARDEN_HARVESTED, FOOD_PREPARED]

static func _load(tree: SceneTree) -> Variant:
	var flags = FLAGS.new()
	if tree.has_meta(KEY):
		if not flags.import_state(tree.get_meta(KEY)):
			return null
		# Nao carregar marcos desconhecidos; o vocabulario e intencionalmente fechado.
		for event_id in flags.export_state():
			if not EVENTS.has(event_id):
				return null
	return flags

## Marca exatamente uma vez e somente apos a operacao efetiva concluir.
## Estado inconsistente e rejeitado sem sobrescrita ou geracao retroativa.
static func mark_event(tree: SceneTree, event_id: String) -> bool:
	if not EVENTS.has(event_id):
		return false
	var flags = _load(tree)
	if flags == null or not flags.mark(event_id):
		return false
	tree.set_meta(KEY, flags.export_state())
	return true

static func is_marked(tree: SceneTree, event_id: String) -> bool:
	if not EVENTS.has(event_id):
		return false
	var flags = _load(tree)
	return flags != null and flags.is_marked(event_id)

## Snapshot independente para futura serializacao validada, sem objeto executavel no meta.
static func snapshot(tree: SceneTree) -> Dictionary:
	var flags = _load(tree)
	return flags.export_state() if flags != null else {}

static func count(tree: SceneTree) -> int:
	var flags = _load(tree)
	return flags.count() if flags != null else -1

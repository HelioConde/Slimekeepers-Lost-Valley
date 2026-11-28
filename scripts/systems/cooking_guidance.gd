extends RefCounted
## Orientação breve e mecânica do ciclo coletar → plantar → colher → preparar.
## Derivada do estado real da sessão; texto vazio quando o ciclo já foi concluído.
## Não contém narrativa nem bloqueia o jogador.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const PROGRESS := preload("res://scripts/systems/session_progress_session.gd")

const STEP_TEXTS := {
	&"collect": "Próximo passo: procure sementes silvestres na floresta",
	&"plant": "Próximo passo: plante uma semente num canteiro do Vale",
	&"harvest": "Próximo passo: espere o cultivo crescer e colha as folhas",
	&"prepare": "Próximo passo: prepare uma porção na estação do Vale",
}


static func step_id(tree: SceneTree) -> StringName:
	if PROGRESS.is_marked(tree, PROGRESS.FOOD_PREPARED):
		return &""
	if BAG.leaves(tree) > 0 or PROGRESS.is_marked(tree, PROGRESS.GARDEN_HARVESTED):
		return &"prepare"
	if PROGRESS.is_marked(tree, PROGRESS.GARDEN_PLANTED):
		return &"harvest"
	if BAG.seeds(tree) > 0:
		return &"plant"
	return &"collect"


static func next_step(tree: SceneTree) -> String:
	return STEP_TEXTS.get(step_id(tree), "")

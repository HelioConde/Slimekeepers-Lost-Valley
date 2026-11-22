extends RefCounted
## Protagonista escolhido no Novo Jogo (Bíblia, seção 3: Aren ou Moni). Fica na
## sessão (KEY, salvo em disco com as outras chaves) e diz ao jogador de onde vêm
## os sprites. Saves antigos não têm a chave: viram Aren, o protagonista original.

const KEY := "protagonist"
## Novo Jogo confirmado e despertar ainda não visto. Só a seleção liga; o fim do
## despertar desliga. Saves antigos não têm a chave: nunca repetem a introdução.
const INTRO_KEY := "intro_pending"
const DEFAULT := "aren"

## art: pasta raiz dos sprites top-down (rotations/, animations/Walk|Running/<dir>/,
## tools/hoe|water/<dir>/, wake/<anim>/south/). card_*: poses da tela de seleção.
const ALL := {
	"aren": {
		"name": "Aren",
		"blurb": "Curioso, determinado e com um grande coração.",
		"art": "res://assets/player",
		"walk_south_dir": "south-f96d7729",
		"hoe": "res://assets/Create_a_Hoe_Equippe/animations/The_adventurer_grips_the_tool_handle_firmly._Her_r",
		"water": "res://assets/Create_a_Watering_Ca/animations/The_character_lifts_the_watering_can_from_her_side",
	},
	"moni": {
		"name": "Moni",
		"blurb": "Inventiva, corajosa e sempre pronta para explorar.",
		"art": "res://assets/player_moni",
		"walk_south_dir": "south",
		"hoe": "res://assets/player_moni/tools/hoe",
		"water": "res://assets/player_moni/tools/water",
	},
}


static func current(tree: SceneTree) -> String:
	var id := str(tree.get_meta(KEY, DEFAULT))
	return id if ALL.has(id) else DEFAULT


static func data(tree: SceneTree) -> Dictionary:
	return ALL[current(tree)]


static func choose(tree: SceneTree, id: String) -> bool:
	if not ALL.has(id):
		return false
	tree.set_meta(KEY, id)
	tree.set_meta(INTRO_KEY, true)
	return true


static func intro_pending(tree: SceneTree) -> bool:
	return bool(tree.get_meta(INTRO_KEY, false))


static func finish_intro(tree: SceneTree) -> void:
	tree.set_meta(INTRO_KEY, false)

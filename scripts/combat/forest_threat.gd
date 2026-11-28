extends RefCounted
## Regras dos slimes da Floresta antes do boss (decisões do usuário, 2026-11-27;
## docs/gameplay/BOSS_BROTINHO.md, "Liberar o boss"):
## - matar um slime vale 1 ponto e domar (amizade) vale 5; com 20 pontos o boss aparece;
## - a dificuldade sai da mistura: só domar = fácil, só matar = difícil, misturado = médio;
## - slime morto volta depois de RESPAWN_DAYS dias;
## - antes do boss vencido, slimes não amigos são agressivos (menos a Bolhinha, que foge);
## - o pet (amigo levado pelo disco) ajuda na luta e, desmaiado, descansa até o dia seguinte.
## Só contam os slimes definidos no mapa da Floresta (forest_slime_friends / ids da Floresta).

const FRIENDS_KEY := "forest_slime_friends"
const KILLS_KEY := "forest_slime_kills"  ## int: slimes da Floresta mortos
const DEAD_KEY := "forest_slimes_dead"  ## {persistent_id: dia da morte}
const PET_KEY := "forest_pet"  ## persistent_id do amigo que segue o jogador ("" = nenhum)
const PET_REST_KEY := "forest_pet_rest"  ## {persistent_id: dia em que desmaiou}
const KILL_POINTS := 1
const TAME_POINTS := 5
const UNLOCK_POINTS := 20
const RESPAWN_DAYS := 2
const SLIME_DAMAGE := 6  ## área inicial (decisão do usuário)
const BOSS_HP := {"facil": 0.7, "medio": 1.0, "dificil": 1.3}
const PACIFIED_KEY := "pacified_areas"
const AREA := "floresta"


static func day(tree: SceneTree) -> int:
	var clock := tree.root.get_node_or_null("GameClock")
	return int(clock.get("day_number")) if clock else 1


static func tames(tree: SceneTree) -> int:
	var friends: Dictionary = tree.get_meta(FRIENDS_KEY, {})
	return friends.values().filter(func(v) -> bool: return bool(v)).size()


static func kills(tree: SceneTree) -> int:
	return int(tree.get_meta(KILLS_KEY, 0))


static func points(tree: SceneTree) -> int:
	return kills(tree) * KILL_POINTS + tames(tree) * TAME_POINTS


## "facil" (só domou), "dificil" (só matou) ou "medio" (misturou).
static func difficulty(tree: SceneTree) -> String:
	var k := kills(tree)
	var t := tames(tree)
	if t > 0 and k == 0: return "facil"
	if k > 0 and t == 0: return "dificil"
	return "medio"


static func pacified(tree: SceneTree) -> bool:
	return bool((tree.get_meta(PACIFIED_KEY, {}) as Dictionary).get(AREA, false))


static func record_kill(tree: SceneTree, persistent_id: String) -> void:
	tree.set_meta(KILLS_KEY, kills(tree) + 1)
	var dead: Dictionary = (tree.get_meta(DEAD_KEY, {}) as Dictionary).duplicate()
	dead[persistent_id] = day(tree)
	tree.set_meta(DEAD_KEY, dead)


## Morto há menos de RESPAWN_DAYS dias: o spawn ainda não o traz de volta.
static func is_dead(tree: SceneTree, persistent_id: String) -> bool:
	var dead: Dictionary = tree.get_meta(DEAD_KEY, {})
	if not dead.has(persistent_id): return false
	return day(tree) - int(dead[persistent_id]) < RESPAWN_DAYS


static func pet_id(tree: SceneTree) -> String:
	return str(tree.get_meta(PET_KEY, ""))


## Desmaiado hoje: só pode voltar a acompanhar no dia seguinte.
static func pet_resting(tree: SceneTree, persistent_id: String) -> bool:
	var rest: Dictionary = tree.get_meta(PET_REST_KEY, {})
	return rest.has(persistent_id) and day(tree) <= int(rest[persistent_id])


static func set_pet(tree: SceneTree, persistent_id: String) -> void:
	tree.set_meta(PET_KEY, persistent_id)


static func pet_fainted(tree: SceneTree, persistent_id: String) -> void:
	var rest: Dictionary = (tree.get_meta(PET_REST_KEY, {}) as Dictionary).duplicate()
	rest[persistent_id] = day(tree)
	tree.set_meta(PET_REST_KEY, rest)
	if pet_id(tree) == persistent_id: tree.set_meta(PET_KEY, "")

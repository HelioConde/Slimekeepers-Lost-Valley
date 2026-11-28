extends RefCounted
## Variantes dos slimes (BIBLIA_NARRATIVA §4.1; números em docs/gameplay/SLIMES_VARIANTES.md).
## A espécie define a função; a variante o desempenho. Cada slime tem 1 nível de trabalho.
## O sorteio é fixo por identidade (persistent_id): o mesmo slime é sempre da mesma variante.
## Boss fica fora do sorteio (anomalias, Bíblia §5).

const COMMON := "comum"
const RARE := "raro"
const RAINBOW := "arco_iris"
## Faixas acumuladas do sorteio: 2% arco-íris, 5% raro, resto comum.
const CHANCES := [[RAINBOW, 0.02], [RARE, 0.07]]
const NAMES := {COMMON: "", RARE: "Raro", RAINBOW: "Arco-íris"}
## Velocidade de trabalho (raro 1,5x). Qualidade da colheita do arco-íris: ainda não
## existe sistema de qualidade (PROXIMOS_PASSOS.md).
const WORK_SPEED := {COMMON: 1.0, RARE: 1.5, RAINBOW: 1.0}
const RANK := {COMMON: 0, RAINBOW: 1, RARE: 2}  # melhor ajudante: o mais rápido


static func of(persistent_id: String) -> String:
	var roll := float(posmod(hash(persistent_id + "#variante"), 100000)) / 100000.0
	for band: Array in CHANCES:
		if roll < float(band[1]): return str(band[0])
	return COMMON


## Melhor variante entre os amigos daquela espécie (o ajudante da fazenda usa esta).
static func best_friend(tree: SceneTree, species: String, friend_keys: Array) -> String:
	var best := COMMON
	for key in friend_keys:
		var friends: Dictionary = tree.get_meta(key, {})
		for identity in friends:
			if bool(friends[identity]) and str(identity).get_slice("/", 0) == species:
				var v := of(str(identity))
				if int(RANK[v]) > int(RANK[best]): best = v
	return best

extends RefCounted
## Vida do jogador na sessão (barra do HUD, referência do usuário 2026-11-23).
## shortcut: ainda nada causa dano (combate/perigos não definidos); a barra fica cheia
## até existir uma fonte de dano.

const KEY := "player_health"
const MAX := 100


static func current(tree: SceneTree) -> int:
	return clampi(int(tree.get_meta(KEY, MAX)), 0, MAX)


static func change(tree: SceneTree, amount: int) -> void:
	tree.set_meta(KEY, clampi(current(tree) + amount, 0, MAX))

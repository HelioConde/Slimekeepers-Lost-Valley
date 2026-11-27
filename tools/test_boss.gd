extends SceneTree
## Primeiro boss (docs/gameplay/BOSS_BROTINHO.md): armas, rolamento, arena, golpes
## avisados, rolamento perfeito, derrota (acorda em casa) e vitória (orbe).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_boss.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const HEALTH := preload("res://scripts/systems/health_state.gd")
const ARENA := preload("res://scripts/combat/boss_arena.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func frames(n: int = 3) -> void:
	for i in n: await process_frame


func run() -> void:
	var recipes: Array = load("res://data/crafting/recipes.gd").RECIPES
	for id in ["espada", "arco", "flecha"]:
		check(recipes.any(func(r: Dictionary) -> bool: return r.id == id and r.station == "bancada"), "receita na bancada: " + id)
	set_meta("tutorial_step", 99)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	await frames(20)
	var player: CharacterBody2D = region.get("player")
	var arena: Node2D = region.get_node_or_null("BossArena")
	check(arena != null and arena.global_position.distance_to(Vector2(5110, 1250)) < 1.0, "arena no Mirante Rochoso")
	check(arena.get_node_or_null("EnergyCrystal") != null, "cristal de energia no local do boss")
	# Escada do Mirante (platô ampliado): subir andando chega à arena.
	player.global_position = Vector2(5110, 1600)
	await frames(5)
	var up := InputEventAction.new()
	up.action = "move_up"
	up.pressed = true
	Input.parse_input_event(up)
	await create_timer(1.8).timeout
	var release := InputEventAction.new()
	release.action = "move_up"
	Input.parse_input_event(release)
	await frames(3)
	check(player.global_position.y < 1420.0, "sobe a escada até o platô (y=%.0f)" % player.global_position.y)
	# Rolamento: sem dano enquanto rola.
	check(player.start_roll(Vector2.RIGHT) and player.invulnerable, "Espaço rola e fica sem tomar dano")
	await frames(30)
	check(not player.invulnerable and not player.is_rolling(), "rolamento termina")
	# Arena trancada até liberar.
	player.global_position = arena.global_position
	await frames(5)
	check(not arena.fighting, "sem liberar, a luta não começa")
	set_meta(ARENA.UNLOCK_KEY, true)
	await frames(5)
	check(arena.fighting and is_instance_valid(arena.boss), "liberado: ao entrar, o boss surge e a arena fecha")
	var boss: Node2D = arena.boss
	await create_timer(1.4).timeout  # entrada do boss
	# Espada.
	BAG.add_item(self, "espada", 1)
	BAG.add_item(self, "arco", 1)
	BAG.add_item(self, "flecha", 3)
	HOTBAR.select(self, HOTBAR.slots(self).find("espada"))
	var combat: Node = region.get_node("PlayerCombat")
	player.global_position = boss.global_position + Vector2(-140, 10)  # de longe (golpe largo como no Stardew)
	player.facing = "east"
	var hp: int = boss.hp
	combat.swing()
	await create_timer(1.2).timeout
	check(boss.hp < hp, "espada acerta de longe, a 140 px (%d -> %d)" % [hp, boss.hp])
	var combat_script := load("res://scripts/combat/player_combat.gd")
	check(not combat_script.in_sword_arc(Vector2.ZERO, Vector2.RIGHT, Vector2(-120, 0), 40.0), "espada não acerta atrás do jogador")
	check(not combat_script.in_sword_arc(Vector2.ZERO, Vector2.RIGHT, Vector2(200, 0), 40.0), "espada não acerta além do alcance")
	# Arco: gasta flecha e acerta.
	hp = boss.hp
	player.global_position = boss.global_position + Vector2(-200, 20)
	player.facing = "east"
	check(combat.shoot() and BAG.count_item(self, "flecha") == 2, "arco gasta 1 flecha")
	await create_timer(0.8).timeout
	check(boss.hp < hp, "flecha acerta o boss (%d -> %d)" % [hp, boss.hp])
	# Golpe avisado: parado, toma dano; rolando na hora, perfeito e o boss fica zonzo.
	set_meta(HEALTH.KEY, 100)
	boss.call("_impact", player.global_position, 40.0, 14, Color.RED)
	check(HEALTH.current(self) == 86, "golpe acerta quem não rola (vida %d)" % HEALTH.current(self))
	player.start_roll(Vector2.UP)
	boss.call("_impact", player.global_position, 40.0, 14, Color.RED)
	check(HEALTH.current(self) == 86 and boss.staggered > 0.0, "rolamento perfeito: sem dano e boss zonzo")
	hp = boss.hp
	boss.take_hit(10, player.global_position)
	check(hp - boss.hp == 20, "zonzo: dano dobrado")
	# Derrota: vida 0 -> acorda em casa com metade, boss some.
	set_meta(HEALTH.KEY, 0)
	await frames(3)
	check(not arena.fighting and HEALTH.current(self) == 50 and player.global_position.distance_to(arena.global_position) > 300.0, "derrota: acorda longe da arena com metade da vida")
	check(BAG.count_item(self, "espada") == 1, "derrota não perde itens")
	# Vitória.
	player.global_position = arena.global_position
	await frames(5)
	check(arena.fighting, "sair e voltar reabre a luta")
	boss = arena.boss
	await create_timer(1.4).timeout
	boss.take_hit(9999, player.global_position)
	await create_timer(2.2).timeout
	check(not arena.fighting and ARENA.defeated_here(self), "vitória registrada")
	check(BAG.count_item(self, "orbe_energia") == 1, "vitória dá o orbe de energia")
	check(bool((get_meta(ARENA.PACIFIED_KEY, {}) as Dictionary).get("floresta", false)), "a Floresta fica pacífica")
	player.global_position = arena.global_position + Vector2(600, 0)
	await frames(3)
	player.global_position = arena.global_position
	await frames(5)
	check(not arena.fighting, "boss vencido não volta")
	print("BOSS: %d failures" % failures)
	quit(1 if failures else 0)

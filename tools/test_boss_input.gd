extends SceneTree
## Combate com mouse e teclado de verdade (eventos de entrada, não chamadas diretas):
## nenhum ataque do jogador pode falhar (pedido do usuário, 2026-11-27). Vida infinita.
## Clica em várias partes do boss (centro, folha, bordas) a partir de 8 lados, com a
## espada e com o arco; aperta [F] virado para o boss; clica no meio de um golpe (fila).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_boss_input.gd

const ARENA := preload("res://scripts/combat/boss_arena.gd")
const COMBAT := preload("res://scripts/combat/player_combat.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
var failures := 0
var region: Node2D
var player: CharacterBody2D
var boss: Node2D


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func frames(n: int = 3) -> void:
	for i in n: await process_frame


## Espera a câmera parar (ela segue o jogador com suavização): o clique é convertido
## para a tela com a câmera de agora e o jogo o lê no quadro seguinte.
func settle() -> void:
	var still := 0
	var last := root.get_canvas_transform()
	for i in 180:
		await process_frame
		var now := root.get_canvas_transform()
		still = still + 1 if now.origin.distance_to(last.origin) < 0.01 else 0
		last = now
		if still >= 3: return


## Clique de mouse de verdade num ponto do mundo (passa pela janela e pela câmera).
func click(world: Vector2) -> void:
	await settle()
	var at: Vector2 = root.get_final_transform() * (root.get_canvas_transform() * world)
	await aim_mouse(world)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
		await frames(2)


## Move o mouse até um ponto do mundo (o jogador mira com o mouse).
func aim_mouse(world: Vector2) -> void:
	var at: Vector2 = root.get_final_transform() * (root.get_canvas_transform() * world)
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	await frames(1)


func key_f() -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_F
		event.physical_keycode = KEY_F
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)


func select(item: String) -> void:
	HOTBAR.select(self, HOTBAR.slots(self).find(item))
	await frames(2)


## Põe o jogador a `gap` px da borda do desenho do boss, no ângulo dado, e espera a câmera.
func stand(angle: float, gap: float) -> void:
	var rect: Rect2 = boss.call("hurt_rect")
	var center := rect.get_center()
	var dir := Vector2.from_angle(angle)
	var edge := center
	while rect.has_point(edge): edge += dir  # anda do centro até a borda do desenho
	player.global_position = edge + dir * gap
	player.facing = player._get_direction_name(-dir)
	await create_timer(0.35).timeout
	# Só mira no que aparece na tela (o jogador não clica fora da janela).
	while gap > 20.0 and not on_screen(rect.position) or gap > 20.0 and not on_screen(rect.end):
		gap -= 20.0
		player.global_position = edge + dir * gap
		await create_timer(0.35).timeout


func on_screen(world: Vector2) -> bool:
	return root.get_visible_rect().has_point(root.get_canvas_transform() * world)


func run() -> void:
	set_meta("tutorial_step", 99)
	set_meta(COMBAT.GOD_KEY, true)  # vida infinita no teste
	region = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	current_scene = region
	await frames(20)
	player = region.get("player")
	var arena: Node2D = region.get_node("BossArena")
	set_meta(ARENA.UNLOCK_KEY, true)
	player.global_position = arena.global_position
	await frames(5)
	boss = arena.boss
	await create_timer(1.6).timeout
	boss.set("max_hp", 99999)
	boss.set("hp", 99999)
	BAG.add_item(self, "espada", 1)
	BAG.add_item(self, "arco", 1)
	BAG.add_item(self, "flecha", 99)
	boss.set("_busy", true)  # parte 1: boss parado, mede só a entrada do jogador
	var rect: Rect2 = boss.call("hurt_rect")
	var parts := {"centro": rect.get_center(), "folha": Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.12),
		"borda esquerda": Vector2(rect.position.x + 6, rect.get_center().y), "borda direita": Vector2(rect.end.x - 6, rect.get_center().y),
		"base": Vector2(rect.get_center().x, rect.end.y - 6)}
	var misses: Array[String] = []
	var total := 0
	for side in 8:
		var angle := TAU * side / 8.0
		for weapon in ["espada", "arco"]:
			await select(weapon)
			for part: String in parts:
				await stand(angle, 60.0 if weapon == "espada" else 220.0)
				if BAG.count_item(self, "flecha") < 20: BAG.add_item(self, "flecha", 60)
				var hp: int = boss.hp
				var rect_now: Rect2 = boss.call("hurt_rect")
				await click(parts[part] - rect.get_center() + rect_now.get_center())
				await create_timer(0.75).timeout
				total += 1
				if boss.hp >= hp: misses.append("%s de %d° clicando na %s" % [weapon, int(rad_to_deg(angle)), part])
	check(misses.is_empty(), "%d cliques no boss (8 lados × 5 partes × espada/arco): todos acertam %s" % [total, misses])
	# Teclado: [F] virado para o boss acerta com as duas armas.
	var key_misses: Array[String] = []
	for side in 8:
		var angle := TAU * side / 8.0
		for weapon in ["espada", "arco"]:
			await select(weapon)
			await stand(angle, 40.0 if weapon == "espada" else 200.0)
			if BAG.count_item(self, "flecha") < 20: BAG.add_item(self, "flecha", 60)
			var hp: int = boss.hp
			await aim_mouse(boss.call("hurt_rect").get_center())  # mouse em cima do boss
			await key_f()
			await create_timer(0.75).timeout
			if boss.hp >= hp: key_misses.append("%s de %d°" % [weapon, int(rad_to_deg(angle))])
	check(key_misses.is_empty(), "[F] virado para o boss acerta de 8 lados %s" % [key_misses])
	# Fila: clicar no meio de um golpe não se perde.
	await select("espada")
	await stand(PI, 50.0)
	var before: int = boss.hp
	await click(boss.call("hurt_rect").get_center())
	await create_timer(0.1).timeout
	await click(boss.call("hurt_rect").get_center())  # ainda no meio do primeiro golpe
	await create_timer(1.6).timeout
	check(before - boss.hp >= COMBAT.SWORD_DAMAGE * 2, "dois cliques seguidos = dois golpes (dano %d)" % (before - boss.hp))
	# Parte 2: boss atacando de verdade; clicar sem parar por 8 s, vida infinita.
	boss.set("_busy", false)
	await select("espada")
	var swings := 0
	var hits := 0
	var t := 0.0
	while t < 8.0:
		var r: Rect2 = boss.call("hurt_rect")
		var dir := (player.global_position - r.get_center()).normalized()
		if player.global_position.distance_to(r.get_center()) > 150.0:  # chega perto como um jogador faria
			player.global_position = r.get_center() + dir * 120.0
			await create_timer(0.3).timeout
		var hp: int = boss.hp
		await click(boss.call("hurt_rect").get_center())
		var combat: Node = region.get_node("PlayerCombat")
		var waited := 0.0
		while waited < 0.25 or player.is_using_tool() or float(combat.get("_queued")) > 0.0:  # espera o golpe sair
			await process_frame
			waited += get_root().get_process_delta_time()
		t += waited
		swings += 1
		if boss.hp < hp: hits += 1
		else:
			var rr: Rect2 = boss.call("hurt_rect")
			print("ERROU: no ar=%s zonzo=%.1f dist_borda=%.0f dentro=%s" % [boss.sprite.position.y < float(boss.get("_sprite_y")) - 10.0, float(boss.get("staggered")), player.global_position.distance_to(player.global_position.clamp(rr.position, rr.end)), rr.has_point(player.global_position)])
	check(hits == swings, "boss atacando, vida infinita: %d de %d golpes acertaram" % [hits, swings])
	check(get_meta(COMBAT.GOD_KEY, false) and preload("res://scripts/systems/health_state.gd").current(self) > 0, "vida infinita: o jogador não cai")
	print("BOSS_INPUT: %d failures" % failures)
	quit(1 if failures else 0)

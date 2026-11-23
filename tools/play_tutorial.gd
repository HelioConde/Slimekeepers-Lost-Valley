extends SceneTree
## Joga o tutorial como um jogador (teclas e esperas de verdade, Novo Jogo com
## despertar): em cada dica faz o que ela pede, registra se passou e salva a tela.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/play_tutorial.gd -- [pasta]

const TUT := preload("res://scripts/ui/tutorial_hud.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
var failures := 0
var out := ""
var shot := 0
var region: Node2D
var player: CharacterBody2D


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func snap(tag: String) -> void:
	if out.is_empty(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/tut_%02d_%s.png" % [out, shot, tag])
	shot += 1


func key(code: int, hold := 0.0) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	if hold > 0.0: await create_timer(hold).timeout
	else:
		for i in 3: await process_frame
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	for i in 3: await process_frame


func step() -> int:
	return int(get_meta(TUT.KEY, -1))


func hud_text() -> String:
	var hud: Node = region.get_node_or_null("HUD/Interface/TutorialHud")
	return str(hud._label.text) if hud and hud.visible else "(sem dica)"


## Anda até perto do ponto (teleporte curto: o caminho não é o que se testa aqui).
func go_to(at: Vector2) -> void:
	player.global_position = at + Vector2(0, 10)
	for i in 4: await physics_frame


func spots(item: String) -> Array:
	var forage: Node = region.get("forage")
	var day: int = root.get_node("GameClock").day_number
	var list: Array = forage.spots.filter(func(s: Dictionary) -> bool: return s.item == item and not forage.is_taken(self, s.id, day))
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at.distance_to(player.global_position) < b.at.distance_to(player.global_position))
	return list


func collect(item: String, count: int) -> void:
	for spot: Dictionary in spots(item).slice(0, count + 4):
		if BAG.count_item(self, item) >= count: break
		await go_to(spot.at)
		await key(KEY_F)
		var g: Node = region.get("gathering")
		if OS.has_environment("SK_DEBUG"): print("DBG item=%s pull=%s hint=%s using=%s" % [item, g.get("_pull_id"), region.hud_hint.text, player.is_using_tool()])
		await create_timer(float(region.get("forage").pull_seconds(item)) + 0.8).timeout
		if OS.has_environment("SK_DEBUG"): print("DBG depois pull=%s bag=%s drops=%d" % [g.get("_pull_id"), BAG.count_item(self, item), region.get("item_drops").pending()])
		var wait := Time.get_ticks_msec()  # o item quica no chão antes do ímã levar
		while region.get("item_drops").pending() > 0 and Time.get_ticks_msec() - wait < 5000:
			await process_frame


func run() -> void:
	out = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	preload("res://scripts/systems/session_state.gd").clear_session(self)
	preload("res://scripts/systems/protagonist.gd").choose(self, "moni")
	set_meta("intro_pending", true)
	region = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	player = region.get("player")
	(player.get_node("Camera2D") as Camera2D).position_smoothing_enabled = false
	# Despertar: espera terminar (ou pula com tecla, como o jogador faria).
	var start := Time.get_ticks_msec()
	while step() < 0 and Time.get_ticks_msec() - start < 40000:
		await key(KEY_SPACE)
		await create_timer(0.5).timeout
	check(step() == 0, "tutorial começa depois do despertar (%d)" % step())
	await snap("andar")
	# 1) Andar.
	Input.action_press("move_right")
	await create_timer(2.0).timeout
	Input.action_release("move_right")
	await process_frame
	check(step() == 1, "andar passa (%s)" % hud_text())
	await snap("coletar")
	# 2) Coletar graveto/pedra com um toque.
	await collect("graveto", 1)
	for i in 3: await process_frame  # a dica confere a mochila no quadro seguinte
	check(step() == 1, "1 graveto ainda não passa (%s)" % hud_text())
	await collect("graveto", 2)
	await collect("pedra_pequena", 2)
	for i in 3: await process_frame
	check(step() == 2, "2 gravetos e 2 pedrinhas passam (%s)" % hud_text())
	await snap("dica_3")
	# 3+) Segue o que cada dica pede, na ordem em que aparecem.
	var guard := 0
	while TUT.active(self) and guard < 16:
		guard += 1
		var title := hud_text()
		var before := step()
		print("DICA %d: %s" % [before, title])
		match title:
			"Arrancando mato":
				await collect("fibra", 3)
			"Sua mochila":
				await key(KEY_E)
				await snap("mochila")
				await key(KEY_E)
			"Fabricando corda":
				# Como o jogador fez: abre a mochila e aperta [B] sem fechar.
				await key(KEY_E)
				await key(KEY_B)
				var craft: Node = region.get("crafting_panel")
				check(craft.visible and not region.get("inventory_panel").visible, "[B] com a mochila aberta troca para a fabricação")
				await snap("fabricar")
				craft.call("_craft", "corda")
				await create_timer(0.3).timeout
				await key(KEY_B)
			"Seu primeiro machado":
				await collect("graveto", 2)
				await collect("pedra_pequena", 2)
				await key(KEY_B)
				region.get("crafting_panel").call("_craft", "machado")
				await create_timer(0.3).timeout
				await key(KEY_B)
			"Cortando árvores":
				await key(KEY_1 + HOTBAR.slots(self).find("machado"))
				check(HOTBAR.selected_item(self) == "machado", "tecla da barra escolhe o machado")
				var chop: Node = region.get("choppable")
				var best: Node2D
				for k in chop.trees:
					if chop.is_small(k) and (best == null or chop.trees[k].global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position)):
						best = chop.trees[k]
				if best: await go_to(best.global_position + Vector2(0, 26))
				player.facing = "north"
				await key(KEY_F, 1.6)
				await snap("golpe")
			"Juntando madeira":
				var chop: Node = region.get("choppable")
				var tries := 0
				while BAG.count_item(self, "madeira") < 6 and tries < 30:
					tries += 1
					var t: Dictionary = chop.target(player.global_position)
					if t.is_empty() or (t.kind == "tree" and not chop.is_small(t.key)):
						var best: Node2D
						for k in chop.trees:
							if chop.is_small(k) and not chop.state(self).has(k) and (best == null or chop.trees[k].global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position)):
								best = chop.trees[k]
						await go_to(best.global_position + Vector2(0, 26))
						player.facing = "north"
					await key(KEY_F, 1.6)
					var wait := Time.get_ticks_msec()
					while region.get("item_drops").pending() > 0 and Time.get_ticks_msec() - wait < 5000: await process_frame
					set_meta("player_energy", 100)  # o roteiro não para para dormir
				for i in 3: await process_frame
			"A bancada de trabalho":
				BAG.add_item(self, "corda", 3)  # roteiro: as 3 cordas viriam de mais mato
				BAG.add_item(self, "pedra_pequena", 4)
				await key(KEY_B)
				region.get("crafting_panel").call("_craft", "bancada")
				await create_timer(0.3).timeout
				await key(KEY_B)
			"Colocando a bancada":
				Input.warp_mouse(Vector2.ZERO)  # prévia à frente do jogador
				await key(KEY_1 + HOTBAR.slots(self).find("bancada"))
				await go_to(player.global_position + Vector2(0, 80))
				player.facing = "south"
				await snap("colocar")
				await key(KEY_F)
			"Construindo a bancada":
				var plan: Node2D = region.get("placer").get("_stations")[0]
				await go_to(plan.global_position + Vector2(0, 20))
				await key(KEY_F)
				await snap("construindo")
				await create_timer(10.8).timeout
			"Usando a bancada":
				await snap("usar")
				var placer: Node = region.get("placer")
				var bench: Node2D = placer.get("_stations")[0]
				await go_to(bench.global_position + Vector2(0, 20))
				await key(KEY_F)
				await snap("bancada_aberta")
				await key(KEY_B)
			"Amigos slimes":
				var slime: Node2D = get_nodes_in_group("living_slimes")[0]
				await go_to(slime.global_position + Vector2(-30, 0))
				await key(KEY_F)
			_:
				await create_timer(1.0).timeout
				await snap("leitura")
				await create_timer(10.0).timeout
		await create_timer(0.3).timeout
		check(step() > before, "dica \"%s\" passa fazendo o que ela pede" % title)
		if step() == before: break
	check(not TUT.active(self), "tutorial termina")
	print("PLAY_TUTORIAL: %d failures" % failures)
	quit(1 if failures else 0)

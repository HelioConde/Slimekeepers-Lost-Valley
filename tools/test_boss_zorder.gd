extends SceneTree
## Ordem de desenho no combate (teste do usuário, 2026-11-27: "o jogador quando está
## muito perto está ficando atrás do slime"). Captura a tela com e sem o jogador
## visível e conta quantos pixels mudam onde ele está:
## - abaixo do pé do boss (mais perto da câmera), o jogador aparece na frente;
## - acima do pé do boss (atrás dele), o boss cobre o jogador;
## - aviso no chão nunca cobre o jogador.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_boss_zorder.gd [-- pasta_de_capturas]

const ARENA := preload("res://scripts/combat/boss_arena.gd")
const COMBAT := preload("res://scripts/combat/player_combat.gd")
var failures := 0
var player: CharacterBody2D
var boss: Node2D
var out := ""


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


## Jogador parado num quadro só (as poses de espera trocam a animação sozinhas).
func freeze(on: bool) -> void:
	player.set_process(not on)
	player.set_physics_process(not on)
	if on: player.sprite.pause()
	else: player.sprite.play()


func shot() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


## Pixels que mudam, numa caixa em volta do corpo do jogador, entre jogador visível e escondido.
func player_pixels(name: String) -> int:
	freeze(true)
	await create_timer(1.5).timeout  # câmera para de andar depois do teleporte
	var with_player := await shot()
	player.visible = false
	var without := await shot()
	player.visible = true
	if not out.is_empty(): with_player.save_png("%s/%s.png" % [out, name])
	var scale := Vector2(with_player.get_size()) / root.get_visible_rect().size
	var body: Vector2 = (root.get_canvas_transform() * (player.global_position + Vector2(0, -22))) * scale
	var changed := 0
	for dy in range(-10, 11):
		for dx in range(-5, 6):
			var p := Vector2i(body) + Vector2i(dx, dy)
			if same(with_player.get_pixelv(p), without.get_pixelv(p)): continue
			changed += 1
	freeze(false)
	return changed


## Cores iguais a menos da luz ambiente animada (muda um pouco a cada quadro).
func same(a: Color, b: Color) -> bool:
	return maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), absf(a.b - b.b)) < 0.07


func run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): out = args[0]
	set_meta("tutorial_step", 99)
	set_meta(COMBAT.GOD_KEY, true)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	current_scene = region
	for i in 20: await process_frame
	player = region.get("player")
	var arena: Node2D = region.get_node("BossArena")
	set_meta(ARENA.UNLOCK_KEY, true)
	player.global_position = arena.global_position + Vector2(0, 100)
	await create_timer(2.0).timeout
	boss = arena.boss
	boss.set("_busy", true)
	boss.global_position = arena.global_position
	await create_timer(0.5).timeout
	boss.sprite.pause()
	var rect: Rect2 = boss.call("hurt_rect")
	check(absf(rect.end.y - boss.global_position.y) < 3.0, "origem do boss no pé do desenho (base %.0f, pé %.0f)" % [rect.end.y, boss.global_position.y])
	# Na frente: logo abaixo do pé, colado no boss.
	player.global_position = boss.global_position + Vector2(10, 14)
	player.facing = "north"
	var front := await player_pixels("frente")
	check(front > 40, "colado na frente do boss, o jogador aparece (%d pixels)" % front)
	# Atrás: acima do pé, dentro do desenho do boss.
	player.global_position = boss.global_position + Vector2(0, -rect.size.y * 0.25)
	var behind := await player_pixels("atras")
	check(behind * 10 < front, "atrás do boss, o boss cobre o jogador (%d pixels contra %d na frente)" % [behind, front])
	# De lado, mesma altura do pé + 2: na frente.
	player.global_position = boss.global_position + Vector2(rect.size.x * 0.45, 2)
	var side := await player_pixels("lado")
	check(side > 40, "ao lado e um pouco abaixo do pé, o jogador fica na frente (%d pixels)" % side)
	# Aviso no chão sob o jogador não o cobre.
	# Compara o corpo do jogador sem e com um aviso embaixo: se o aviso ficasse por cima,
	# a cor do corpo mudaria (o aviso é vermelho translúcido).
	player.global_position = boss.global_position + Vector2(0, 160)
	freeze(true)
	player.visible = false
	await create_timer(1.5).timeout  # câmera para de andar depois do teleporte
	var empty := await shot()
	player.visible = true
	await create_timer(0.3).timeout
	var plain := await shot()
	await create_timer(0.2).timeout
	var control := await shot()
	(boss.get("_warnings") as Array).append({"at": player.global_position, "radius": 40.0, "time": 99.0, "total": 99.0, "color": Color(0.85, 0.3, 0.15)})
	await create_timer(0.2).timeout
	var warned := await shot()
	if not out.is_empty():
		warned.save_png("%s/com_aviso.png" % out)
		plain.save_png("%s/sem_aviso.png" % out)
	var scale := Vector2(plain.get_size()) / root.get_visible_rect().size
	var body: Vector2 = (root.get_canvas_transform() * (player.global_position + Vector2(0, -22))) * scale
	var body_px := 0
	var tinted := 0
	var noise := 0
	for dy in range(-10, 11):
		for dx in range(-5, 6):
			var p := Vector2i(body) + Vector2i(dx, dy)
			var d := plain.get_pixelv(p) - empty.get_pixelv(p)
			if maxf(maxf(absf(d.r), absf(d.g)), absf(d.b)) < 0.25: continue  # chão ou sombra, não o corpo
			body_px += 1
			if not same(plain.get_pixelv(p), warned.get_pixelv(p)):
				tinted += 1
			if not same(plain.get_pixelv(p), control.get_pixelv(p)): noise += 1
	freeze(false)
	print("ruído entre dois quadros sem aviso: %d" % noise)
	check(body_px > 25 and tinted * 8 < body_px, "aviso no chão fica embaixo do jogador (%d de %d pixels do corpo mudaram)" % [tinted, body_px])
	# Cristal: atrás dele o jogador some; na frente aparece.
	var crystal: Node2D = arena.get_node("EnergyCrystal")
	player.global_position = crystal.global_position + Vector2(0, 16)
	var crystal_front := await player_pixels("cristal_frente")
	check(crystal_front > 40, "na frente do cristal, o jogador aparece (%d pixels)" % crystal_front)
	print("BOSS_ZORDER: %d failures" % failures)
	quit(1 if failures else 0)

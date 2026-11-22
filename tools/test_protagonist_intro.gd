extends SceneTree
## Fluxo real: menu → Novo Jogo → seleção (hover, clique, confirmar) → Floresta →
## despertar sentado → controle liberado. Também: Voltar retorna ao menu, a escolha
## fica no save e Continuar não repete o despertar.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_protagonist_intro.gd -- [OUT_DIR] [aren|moni]

const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
const SAVE := preload("res://scripts/systems/save_game.gd")
var failures := 0
var out := ""


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func _initialize() -> void:
	call_deferred("run")


func frames(n: int) -> void:
	for i in n: await process_frame


func shot(name: String) -> void:
	if out.is_empty(): return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])


func run() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else ""
	var who: String = args[1] if args.size() > 1 else "aren"
	if not out.is_empty(): DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	SAVE.path = "user://test_intro_save.txt"
	change_scene_to_file("res://scenes/start_menu.tscn")
	await frames(30)
	current_scene.call("_start_game")
	await frames(30)
	check(current_scene.scene_file_path == "res://scenes/protagonist_select.tscn", "Novo Jogo abre a seleção")
	var sel: Control = current_scene
	check(sel.figures.has("aren") and sel.figures.has("moni"), "os dois protagonistas aparecem")
	await shot("01_selecao")
	sel.call("_on_hover", who)
	await frames(20)
	var other := "moni" if who == "aren" else "aren"
	check((sel.figures[who] as Control).modulate.r > (sel.figures[other] as Control).modulate.r, "hover realça um e esmaece o outro")
	check((sel.figures[who] as TextureRect).texture == sel._textures[who][1], "hover: olha por cima do ombro")
	await shot("02_hover_" + who)
	sel.call("_on_unhover", who)
	await frames(20)
	check((sel.figures[who] as TextureRect).texture == sel._textures[who][0], "saída do cursor volta à pose neutra")
	check(sel._confirm.disabled, "confirmar desligado sem escolha")
	sel.call("select", who)
	await frames(10)
	check(sel.selected == who and not sel._confirm.disabled, "clique fixa a escolha e libera Confirmar")
	await shot("03_escolhido_" + who)
	sel.call("_on_back")
	await frames(20)
	check(current_scene.scene_file_path == "res://scenes/start_menu.tscn", "Voltar retorna ao menu")
	current_scene.call("_start_game")
	await frames(20)
	current_scene.call("select", who)
	current_scene.call("_on_confirm")
	await create_timer(0.9).timeout
	await shot("03b_carregando")
	await create_timer(1.2).timeout
	await frames(30)
	check(current_scene.scene_file_path == "res://scenes/regions/FlorestaDoDespertarV2.tscn", "confirmar carrega a Floresta")
	check(PROTAGONIST.current(self) == who, "protagonista registrado: " + who)
	var player: CharacterBody2D = current_scene.get_node("Player")
	var intro: Node = current_scene.get("intro")
	check(is_instance_valid(intro), "despertar começou")
	check(player.current_animation == "sit_idle", "começa sentado (%s)" % player.current_animation)
	await shot("04_sentado")
	var start := player.global_position
	Input.action_press("move_right")
	await create_timer(0.6).timeout
	Input.action_release("move_right")
	check(player.global_position.distance_to(start) < 1.0, "não anda durante o despertar")
	var seen: Array[String] = []
	var t0 := Time.get_ticks_msec()
	while is_instance_valid(intro) and Time.get_ticks_msec() - t0 < 30000:
		if seen.is_empty() or seen[-1] != player.current_animation:
			seen.append(player.current_animation)
			if player.current_animation in ["sit_look_left", "sit_confused", "stand_up"]:
				await create_timer(0.5).timeout
				await shot("05_" + player.current_animation)
		await process_frame
	print("ORDER ", seen)
	var expected := ["sit_idle", "sit_look_left", "sit_look_right", "sit_confused", "stand_up", "idle_south"]
	var ordered := true
	var at := 0
	for name in seen:
		if at < expected.size() and name == expected[at]: at += 1
	check(at == expected.size(), "ordem: sentado → esquerda → direita → confusão → levanta → olha")
	check(not is_instance_valid(intro) and not PROTAGONIST.intro_pending(self), "despertar terminou")
	await frames(10)
	start = player.global_position
	Input.action_press("move_right")
	await create_timer(0.5).timeout
	Input.action_release("move_right")
	check(player.global_position.distance_to(start) > 20.0, "movimento liberado depois de levantar")
	await shot("06_jogando")
	# Save preserva a escolha; Continuar não repete a introdução.
	SAVE.save(self, root.get_node("GameClock"), current_scene.scene_file_path)
	preload("res://scripts/systems/session_state.gd").clear_session(self)
	var region := SAVE.restore(self, root.get_node("GameClock"))
	check(PROTAGONIST.current(self) == who and not PROTAGONIST.intro_pending(self), "save guarda a escolha e não reabre o despertar")
	change_scene_to_file(region)
	await frames(40)
	check(not is_instance_valid(current_scene.get("intro")), "Continuar não repete o despertar")
	SAVE.delete()
	print("PROTAGONIST_INTRO: %d failures" % failures)
	quit(1 if failures else 0)

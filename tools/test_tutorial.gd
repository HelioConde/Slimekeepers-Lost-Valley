extends SceneTree
## Tutorial inicial: cada dica passa quando o jogador faz o que ela pede; [Tab] pula.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_tutorial.gd -- [pasta]

const TUT := preload("res://scripts/ui/tutorial_hud.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func key(code: int) -> void:
	var down := InputEventKey.new()
	down.keycode = code
	down.physical_keycode = code
	down.pressed = true
	root.push_input(down)
	for i in 3: await process_frame
	var up := down.duplicate()
	up.pressed = false
	root.push_input(up)
	for i in 3: await process_frame


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in [BAG.INVENTORY_KEY, "forest_slime_friends", "valley_slime_friends"]:
		if has_meta(k): remove_meta(k)
	set_meta(TUT.KEY, 0)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var hud: Control = region.get_node("HUD/Interface/TutorialHud")
	check(hud.visible and str(hud._label.text).contains("básico") and hud._body.get_child_count() > 8, "primeira dica: andar com as teclas desenhadas")
	if out != "":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/tutorial_0.png" % out)
	Input.action_press("move_right")
	await create_timer(2.0).timeout
	Input.action_release("move_right")
	await process_frame
	check(int(get_meta(TUT.KEY)) == 1, "andar passa para pegar")
	BAG.add_item(self, "graveto")
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 2, "pegar passa para a mochila")
	await key(KEY_E)
	check(int(get_meta(TUT.KEY)) == 3, "abrir a mochila passa para fabricar")
	await key(KEY_E)
	await key(KEY_B)
	check(int(get_meta(TUT.KEY)) == 4, "[B] abre a fabricação e passa")
	var craft: Control = region.get("crafting_panel")
	var build: Button = craft.get("_build")
	check(is_instance_valid(build) and build.visible, "fabricação mostra 'Construir casa'")
	await key(KEY_B)
	check(not craft.visible, "[B] fecha a fabricação")
	await key(KEY_TAB)
	check(int(get_meta(TUT.KEY)) == 5, "[Tab] pula a dica")
	set_meta("forest_slime_friends", {"brotinho/x/0": true})
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 6, "amizade passa a dica")
	await key(KEY_TAB)
	for i in 3: await process_frame
	check(not hud.visible and not TUT.active(self), "tutorial termina e some")
	# Construir casa pelo botão da fabricação; [B] sai do modo construir.
	await key(KEY_B)
	craft.call("start_building")
	var house: Node2D = region.get("house")
	check(not craft.visible and bool(house.get("building")), "'Construir casa' entra no modo construir")
	await key(KEY_B)
	check(not bool(house.get("building")) and not craft.visible, "[B] sai do modo construir sem abrir a fabricação")
	print("TUTORIAL: %d failures" % failures)
	quit(1 if failures else 0)

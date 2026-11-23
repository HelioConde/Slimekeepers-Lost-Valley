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
	BAG.add_item(self, "graveto", 3)
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 1 and str(hud._footer.text).contains("Gravetos 3/8"), "3 gravetos ainda não passam (%s)" % hud._footer.text)
	BAG.add_item(self, "graveto", 5)
	BAG.add_item(self, "pedra_pequena", 6)
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 2, "8 gravetos e 6 pedrinhas passam para o mato")
	BAG.add_item(self, "fibra", 9)
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 3, "9 fibras passam para a mochila")
	await key(KEY_E)
	check(int(get_meta(TUT.KEY)) == 3, "mochila aberta: espera fechar")
	await key(KEY_B)
	var craft: Control = region.get("crafting_panel")
	check(craft.visible and not region.get("inventory_panel").visible, "[B] com a mochila aberta abre a fabricação")
	check(int(get_meta(TUT.KEY)) == 4, "fechar a mochila passa para a corda")
	check(not craft.call("entries", "ferramentas").is_empty() and not (craft.get("_tabs").get_node("Tab_ferramentas") as Control).visible, "[B] não mostra a aba Ferramentas")
	check(not (craft.get("_tabs").get_node("Tab_construcao") as Control).visible, "[B] não mostra Construção (só na bancada)")
	check(hud.position.y < 60, "com janela aberta o balão sobe e não a cobre (%d)" % hud.position.y)
	for n in 3: craft.call("_craft", "corda")
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 5, "3 cordas passam para a bancada")
	craft.call("_craft", "bancada")
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 6 and hud._body.get_children().any(func(c: Node) -> bool: return c.name.begins_with("Mouse_esq")), "fazer a bancada (sem madeira) passa para colocar; ícone do clique")
	await key(KEY_E)
	check(not craft.visible and region.get("inventory_panel").visible, "[E] na fabricação troca para a mochila")
	await key(KEY_E)
	set_meta("placed_stations", [{"region": "floresta", "x": 0, "y": 0, "built": false}])
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 7, "colocar passa para construir")
	set_meta("placed_stations", [{"region": "floresta", "x": 0, "y": 0, "built": true}])
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 8, "construir passa para usar")
	craft.call("open", "bancada")
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 9 and (craft.get("_tabs").get_node("Tab_ferramentas") as Control).visible, "abrir a bancada passa para o machado (aba Ferramentas)")
	check((craft.get("_tabs").get_node("Tab_construcao") as Control).visible and craft.call("entries", "construcao").any(func(r: Dictionary) -> bool: return str(r.id) == "casa"), "bancada tem Construção com a Casa")
	craft.call("_craft", "machado")
	for i in 3: await process_frame
	check(int(get_meta(TUT.KEY)) == 10, "fazer o machado passa para cortar")
	craft.call("close")
	check(hud._body.get_children().any(func(c: Node) -> bool: return c.name.begins_with("Mouse_roda")), "dica da barra mostra o ícone da roda")
	if out != "":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/tutorial_mouse.png" % out)
	await key(KEY_TAB)
	check(int(get_meta(TUT.KEY)) == 11, "[Tab] pula a dica")
	await key(KEY_TAB)
	for i in 3: await process_frame
	check(not hud.visible and not TUT.active(self), "tutorial termina e some")
	remove_meta("placed_stations")
	# Construir casa pelo botão da fabricação; [B] sai do modo construir.
	await key(KEY_B)
	craft.call("start_building")
	var house: Node2D = region.get("house")
	check(not craft.visible and bool(house.get("building")), "'Construir casa' entra no modo construir")
	await key(KEY_B)
	check(not bool(house.get("building")) and not craft.visible, "[B] sai do modo construir sem abrir a fabricação")
	print("TUTORIAL: %d failures" % failures)
	quit(1 if failures else 0)

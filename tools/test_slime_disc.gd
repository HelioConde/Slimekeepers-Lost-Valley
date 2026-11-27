extends SceneTree
## Disco de ações do slime ([F] num slime): carinho, comida (lista só com mais de um tipo),
## trabalho (Carreguim escolhe o baú) e seguir/ficar. Salva a captura do disco.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_slime_disc.gd -- [pasta]

const BAG := preload("res://scripts/systems/forest_bag.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	for i in 3: await process_frame
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	for i in 3: await process_frame


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in [BAG.INVENTORY_KEY, "slime_work_off", "slime_at_farm", "carreguim_chest", "slime_food_known", "slime_fed_day"]:
		if has_meta(k): remove_meta(k)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var slime: Node2D = get_nodes_in_group("living_slimes")[0]
	slime.call("make_friend")
	var player: Node2D = region.get("player")
	player.global_position = slime.global_position + Vector2(0, 24)
	for i in 5: await physics_frame
	await key(KEY_F)
	var disc: Control = region.get("slime_disc")
	check(disc.visible and disc.get("actions").size() == 4, "[F] no slime abre o disco com 4 ações")
	if out != "":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/disco.png" % out)
	Input.warp_mouse(Vector2(640, 200))  # mouse sobre a fatia de cima (carinho)
	await key(KEY_F)  # primeira fatia: carinho
	check(not disc.visible and str(slime.get("reaction")) == "receber_carinho", "carinho pelo disco")
	# Comida: dois tipos -> lista; escolher dá a comida.
	BAG.add_item(self, "cenoura", 2)
	BAG.add_item(self, "cenoura_assada", 1)
	disc.call("open", slime)
	disc.set("hovered", 1)
	disc.call("_choose")
	var list: VBoxContainer = disc.get("_list")
	check(list.visible and list.get_child_count() == 3, "dois tipos de comida abrem a lista (%d botões)" % list.get_child_count())
	# Playtest ID 59: preferência não aparece antes de provar.
	var first := (list.get_child(0) as Button).text
	check(first.contains("(nova)") and (list.get_child(1) as Button).text.contains("(nova)"), "comida não provada aparece como nova (%s)" % first)
	var eaten: String = "cenoura_assada" if first.begins_with("Cenoura assada") else "cenoura"
	(list.get_child(0) as Button).emit_signal("pressed")
	for i in 3: await process_frame
	check(not disc.visible, "escolher a comida fecha o disco")
	var FEEDING := preload("res://scripts/systems/slime_feeding.gd")
	check(FEEDING.known_preference(self, eaten, str(slime.get("slime_type"))) == FEEDING.preference(eaten, str(slime.get("slime_type"))), "comer revela a preferência de %s" % eaten)
	# Trabalho e seguir.
	disc.call("open", slime)
	disc.set("hovered", 2)
	disc.call("_choose")
	var species := str(slime.get("slime_type"))
	check(bool((get_meta("slime_work_off", {}) as Dictionary).get(species, false)), "trabalho liga/desliga (%s)" % species)
	disc.call("open", slime)
	disc.set("hovered", 3)
	disc.call("_choose")
	check(not bool((get_meta("slime_at_farm", {}) as Dictionary).get(species, true)), "seguir/ficar: fica em casa")
	# Carreguim: trabalho abre a lista de baús.
	slime.set("slime_type", "carreguim")
	disc.call("open", slime)
	disc.set("hovered", 2)
	disc.call("_choose")
	check(list.visible and (list.get_child(0) as Button).text.contains("mais perto"), "Carreguim escolhe o baú")
	(list.get_child(0) as Button).emit_signal("pressed")
	check(has_meta("carreguim_chest"), "baú do Carreguim gravado")
	# Playtest ID 60: slime ainda desconfiado só mostra o que dá para fazer (dar comida).
	var stranger: Node2D = null
	for s: Node2D in get_nodes_in_group("living_slimes"):
		if not bool(s.get("befriended")): stranger = s
	if stranger:
		disc.call("open", stranger)
		var ids: Array = disc.get("actions").map(func(a: Dictionary) -> String: return str(a.id))
		check(ids == ["comida"], "slime desconfiado: só Dar comida no disco (%s)" % [ids])
		disc.call("close")
	print("SLIME_DISC: %d failures" % failures)
	quit(1 if failures else 0)

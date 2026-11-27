extends SceneTree
## Balões de fala contextuais (playtest ID 48), na Floresta:
## - árvore grande com machado rudimentar mostra o balão ("vai demorar");
## - repetir no mesmo instante não empilha (um balão por situação, com intervalo);
## - energia baixa sem cama sugere construir; com cama, dormir.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_speech_bubbles.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const HOUSE := preload("res://scripts/systems/house_state.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func press() -> void:
	var down := InputEventAction.new()
	down.action = "interact"
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in [BAG.INVENTORY_KEY, "rocks_broken", "forage_taken", HOUSE.KEY]:
		if has_meta(k): remove_meta(k)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	current_scene = region
	for i in 40: await process_frame
	var speech: Control = region.get("speech")
	var player: Node2D = region.get("player")
	check(speech != null and not speech.visible, "balão existe e começa escondido")
	# Árvore grande + machado rudimentar.
	var trees: Node = region.get("gathering").choppable
	var big_tree := ""
	for key: String in trees.trees:
		if not trees.is_small(key) and (trees.trees[key] as Node2D).global_position.distance_to(Vector2(3200, 3200)) < 2500.0:
			big_tree = key
			break
	check(not big_tree.is_empty(), "há árvore grande cortável")
	BAG.add_item(self, "machado", 1)
	HOTBAR.select(self, HOTBAR.slots(self).find("machado"))
	set_meta("player_energy", 100)
	player.global_position = trees.spot_of(big_tree) + Vector2(0, 40)
	for i in 4: await physics_frame
	for i in 3: await process_frame
	await press()
	await press()
	check(speech.visible and speech.key == "big_tree", "árvore grande com machado rudimentar mostra o balão (%s)" % speech.key)
	var text: String = speech.get_child(0).text
	check(text.contains("grande") and text.contains("machado melhor"), "texto sugere árvore menor ou machado melhor (%s)" % text)
	check(not speech.say("big_tree", "outro texto"), "repetir a mesma situação não empilha")
	check(speech.get_child(0).text == text, "texto do balão intacto")
	check(not speech.say("need_pick", "outra situação"), "outra situação espera o balão atual sumir")
	speech._left = 0.0
	await process_frame
	check(not speech.visible, "balão some sozinho")
	check(not speech.say("big_tree", "de novo"), "intervalo por situação depois que sumiu")
	# Energia baixa: sem cama sugere construir; com cama, dormir.
	set_meta("player_energy", 10)
	for i in 3: await process_frame
	check(speech.visible and speech.key == "low_energy" and speech.get_child(0).text.contains("Construa uma cama"), "energia baixa sem cama sugere construir a cama (%s)" % speech.get_child(0).text)
	speech._left = 0.0
	await process_frame
	set_meta("player_energy", 100)
	for i in 3: await process_frame  # aviso rearma ao recuperar
	var house: Dictionary = HOUSE.empty()
	house.furniture = {Vector2i(2, 2): "cama"}
	set_meta(HOUSE.KEY, house)
	speech._next_at.clear()
	set_meta("player_energy", 10)
	for i in 3: await process_frame
	check(speech.visible and speech.get_child(0).text.contains("dormir"), "energia baixa com cama sugere dormir (%s)" % speech.get_child(0).text)
	print("SPEECH_BUBBLES: %d failures" % failures)
	quit(1 if failures else 0)

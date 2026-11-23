extends SceneTree
const NEW_GAME := preload("res://tools/new_game_helper.gd")
## End-to-end Godot 4.7.2 test: amizade -> coleta -> bolsa -> viagem -> Novo Jogo.
const BAG := preload("res://scripts/systems/forest_bag.gd")
const FOREST := "res://scenes/regions/FlorestaDoDespertarV2.tscn"
const VALLEY := "res://scenes/regions/ValeDasNascentes.tscn"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

func _settle() -> void:
	for i in 6:
		await physics_frame
	await process_frame
	await process_frame

func _press_e() -> void:
	Input.action_press("interact")
	await process_frame
	await process_frame
	Input.action_release("interact")
	await _settle()

func _bag_text(scene: Node2D) -> String:
	var panel := scene.get_node_or_null("HUD/Interface/ForagingBagPanel")
	if panel == null:
		return ""
	return str(panel.get_node("InventoryCount").text)

func _run() -> void:
	var forest := load(FOREST).instantiate() as Node2D
	root.add_child(forest)
	current_scene = forest
	await _settle()
	var patches: Array = forest.get("seed_patches")
	_check(patches.size() == 3, "Three unique seed locations exist in the forest")
	_check(BAG.seeds(self) == 0 and not BAG.has_brotinho_friend(self),
		"Fresh session has no seeds and no Brotinho friendship")
	_check(_bag_text(forest).contains("0/3"), "Bag HUD begins empty")

	var patch: Node2D = null
	for candidate in patches:
		if str(candidate.get("patch_id")) == "bosque_cogumelos":
			patch = candidate
	_check(patch != null, "Safe trail harvest patch is present")
	if patch == null:
		_finish()
		return
	forest.player.global_position = patch.global_position
	await _settle()
	_check(forest.hud_hint.text.contains("Brotinho"),
		"Seed interaction explains the friendship prerequisite")
	await _press_e()
	_check(BAG.seeds(self) == 0 and not bool(patch.get("collected")),
		"Unbefriended player cannot collect seeds")

	var friend: Node2D = null
	for slime in forest.slimes:
		if slime.slime_type == "brotinho":
			friend = slime
			break
	_check(friend != null, "A Brotinho exists in active forest habitat")
	if friend == null:
		_finish()
		return
	forest.player.global_position = friend.global_position + Vector2(0, 24)
	await _settle()
	await _hold_food()
	await _press_e()
	preload("res://scripts/systems/hotbar_state.gd").select(self, -1)
	_check(friend.befriended and BAG.has_brotinho_friend(self),
		"E really befriends Brotinho in gameplay")
	forest.player.global_position = patch.global_position
	await _settle()
	_check(forest.hud_hint.text.contains("Recolher sementes"),
		"Friendship unlocks the harvesting interaction")
	await _press_e()
	_check(BAG.seeds(self) == 1 and bool(patch.get("collected")),
		"E collects exactly one seed from one unique patch")
	_check(_bag_text(forest).contains("1/3"),
		"Visible bag counter updates immediately")
	_check(not bool(patch.call("harvest")) and BAG.seeds(self) == 1,
		"Collected patch cannot produce duplicate items")

	var second: Node2D = null
	for candidate in patches:
		if str(candidate.get("patch_id")) == "jardim_folhas":
			second = candidate
	if second != null:
		forest.player.global_position = second.global_position
		await _settle()
		await _press_e()
	_check(second != null and BAG.seeds(self) == 2,
		"Distinct second patch increases seeds to two")
	forest.player.position = Vector2(3220, 6280)
	await _settle()
	await _press_e()
	_check(current_scene != null and current_scene.scene_file_path == VALLEY,
		"Forest travel brings player into valley")
	if current_scene == null or current_scene.scene_file_path != VALLEY:
		_finish()
		return
	_check(BAG.seeds(self) == 2 and _bag_text(current_scene).contains("2/3"),
		"Bag contents and UI survive entering valley")
	current_scene.player.position = Vector2(1600, 70)
	await _settle()
	await _press_e()
	_check(current_scene.scene_file_path == FOREST,
		"Valley's return gate brings player back to forest")
	if current_scene.scene_file_path != FOREST:
		_finish()
		return
	_check(BAG.seeds(self) == 2 and _bag_text(current_scene).contains("2/3"),
		"Bag survives the full round trip")
	var restored_collected := 0
	for candidate in current_scene.seed_patches:
		if bool(candidate.get("collected")):
			restored_collected += 1
	_check(restored_collected == 2, "Collected patches remain depleted after travel")
	_check(BAG.has_brotinho_friend(self), "Brotinho friendship survives travel")

	change_scene_to_file("res://scenes/start_menu.tscn")
	await _settle()
	var menu := current_scene
	_check(menu != null and menu.scene_file_path == "res://scenes/start_menu.tscn",
		"Returning to title opens the real menu")
	menu._start_game()
	await NEW_GAME.through_selection(self)
	await _settle()
	_check(current_scene != null and current_scene.scene_file_path == FOREST,
		"New Game begins at the correct forest scene")
	_check(BAG.seeds(self) == 0 and not BAG.has_brotinho_friend(self),
		"New Game clears previous bag and slime friendships")
	var reset_collected := 0
	for candidate in current_scene.seed_patches:
		if bool(candidate.get("collected")):
			reset_collected += 1
	_check(reset_collected == 0 and _bag_text(current_scene).contains("0/3"),
		"New Game restores all harvest patches and empty bag")
	_finish()

func _finish() -> void:
	print("FORAGING_LOOP: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


## Amizade é pela comida (2026-11-23): segura uma folha fresca na barra antes do [F].
func _hold_food() -> void:
	var bag := preload("res://scripts/systems/forest_bag.gd")
	var bar := preload("res://scripts/systems/hotbar_state.gd")
	bag.add_item(self, "folhas_frescas", 1)
	bar.select(self, bar.slots(self).find("folhas_frescas"))
	await process_frame

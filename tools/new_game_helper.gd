extends RefCounted
## Para regressões: depois de "Novo Jogo" no menu, passa pela seleção como um
## jogador (escolhe, confirma), espera a Floresta e pula o despertar, para o teste
## seguir com o controle livre. A própria seleção/despertar: test_protagonist_intro.

const FOREST := "res://scenes/regions/FlorestaDoDespertarV2.tscn"


static func through_selection(tree: SceneTree, who: String = "aren") -> void:
	for i in 120:
		await tree.process_frame
		if is_instance_valid(tree.current_scene) and tree.current_scene.has_method("select"): break
	if not is_instance_valid(tree.current_scene) or not tree.current_scene.has_method("select"):
		return
	tree.current_scene.call("select", who)
	tree.current_scene.call("_on_confirm")
	for i in 600:
		await tree.process_frame
		if is_instance_valid(tree.current_scene) and tree.current_scene.scene_file_path == FOREST: break
	for i in 5: await tree.process_frame
	var intro = tree.current_scene.get("intro") if is_instance_valid(tree.current_scene) else null
	if is_instance_valid(intro): intro.call("_enter", 6)  # State.DONE

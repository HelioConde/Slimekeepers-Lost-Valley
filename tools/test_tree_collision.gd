extends SceneTree
## Física de contato das árvores (playtest ID 28): árvore em pé bloqueia o jogador pelo
## tronco; derrubada (toco e tronco caído), deixa passar; sem bloqueios invisíveis.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_tree_collision.gd

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	var chop: Node = region.get("gathering").choppable
	var with_body := 0
	var solid := 0
	for key: String in chop.trees:
		var body := (chop.trees[key] as Node).get_node_or_null("SolidBase") as CollisionObject2D
		if body: with_body += 1
		if body and body.collision_layer != 0: solid += 1
	var hidden := 0
	for key2: String in chop.trees:
		if not (chop.trees[key2] as CanvasItem).is_visible_in_tree(): hidden += 1
	print("ocultas registradas como cortáveis: ", hidden)
	var starters: Array = chop.trees.keys().filter(func(k: String) -> bool: return k.begins_with("StarterTrees/"))
	check(not starters.is_empty() and starters.all(func(k: String) -> bool: return (chop.trees[k] as CanvasItem).is_visible_in_tree()), "árvores do início visíveis (%d)" % starters.size())
	var ghost_solid: Array = chop.trees.keys().filter(func(k: String) -> bool:
		var b := (chop.trees[k] as Node).get_node_or_null("SolidBase") as CollisionObject2D
		return not (chop.trees[k] as CanvasItem).is_visible_in_tree() and b != null and b.collision_layer != 0 and b.can_process())  # desativada (sob a casa) sai da física
	check(ghost_solid.is_empty(), "nenhuma árvore oculta bloqueia (%d)" % ghost_solid.size())
	print("árvores cortáveis: %d · com SolidBase: %d · sólidas: %d" % [chop.trees.size(), with_body, solid])
	check(solid + hidden >= chop.trees.size(), "toda árvore visível em pé tem colisão no tronco")
	# Andar contra uma árvore: o jogador para antes do tronco.
	var player: CharacterBody2D = region.get("player")
	var spawn := Vector2(3200, 3200)
	var key := ""
	for k: String in chop.trees:
		if key == "" or (chop.trees[k] as Node2D).global_position.distance_to(spawn) < (chop.trees[key] as Node2D).global_position.distance_to(spawn): key = k
	var trunk: Vector2 = (chop.trees[key] as Node2D).global_position
	for side: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		player.global_position = trunk + side * 60.0
		await physics_frame
		for i in 30:
			player.velocity = -side * 200.0
			player.move_and_slide()
			await physics_frame
		check(player.global_position.distance_to(trunk) > 8.0, "árvore bloqueia vindo de %s (parou a %.0f px)" % [side, player.global_position.distance_to(trunk)])
	# Derrubada: passa pelo lugar.
	for i in chop.fell_hits(key): chop.strike({"key": key, "kind": "tree"}, 1, 1, trunk + Vector2.LEFT * 30)
	player.global_position = trunk + Vector2.LEFT * 60.0
	await physics_frame
	for i in 40:
		player.velocity = Vector2.RIGHT * 200.0
		player.move_and_slide()
		await physics_frame
	check(player.global_position.x > trunk.x - 6.0, "derrubada, a árvore não bloqueia mais")
	print("TREE_COLLISION: %d failures" % failures)
	quit(1 if failures else 0)

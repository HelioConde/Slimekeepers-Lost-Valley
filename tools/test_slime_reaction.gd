extends SceneTree
## Reação do slime ao carinho/comida: para, olha para o jogador, se espreme e solta
## um coração que sobe e some; amizade nova solta três corações.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_slime_reaction.gd -- [pasta]

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func hearts(slime: Node) -> int:
	return slime.get_children().filter(func(c: Node) -> bool: return c.name.begins_with("ReactionHeart")).size()


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	if has_meta("forest_slime_friends"): remove_meta("forest_slime_friends")
	root.get_node("GameClock").set_time(10, 0)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	var slimes := get_nodes_in_group("living_slimes")
	check(slimes.size() > 0, "há slimes na Floresta (%d)" % slimes.size())
	if slimes.is_empty():
		quit(1)
		return
	var slime: Node2D = slimes[0]
	var player: Node2D = region.get("player")
	(player.get_node("Camera2D") as Camera2D).position_smoothing_enabled = false
	player.global_position = slime.global_position + Vector2(-40, 6)
	for i in 5: await physics_frame
	check(slime.make_friend(), "faz amizade")
	await process_frame
	check(hearts(slime) == 3, "amizade nova solta 3 corações (%d)" % hearts(slime))
	await create_timer(2.3).timeout  # último coração: 0,3 s de atraso + 1,52 s
	check(hearts(slime) == 0, "corações somem (%d)" % hearts(slime))
	slime.react("receber_carinho")
	var sprite: AnimatedSprite2D = slime.get("sprite")
	check(sprite.flip_h, "olha para o jogador (à esquerda)")
	check(str(slime.get("behavior")) == "rest" and not bool(slime.get("_moving")), "para para receber carinho")
	check(hearts(slime) == 1, "carinho solta 1 coração")
	check(str(player.get("facing")).contains("east"), "protagonista vira para o slime (%s)" % player.get("facing"))
	for f in 6:
		await create_timer(0.2).timeout
		if out != "":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/reaction_%02d.png" % [out, f])
	check(is_equal_approx(sprite.scale.x, sprite.scale.y), "volta ao tamanho normal depois de se espremer")
	# Curioso: nota o jogador perto e mostra "!".
	var other: Node2D = slimes[1] if slimes.size() > 1 else slime
	player.global_position = other.global_position + Vector2(60, 0)
	other.set("_happy_time", 0.0)
	other.set("_curiosity_cooldown", 0.0)
	other.set("energy", 0.9)
	other.set("_rng", RandomNumberGenerator.new())
	other.call("_rest", 0.0)
	other.call("_choose_behavior")
	var notices := other.get_children().filter(func(c: Node) -> bool: return c.name.begins_with("ReactionNotice")).size()
	check(str(other.get("behavior")) != "curious" or notices >= 1, "curioso mostra '!' (%s, %d)" % [other.get("behavior"), notices])
	if out != "":
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/notice.png" % out)
	# Brincadeira entre dois slimes: chegam, se olham e soltam um coração.
	var a: Node2D = slimes[2] if slimes.size() > 2 else slime
	var b: Node2D = slimes[3] if slimes.size() > 3 else other
	if a != b:
		a.set("_social_partner", b)
		a.set("behavior", "social")
		b.set("behavior", "curious")
		a.call("_arrive")
		check(str(a.get("behavior")) == "play" and str(b.get("behavior")) == "play", "os dois brincam")
		check(a.get_children().any(func(c: Node) -> bool: return c.name.begins_with("ReactionHeart")), "brincadeira solta coração")
		check(a.get("sprite").flip_h != b.get("sprite").flip_h, "um olha para o outro")
	print("SLIME_REACTION: %d failures" % failures)
	quit(1 if failures else 0)

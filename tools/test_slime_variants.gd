extends SceneTree
## Variantes dos slimes (SLIMES_VARIANTES.md): sorteio fixo por identidade (93/5/2),
## raro e arco-íris com brilho e nome no painel; ajudante raro trabalha 1,5x mais rápido.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_slime_variants.gd -- [pasta]

const VARIANTS := preload("res://scripts/systems/slime_variants.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var count := {"comum": 0, "raro": 0, "arco_iris": 0}
	for i in 20000: count[VARIANTS.of("brotinho/teste/%d" % i)] += 1
	check(absf(count.raro / 20000.0 - 0.05) < 0.01 and absf(count.arco_iris / 20000.0 - 0.02) < 0.006, "sorteio perto de 5%% raro e 2%% arco-íris %s" % count)
	check(VARIANTS.of("brotinho/x/1") == VARIANTS.of("brotinho/x/1"), "mesmo slime, mesma variante")
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var slimes := get_nodes_in_group("living_slimes")
	var a: Node2D = slimes[0]
	var b: Node2D = slimes[1]
	a.set("variant", "raro")
	a.call("_add_variant_glow")
	b.set("variant", "arco_iris")
	b.call("_add_variant_glow")
	check(str(a.call("display_name")).ends_with("Raro") and a.get_node_or_null("VariantSparkles") != null, "raro tem nome e brilho")
	check(str(b.call("display_name")).ends_with("Arco-íris"), "arco-íris no nome")
	# Ajudante: raro entre os amigos da espécie -> 1,5x.
	var raro_id := ""
	for i in 500:
		if VARIANTS.of("brotinho/t/%d" % i) == "raro":
			raro_id = "brotinho/t/%d" % i
			break
	set_meta("forest_slime_friends", {"brotinho/t/x": true, raro_id: true})
	check(VARIANTS.best_friend(self, "brotinho", ["forest_slime_friends"]) == "raro", "ajudante usa o melhor amigo (raro)")
	var player: Node2D = region.get("player")
	player.global_position = a.global_position + Vector2(-40, 10)
	for i in 10: await process_frame
	var bond: Control = region.get_node_or_null("HUD/Interface/SlimeBond")
	check(bond != null and str(bond.get("_role").text).contains("gosta de"), "painel mostra função e comida favorita (%s)" % (bond.get("_role").text if bond else "-"))
	if out != "":
		player.global_position = a.global_position + Vector2(-30, 30)
		b.global_position = a.global_position + Vector2(40, 0)
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/variantes.png" % out)
	print("SLIME_VARIANTS: %d failures" % failures)
	quit(1 if failures else 0)

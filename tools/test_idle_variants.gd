extends SceneTree
## Parado (2026-11-23): Aren e Moni respiram em laço por padrão (8 direções) e, depois de
## alguns segundos, tocam uma variante (olhar em volta, cabelo, mochila, borboleta);
## muito tempo parado medita. Pegar com uma mão: agacha sem "crescer".
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_idle_variants.gd

const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	for who in ["aren", "moni"]:
		var player: CharacterBody2D = load("res://scenes/player.tscn").instantiate()
		player.protagonist_override = who
		root.add_child(player)
		await process_frame
		var frames: SpriteFrames = player.sprite.sprite_frames
		for d in player.DIRS:
			check(frames.get_frame_count("idle_" + d) == 4 and frames.get_animation_loop("idle_" + d), "%s: respira em laço (%s)" % [who, d])
		for v in ["idle_look", "idle_hair", "idle_bag", "idle_c"]:
			check(frames.has_animation(v + "_south") and frames.get_frame_count(v + "_south") == 9, "%s: variante %s" % [who, v])
		check(frames.has_animation("meditate_south"), "%s: medita" % who)
		var stand: Texture2D = frames.get_frame_texture("pick_small_south", 0)
		var low: Texture2D = frames.get_frame_texture("pick_small_south", player.PICK_SMALL_GROUND)
		var top_stand := stand.get_image().get_used_rect().position.y
		var top_low := low.get_image().get_used_rect().position.y
		check(top_low > top_stand + 15, "%s: pegar com uma mão abaixa a cabeça (%d -> %d)" % [who, top_stand, top_low])
		# Parado: variante depois da espera.
		player.facing = "east"
		player.set("_idle_wait", 0.5)
		var played := ""
		for i in 120:
			await physics_frame
			var anim := str(player.current_animation)
			if anim.begins_with("idle") and not ("idle_" + anim.trim_prefix("idle_")) in player.DIRS.map(func(d: String) -> String: return "idle_" + d):
				played = anim
				break
		check(not played.is_empty(), "%s: toca variante parado (%s)" % [who, played])
		player.queue_free()
		await process_frame
	print("IDLE_VARIANTS: %d failures" % failures)
	quit(1 if failures else 0)

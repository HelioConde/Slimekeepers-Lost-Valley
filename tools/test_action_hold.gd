extends SceneTree
## Playtest ID 02: Moni/Aren voltavam ao idle antes do fim da ação. Parado, cada ferramenta e
## cada pose de pegar tem de tocar o clipe inteiro (até o último quadro, pelo tempo dele) e
## só então voltar ao idle; repetir a entrada não corta o golpe ao meio.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_action_hold.gd

const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
const TOOLS := ["axe", "pickaxe", "hoe", "water", "sickle", "shovel", "pick_small", "pick_big"]
const FACINGS := ["south", "east", "west", "north", "south-east", "north-west"]
const TOLERANCE := 0.05  # s: medimos a partir do quadro seguinte à chamada (até 1 quadro de folga)
var failures := 0
var region: Node2D
var player: CharacterBody2D


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	if not ok:
		print("FAIL: " + what)
		failures += 1


func clip_seconds(name: String) -> float:
	var frames: SpriteFrames = player.sprite.sprite_frames
	var units := 0.0
	for i in frames.get_frame_count(name): units += frames.get_frame_duration(name, i)
	return units / frames.get_animation_speed(name)


## Acompanha a ação `anim` a cada quadro até a animação atual mudar; `step` roda a cada quadro
## (simula a entrada do jogador). Devolve o que viu.
func watch(anim: String, step: Callable = Callable()) -> Dictionary:
	var sprite: AnimatedSprite2D = player.sprite
	var st := {"finished": false}
	var on_finished := func() -> void:
		if sprite.animation == anim: st.finished = true
	sprite.animation_finished.connect(on_finished)
	var last := sprite.sprite_frames.get_frame_count(anim) - 1
	var t0 := Time.get_ticks_usec()
	var res := {"seen_last": false, "backwards": false, "paused": false, "finished": false, "elapsed": 0.0, "after": "", "using": true}
	var prev := -1
	while (Time.get_ticks_usec() - t0) < 8000000:
		await process_frame
		if step.is_valid(): step.call()
		if player.current_animation != anim: break
		var f: int = sprite.frame
		if f == last: res.seen_last = true
		if f < prev: res.backwards = true
		if not sprite.is_playing() and not st.finished: res.paused = true
		prev = f
	res.elapsed = (Time.get_ticks_usec() - t0) / 1000000.0
	res.finished = st.finished
	res.after = str(player.current_animation)
	res.using = player.is_using_tool()
	sprite.animation_finished.disconnect(on_finished)
	return res


func settle() -> void:
	while player.is_using_tool(): await process_frame
	for i in 3: await process_frame


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for who in ["aren", "moni"]:
		set_meta(PROTAGONIST.KEY, who)
		region = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
		root.add_child(region)
		for i in 20: await process_frame
		player = region.get("player")
		check(player.sprite.sprite_frames.has_animation("axe_south"), "%s: tem a arte do machado" % who)
		var tested := 0
		for tool in TOOLS:
			for facing in FACINGS:
				player.facing = facing
				var side: String = player.TOOL_FACING.get(facing, facing)
				var anim := "%s_%s" % [tool, side]
				if not player.sprite.sprite_frames.has_animation(anim): continue
				await settle()
				var expected := clip_seconds(anim)
				var length: float = player.play_tool(tool)
				var label := "%s %s (%s)" % [who, anim, facing]
				check(absf(length - expected) < 0.005, "%s: tempo devolvido %.3f = clipe %.3f" % [label, length, expected])
				var r: Dictionary = await watch(anim)
				tested += 1
				check(bool(r.seen_last), "%s: mostra o último quadro antes do idle" % label)
				check(bool(r.finished), "%s: só sai da ação depois do clipe terminar (saiu para %s)" % [label, r.after])
				check(float(r.elapsed) >= expected - TOLERANCE, "%s: dura %.3f s de %.3f s" % [label, r.elapsed, expected])
				check(not bool(r.backwards) and not bool(r.paused), "%s: sem pausa nem retrocesso no meio" % label)
				check(str(r.after).begins_with("idle") and not bool(r.using), "%s: depois do clipe volta ao idle (%s)" % [label, r.after])
		check(tested >= 30, "%s: testou %d ações" % [who, tested])
		# Entrada repetida ([F] segurado): só começa outro golpe depois do clipe; nada é cortado.
		for tool in ["axe", "pickaxe", "hoe", "water", "sickle"]:
			player.facing = "east"
			await settle()
			var anim: String = tool + "_east"
			var st := {"starts": 0, "idle_frames": 0}
			var tick := func() -> void:
				if not player.is_using_tool():
					player.play_tool(tool)
					st.starts += 1
			var sprite: AnimatedSprite2D = player.sprite
			var last := sprite.sprite_frames.get_frame_count(anim) - 1
			var cuts := 0
			var prev_anim := ""
			var prev_frame := -1
			var swings_done := 0
			var t0 := Time.get_ticks_usec()
			while swings_done < 3 and (Time.get_ticks_usec() - t0) < 12000000:
				await process_frame
				tick.call()
				var cur := str(player.current_animation)
				if cur == anim and prev_anim == anim and sprite.frame < prev_frame:
					if prev_frame != last: cuts += 1  # recomeçou antes de chegar ao fim
					swings_done += 1
				if cur != anim and prev_anim == anim and prev_frame != last: cuts += 1  # saiu para o idle no meio
				if cur != anim: st.idle_frames += 1
				prev_anim = cur
				prev_frame = sprite.frame
			check(cuts == 0, "%s %s: entrada repetida não corta o golpe (%d cortes, %d inícios)" % [who, tool, cuts, st.starts])
		# Andar cancela só depois da ação; com a ação terminada o controle volta.
		player.facing = "east"
		await settle()
		player.play_tool("axe")
		Input.action_press("move_right")
		for i in 4: await process_frame
		check(player.velocity == Vector2.ZERO and str(player.current_animation).begins_with("axe_"), "%s: andar não corta o golpe" % who)
		await settle()
		for i in 6: await process_frame
		check(str(player.current_animation).begins_with("walk_") or str(player.current_animation).begins_with("run_"), "%s: com o golpe terminado, andar volta (%s)" % [who, player.current_animation])
		Input.action_release("move_right")
		await settle()
		# Segurar para arrancar/pegar: fica no quadro do chão e, ao soltar, levanta até o fim.
		for action in [["pick_big", player.PICK_BIG_GROUND], ["pick_small", player.PICK_SMALL_GROUND]]:
			for facing in ["south", "east", "west", "north"]:
				player.facing = facing
				await settle()
				var anim := "%s_%s" % [action[0], facing]
				var t0 := Time.get_ticks_usec()
				while (Time.get_ticks_usec() - t0) < 1500000:
					player.hold_pose(action[0], action[1])
					await process_frame
					check(player.current_animation == anim, "%s %s: segurando fica na pose" % [who, anim])
				var left: float = player.release_pose()
				var rest := 0.0
				var frames: SpriteFrames = player.sprite.sprite_frames
				# o clipe só termina depois do quadro atual (que recomeça ao soltar) e dos seguintes
				for i in range(player.sprite.frame, frames.get_frame_count(anim)): rest += frames.get_frame_duration(anim, i)
				rest /= frames.get_animation_speed(anim)
				var r: Dictionary = await watch(anim)
				var label := "%s %s (soltar)" % [who, anim]
				check(bool(r.seen_last), "%s: levanta até o último quadro" % label)
				check(bool(r.finished), "%s: só vai ao idle depois de levantar (saiu para %s)" % [label, r.after])
				check(float(r.elapsed) >= rest - TOLERANCE, "%s: levantar leva %.3f s de %.3f s (release_pose disse %.3f)" % [label, r.elapsed, rest, left])
				check(str(r.after).begins_with("idle") and not bool(r.using), "%s: depois de levantar volta ao idle (%s)" % [label, r.after])
		region.queue_free()
		await process_frame
		remove_meta(PROTAGONIST.KEY)
	print("ACTION_HOLD: %d failures" % failures)
	quit(1 if failures else 0)

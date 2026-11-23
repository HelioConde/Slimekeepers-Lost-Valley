extends SceneTree
## SpriteFrames de um slime novo a partir de <pasta>/v3/<animação>/frame_NNN.png
## (Colhita, Carreguim). Animações sem arte usam a mais parecida (ALIAS) ou o parado.
## Nenhum quadro pode ter braço ou perna (conferir antes).
## Uso: godot --headless --path . --script res://tools/build_placeholder_frames.gd -- <especie>
const ANIMS := ["idle", "move", "blink", "happy", "sleep", "comer", "receber_carinho", "colher", "carregar", "plant", "curious", "play", "comemorar"]
const ALIAS := {"plant": "colher", "curious": "blink", "play": "happy", "comemorar": "happy", "colher": "happy", "carregar": "happy"}
const FPS := {"idle": 6.0, "move": 10.0, "sleep": 4.0}
func _initialize() -> void:
	var sp: String = OS.get_cmdline_user_args()[0]
	var dir := "res://assets/slimes/living_v3/%s/v3" % sp
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for a: String in ANIMS:
		var src := a
		if not ResourceLoader.exists("%s/%s/frame_000.png" % [dir, src]):
			src = str(ALIAS.get(a, "idle"))
			if a == "plant" and not ResourceLoader.exists("%s/%s/frame_000.png" % [dir, src]): src = "carregar"
		if not ResourceLoader.exists("%s/%s/frame_000.png" % [dir, src]): src = "idle"
		frames.add_animation(a)
		frames.set_animation_loop(a, a in ["idle", "move", "sleep"])
		frames.set_animation_speed(a, float(FPS.get(a, 8.0)))
		var k := 0
		while ResourceLoader.exists("%s/%s/frame_%03d.png" % [dir, src, k]):
			frames.add_frame(a, load("%s/%s/frame_%03d.png" % [dir, src, k]))
			k += 1
		print(sp, " ", a, " <- ", src, " (", k, ")")
	print(sp, " salvo ", ResourceSaver.save(frames, dir.get_base_dir() + "/frames.tres"))
	quit()

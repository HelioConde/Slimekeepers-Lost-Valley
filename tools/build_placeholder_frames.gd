extends SceneTree
## SpriteFrames provisório de um slime com um quadro só (todas as animações usam o
## parado), até a arte animada ser aprovada. Arte: <pasta>/v3/idle/frame_000.png.
## Uso: godot --headless --path . --script res://tools/build_placeholder_frames.gd -- <especie>
const ANIMS := ["idle", "move", "blink", "happy", "sleep", "comer", "receber_carinho", "colher", "carregar", "plant", "curious", "play", "comemorar"]
func _initialize() -> void:
	var sp: String = OS.get_cmdline_user_args()[0]
	var dir := "res://assets/slimes/living_v3/%s" % sp
	var tex: Texture2D = load(dir + "/v3/idle/frame_000.png")
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for a in ANIMS:
		frames.add_animation(a)
		frames.set_animation_loop(a, a in ["idle", "move", "sleep"])
		frames.add_frame(a, tex)
	print(sp, " ", ResourceSaver.save(frames, dir + "/frames.tres"))
	quit()

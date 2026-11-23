extends SceneTree
## Slimes novos (2026-11-23) lado a lado no gramado: cada espécie toca parado, comer,
## carinho e a animação da sua função (Brotinho planta, Bolhinha rega, Musguinho aduba).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_slimes.gd -- <pasta>

const SPECIES := {
	"brotinho": ["res://assets/slimes/bestiary/brotinho/brotinho_frames.tres", "plantar"],
	"bolhinha": ["res://assets/slimes/living_v3/bolhinha/frames.tres", "regar"],
	"musguinho": ["res://assets/slimes/living_v3/musguinho/frames.tres", "adubar"],
}
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(960, 540))
	var stage := Node2D.new()
	root.add_child(stage)
	var grass := ColorRect.new()
	grass.color = Color("#6f9a3c")
	grass.size = Vector2(960, 540)
	stage.add_child(grass)
	var sprites := {}
	var x := 0
	for id in SPECIES:
		var frames: SpriteFrames = load(SPECIES[id][0])
		for anim in ["idle", "comer", "receber_carinho", SPECIES[id][1]]:
			check(frames.has_animation(anim) and frames.get_frame_count(anim) > 0, "%s tem %s" % [id, anim])
		var row := []
		for k in 4:
			var s := AnimatedSprite2D.new()
			s.sprite_frames = frames
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale = Vector2.ONE * 2.0
			s.position = Vector2(150 + k * 220, 110 + x * 160)
			stage.add_child(s)
			s.play(["idle", "comer", "receber_carinho", SPECIES[id][1]][k])
			row.append(s)
		sprites[id] = row
		x += 1
	if out != "":
		for k in 14:
			await create_timer(0.12).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/slimes_%02d.png" % [out, k])
	print("SLIMES: %d failures" % failures)
	quit(1 if failures else 0)

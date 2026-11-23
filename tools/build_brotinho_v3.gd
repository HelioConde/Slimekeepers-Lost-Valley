extends SceneTree
## Monta assets/slimes/bestiary/brotinho/brotinho_frames.tres com a arte nova do
## Brotinho (PixelLab, escolhida pelo usuário em 2026-11-23: candidato 4) em
## assets/slimes/bestiary/brotinho/v3/<animação>/frame_NNN.png. Mantém todos os nomes
## de animação que o jogo usa; os que não têm arte nova usam a mais parecida.
const OLD := "res://assets/slimes/bestiary/brotinho/brotinho_frames.tres"
const ART := "res://assets/slimes/bestiary/brotinho/v3/%s/frame_%03d.png"
const ALIAS := {"curious": "blink", "comemorar": "happy", "idle_feliz": "happy", "land": "move", "seguir_jogador": "move",
	"acordar": "blink", "cansado": "sleep", "plantar": "comer", "absorver_sementes": "comer",
	"carregar_sementes": "move", "work_start": "blink", "work_loop": "idle", "work_finish": "happy",
	"procurar_terreno": "blink", "abrir_bau": "comer", "hurt": "blink", "irritado": "blink",
	"attack_charge": "blink", "attack": "move", "lancar_cipos": "happy", "derrotado_dissipar": "sleep"}

func _initialize() -> void:
	var old: SpriteFrames = load(OLD)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var names: Array = Array(old.get_animation_names())
	for extra in ["comer", "receber_carinho"]:
		if not names.has(extra): names.append(extra)
	for anim: String in names:
		var source: String = anim if ResourceLoader.exists(ART % [anim, 0]) else str(ALIAS.get(anim, "idle"))
		frames.add_animation(anim)
		frames.set_animation_speed(anim, old.get_animation_speed(anim) if old.has_animation(anim) else 8.0)
		frames.set_animation_loop(anim, old.get_animation_loop(anim) if old.has_animation(anim) else false)
		var k := 0
		while ResourceLoader.exists(ART % [source, k]):
			frames.add_frame(anim, load(ART % [source, k]))
			k += 1
		print(anim, " <- ", source, " (", k, ")")
	print("save: ", ResourceSaver.save(frames, OLD))
	quit()

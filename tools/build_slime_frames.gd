extends SceneTree
## Monta o SpriteFrames de um slime com a arte nova (PixelLab, 2026-11-23), mantendo os
## nomes de animação que o jogo já usa; os que não têm arte nova usam a mais parecida.
## Arte: <pasta>/<animação>/frame_NNN.png. Nenhum quadro pode ter braço ou perna.
## Uso: godot --headless --path . --script res://tools/build_slime_frames.gd -- <frames.tres> <pasta da arte>
const ALIAS := {"curious": "blink", "comemorar": "happy", "idle_feliz": "happy", "land": "move",
	"seguir_jogador": "move", "acordar": "blink", "cansado": "sleep", "plantar": "comer",
	"absorver_sementes": "comer", "carregar_sementes": "move", "work_start": "blink",
	"work_loop": "idle", "work_finish": "happy", "procurar_terreno": "blink", "abrir_bau": "comer",
	"hurt": "blink", "irritado": "blink", "attack_charge": "blink", "attack": "move",
	"lancar_cipos": "happy", "derrotado_dissipar": "sleep", "jump": "move", "play": "happy",
	"drink": "comer", "splash": "regar", "plant": "idle"}
## Função de cada espécie na fazenda (decisão do usuário): "plant" toca a animação da função.
const ROLE := {"brotinho": "plantar", "bolhinha": "regar", "musguinho": "adubar"}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var tres: String = args[0]
	var art: String = args[1]
	var species := tres.get_base_dir().get_file()
	var old: SpriteFrames = load(tres)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var names: Array = Array(old.get_animation_names())
	for extra in ["comer", "receber_carinho", "blink", "happy", "sleep", "move"]:
		if not names.has(extra): names.append(extra)
	if ROLE.has(species) and not names.has(ROLE[species]): names.append(ROLE[species])
	for anim: String in names:
		var source := anim
		if anim == "plant" and ROLE.has(species): source = ROLE[species]
		if not ResourceLoader.exists("%s/%s/frame_000.png" % [art, source]): source = str(ALIAS.get(anim, "idle"))
		if not ResourceLoader.exists("%s/%s/frame_000.png" % [art, source]): source = "idle"
		frames.add_animation(anim)
		frames.set_animation_speed(anim, old.get_animation_speed(anim) if old.has_animation(anim) else 8.0)
		frames.set_animation_loop(anim, old.get_animation_loop(anim) if old.has_animation(anim) else false)
		var k := 0
		while ResourceLoader.exists("%s/%s/frame_%03d.png" % [art, source, k]):
			frames.add_frame(anim, load("%s/%s/frame_%03d.png" % [art, source, k]))
			k += 1
		print(species, " ", anim, " <- ", source, " (", k, ")")
	print("save: ", ResourceSaver.save(frames, tres))
	quit()

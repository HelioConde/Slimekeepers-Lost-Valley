extends RefCounted
## Efeitos sonoros originais sintetizados no código (como forest_audio.gd e AUDIO.md:
## sem gravações de terceiros nem créditos PixelLab). PCM mono 16 bits, gerados uma vez
## e guardados em cache. Respeitam as opções de áudio do menu (user://presentation.cfg,
## seção audio: ambient_volume e muted).
## Uso: SFX.play(get_tree(), "pegar")  ou  SFX.play(get_tree(), "golpe_machado", posicao)

const RATE := 22050
const SOUNDS := ["pegar", "golpe_machado", "golpe_picareta", "coracao", "fabricar", "corte"]
const GAIN := 0.55
static var _cache: Dictionary = {}
static var _volume := -1.0


static func stream(sound: String) -> AudioStreamWAV:
	if _cache.has(sound): return _cache[sound]
	var samples := _synth(sound)
	var pcm := PackedByteArray()
	pcm.resize(samples.size() * 2)
	for i in samples.size():
		pcm.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = pcm
	_cache[sound] = wav
	return wav


## Toca o efeito; com `at` finito o som vem daquele ponto do mundo.
static func play(tree: SceneTree, sound: String, at: Vector2 = Vector2.INF) -> void:
	if tree == null or tree.current_scene == null or not SOUNDS.has(sound): return
	var volume := _settings_volume()
	if volume <= 0.0: return
	var player: Node
	if at.is_finite():
		var p2 := AudioStreamPlayer2D.new()
		p2.max_distance = 600.0
		p2.position = at
		p2.volume_db = linear_to_db(volume * GAIN)
		p2.stream = stream(sound)
		player = p2
	else:
		var p := AudioStreamPlayer.new()
		p.volume_db = linear_to_db(volume * GAIN)
		p.stream = stream(sound)
		player = p
	player.name = "Sfx_" + sound
	tree.current_scene.add_child(player)
	player.call("play")
	player.connect("finished", player.queue_free)


static func _settings_volume() -> float:
	if _volume < 0.0:
		var cfg := ConfigFile.new()
		_volume = 0.65
		if cfg.load("user://presentation.cfg") == OK:
			_volume = 0.0 if bool(cfg.get_value("audio", "muted", false)) else float(cfg.get_value("audio", "ambient_volume", 0.65))
	return _volume


## Opções do menu mudaram: relê na próxima vez.
static func reload_settings() -> void:
	_volume = -1.0


static func _synth(sound: String) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sound)
	match sound:
		"pegar":  # "plop" subindo, curto e fofo
			return _tone(0.11, func(t: float, k: float) -> float:
				return sin(TAU * (420.0 + 900.0 * k) * t) * (1.0 - k) * (1.0 - k))
		"golpe_machado":  # pancada surda na madeira: grave + ruído abafado
			var low := 0.0
			return _tone(0.16, func(t: float, k: float) -> float:
				low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.18)
				return (sin(TAU * 110.0 * t) * 0.7 + low * 1.4) * exp(-k * 7.0))
		"golpe_picareta":  # "tlim" metálico na pedra
			return _tone(0.22, func(t: float, k: float) -> float:
				var ring := sin(TAU * 1760.0 * t) * 0.5 + sin(TAU * 2640.0 * t) * 0.3
				var tick := rng.randf_range(-1.0, 1.0) * exp(-k * 40.0)
				return (ring + tick * 0.6) * exp(-k * 9.0))
		"corte":  # "fsst" da foice no mato: ruído agudo que passa rápido
			var prev := 0.0
			return _tone(0.14, func(t: float, k: float) -> float:
				var n := rng.randf_range(-1.0, 1.0)
				var hp := n - prev  # passa-alta simples: só o chiado
				prev = n
				return hp * 0.5 * sin(PI * k) * (1.0 - k * 0.5))
		"coracao":  # duas notas de sino (dó e mi)
			return _tone(0.34, func(t: float, k: float) -> float:
				var first := sin(TAU * 1047.0 * t) * exp(-t * 18.0)
				var second := sin(TAU * 1319.0 * maxf(0.0, t - 0.09)) * (exp(-(t - 0.09) * 14.0) if t > 0.09 else 0.0)
				return (first + second) * 0.6)
		"fabricar":  # acorde que sobe (dó, mi, sol)
			return _tone(0.38, func(t: float, k: float) -> float:
				var v := 0.0
				for n in 3:
					var start := n * 0.07
					if t > start: v += sin(TAU * [523.0, 659.0, 784.0][n] * (t - start)) * exp(-(t - start) * 10.0)
				return v * 0.45)
	return PackedFloat32Array()


static func _tone(seconds: float, wave: Callable) -> PackedFloat32Array:
	var count := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	for i in count:
		var t := float(i) / RATE
		var fade_in := minf(1.0, i / 40.0)  # sem estalo no começo
		out[i] = float(wave.call(t, float(i) / count)) * fade_in
	return out

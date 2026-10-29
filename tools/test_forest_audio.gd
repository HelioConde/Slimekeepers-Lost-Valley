extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists("res://scripts/world/forest_audio.gd"):
		_check(false, "Procedural forest audio exists")
		quit(1)
		return
	var audio = load("res://scripts/world/forest_audio.gd").new()
	var player := Node2D.new()
	root.add_child(player)
	var sources: Array[Vector2] = [Vector2(0, 1000), Vector2(300, 2000)]
	audio.configure(player, sources, func(_point: Vector2) -> String: return "clearing")
	root.add_child(audio)
	audio.set_process(false)
	_check(audio.debug_snapshot().cached_clips == 0, "Ready does not block on sound synthesis")
	for i in 400:
		audio._process(1.0 / 60.0)
	var state: Dictionary = audio.debug_snapshot()
	_check(state.cached_clips == 7, "Incremental synthesis completes seven reusable clips")
	for stream: AudioStreamWAV in audio.generated_streams():
		_check(stream.mix_rate == 22050 and not stream.stereo and stream.data.size() > 1000, "Generated clip is real mono PCM at 22050Hz")
		var peak := 0.0
		for frame in range(0, stream.data.size() / 2, 31):
			peak = maxf(peak, absf(float(stream.data.decode_s16(frame * 2)) / 32768.0))
		_check(peak > 0.005 and peak < 0.8, "Synthesized PCM is nonempty and below clipping")
	audio.set_muted(false)
	audio.set_ambient_volume(3.0)
	_check(audio.debug_snapshot().ambient_volume == 1.0, "Ambient gain clamps excessive inputs")
	player.position = Vector2(0, 1000)
	for i in 60:
		audio._process(0.1)
	var near_gain: float = audio.debug_snapshot().water_gain
	player.position = Vector2(6000, 1000)
	for i in 100:
		audio._process(0.1)
	_check(near_gain > 0.9 and audio.debug_snapshot().water_gain < 0.001, "Water fades in near sources and out with distance")
	var weather = load("res://scripts/world/environment_state.gd").new()
	audio.set_environment_state(weather)
	weather.set_conditions("night", 0.8, 0.0, 0.5)
	for i in 120:
		audio._process(0.1)
	_check(audio.debug_snapshot().wind_gain < 0.001, "Calm weather fades wind while retaining other ambience")
	_check(audio.debug_snapshot().environment.period == "night", "Audio consumes the shared night/weather interface")
	audio.set_muted(true)
	_check(audio.debug_snapshot().playing_voices == 0, "Mute stops every environmental voice")
	_check(audio.get_child_count() == 3, "Sound design uses at most three player nodes")
	audio.free()
	player.free()
	# Let the audio server release stopped playback handles before process shutdown.
	await create_timer(0.1).timeout
	print("FOREST_AUDIO: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

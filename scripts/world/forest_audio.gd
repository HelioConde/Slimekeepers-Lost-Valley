extends Node2D
## Original procedural sound: cached 16-bit mono WAV, built in bounded frame jobs.
## No downloads, external recordings, or filesystem writes. See AUDIO.md.
const RATE := 22050
const BUILD_BATCH := 2048
const CLIPS := ["wind", "water", "bird_a", "bird_b", "bird_c", "insects", "leaves"]
const DURATIONS := [11.7, 8.3, 0.75, 0.9, 0.65, 2.6, 0.85]
static var _cache: Dictionary = {}

var _player: Node2D
var _water_points: Array[Vector2] = []
var _zone_resolver: Callable
var _wind: AudioStreamPlayer
var _water: AudioStreamPlayer2D
var _bird: AudioStreamPlayer2D
var _ambient_volume := 0.65
var _muted := false
var _wind_gain := 0.0
var _water_gain := 0.0
var _bird_timer := 18.0
var _control_step := 0.0
var _event_rng := RandomNumberGenerator.new()
var _noise_rng := RandomNumberGenerator.new()
var _building := -1
var _frame := 0
var _frames := 0
var _pcm := PackedByteArray()
var _intro := PackedFloat32Array()
var _filtered := 0.0
var _slow := 0.0
var _phase := 0.0
var _synthesis_usec := 0
var _max_batch_usec := 0
var _environment = preload("res://scripts/world/environment_state.gd").new()
var _last_event := ""
var _event_count := 0

func set_environment_state(state: RefCounted) -> void:
	if state != null and state.has_method("snapshot"):
		_environment = state

func _exit_tree() -> void:
	for voice in [_wind, _water, _bird]:
		if is_instance_valid(voice):
			voice.stop()

func configure(player: Node2D, water_points: Array[Vector2], zone_resolver: Callable = Callable()) -> void:
	_player = player
	_water_points = water_points.duplicate()
	_zone_resolver = zone_resolver

func _ready() -> void:
	_event_rng.seed = 271027
	var prefs := ConfigFile.new()
	if prefs.load("user://presentation.cfg") == OK:
		_ambient_volume = clampf(float(prefs.get_value("audio", "ambient_volume", 0.65)), 0.0, 1.0)
		_muted = bool(prefs.get_value("audio", "muted", false))
	_wind = AudioStreamPlayer.new()
	_wind.name = "ForestWind"
	add_child(_wind)
	_water = AudioStreamPlayer2D.new()
	_water.name = "SouthernWater"
	_water.max_distance = 1400.0
	_water.panning_strength = 0.35
	add_child(_water)
	_bird = AudioStreamPlayer2D.new()
	_bird.name = "OccasionalBird"
	_bird.max_distance = 1600.0
	_bird.panning_strength = 0.45
	add_child(_bird)
	_assign_cached_streams()
	_apply_gains()

func set_ambient_volume(value: float) -> void:
	_ambient_volume = clampf(value, 0.0, 1.0)
	_apply_gains()

func set_muted(value: bool) -> void:
	_muted = value
	if is_instance_valid(_wind) and value:
		_wind.stop()
		_water.stop()
		_bird.stop()
		_wind_gain = 0.0
		_water_gain = 0.0
	_apply_gains()

func _process(delta: float) -> void:
	if _cache.size() < CLIPS.size():
		_build_batch()
	_control_step += delta
	if _control_step < 0.1:
		return
	var elapsed := minf(_control_step, 0.25)
	_control_step = 0.0
	if _muted or not is_instance_valid(_player):
		return
	var zone := str(_zone_resolver.call(_player.global_position)).to_lower() if _zone_resolver.is_valid() else ""
	var sheltered := "mushroom" in zone or "cogumelo" in zone or "antiga" in zone or "dense" in zone
	var conditions: Dictionary = _environment.snapshot()
	var wind_target := (0.65 if sheltered else 1.0) * float(conditions.wind)
	_wind_gain = move_toward(_wind_gain, wind_target, elapsed * 0.25)
	var nearest_distance := INF
	var nearest := Vector2.ZERO
	for source in _water_points:
		var distance := _player.global_position.distance_to(source)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = source
	_water.global_position = nearest
	var desired_water := clampf(1.0 - nearest_distance / 1000.0, 0.0, 1.0) * (1.0 + float(conditions.rain) * 0.15)
	_water_gain = move_toward(_water_gain, desired_water, elapsed * 0.5)
	_apply_gains()
	if _wind.stream != null and not _wind.playing and _ambient_volume > 0.0:
		_wind.play()
	if _water.stream != null and not _water.playing and _water_gain > 0.001 and _ambient_volume > 0.0:
		_water.play()
	elif _water_gain <= 0.001:
		_water.stop()
	_bird_timer -= elapsed
	if _bird_timer <= 0.0 and _cache.has("bird_c"):
		_bird_timer = _event_rng.randf_range(16.0, 38.0) * (1.35 if sheltered else 1.0)
		if _ambient_volume > 0.0:
			var clip: String = CLIPS[_event_rng.randi_range(2, 4)]
			if conditions.period == "night":
				clip = "insects"
				_bird_timer = _event_rng.randf_range(9.0, 18.0)
			elif _event_rng.randf() < 0.3:
				clip = "leaves"
			if not _cache.has(clip):
				return
			_bird.stream = _cache[clip]
			_last_event = clip
			_event_count += 1
			_bird.global_position = _player.global_position + Vector2(_event_rng.randf_range(-420.0, 420.0), _event_rng.randf_range(-300.0, -150.0))
			_bird.pitch_scale = _event_rng.randf_range(0.94, 1.06)
			_bird.play()

func _apply_gains() -> void:
	if not is_instance_valid(_wind):
		return
	var gain := 0.0 if _muted else _ambient_volume
	_wind.volume_db = -24.0 + linear_to_db(maxf(0.00001, gain * _wind_gain))
	_water.volume_db = -25.0 + linear_to_db(maxf(0.00001, gain * _water_gain))
	_bird.volume_db = -29.0 + linear_to_db(maxf(0.00001, gain))

func _assign_cached_streams() -> void:
	if _cache.has("wind"):
		_wind.stream = _cache.wind
	if _cache.has("water"):
		_water.stream = _cache.water

func _build_batch() -> void:
	var started := Time.get_ticks_usec()
	if _building < 0:
		for index in CLIPS.size():
			if not _cache.has(CLIPS[index]):
				_building = index
				break
		if _building < 0:
			return
		_frames = int(float(DURATIONS[_building]) * RATE)
		_pcm.resize(_frames * 2)
		_intro.resize(int(RATE * 0.4))
		_frame = 0
		_filtered = 0.0
		_slow = 0.0
		_phase = 0.0
		_noise_rng.seed = 17027 + _building * 177
	var stop := mini(_frame + BUILD_BATCH, _frames)
	while _frame < stop:
		var time := float(_frame) / RATE
		var noise := _noise_rng.randf_range(-1.0, 1.0)
		_filtered += (noise - _filtered) * (0.045 if _building == 0 else 0.14)
		_slow += (_filtered - _slow) * 0.012
		var value := 0.0
		if _building == 0:
			# Low-pass aperiodic breath, no tonal oscillation or mains-like hum.
			value = _filtered * (0.7 + 0.15 * sin(time * 0.71) + 0.1 * sin(time * 1.17))
		elif _building == 1:
			# Soft broadband stream with a low-frequency bed, no sharp droplets.
			value = ((_filtered - _slow) * 0.65 + _slow * 0.4) * (0.8 + 0.12 * sin(time * 1.31))
		elif _building == 5:
			# Soft night insect stridulation: irregular pulses, never a constant alarm tone.
			var pulse := pow(maxf(0.0, sin(time * 17.0) * sin(time * 4.3)), 2.0)
			value = sin(time * TAU * 3600.0) * pulse * 0.055 * sin(time / DURATIONS[_building] * PI)
		elif _building == 6:
			# Short filtered-noise rustle, shared event voice with bird calls.
			value = (_filtered - _slow) * 0.65 * pow(sin(time / DURATIONS[_building] * PI), 2.0)
		else:
			# Two or three short frequency-swept whistles separated by silence.
			var pulse_length := 0.21 if _building != 3 else 0.27
			var pulse := fmod(time, pulse_length) / pulse_length
			var envelope := pow(maxf(0.0, sin(minf(pulse / 0.68, 1.0) * PI)), 2.0)
			var frequency := 2450.0 + float(_building - 2) * 320.0 + sin(pulse * PI) * 1100.0 - pulse * 700.0
			_phase += TAU * frequency / RATE
			value = sin(_phase) * envelope * 0.22 * sin(time / float(DURATIONS[_building]) * PI)
		if _building < 2:
			if _frame < _intro.size():
				_intro[_frame] = value
			if _frame >= _frames - _intro.size():
				var overlap := _frame - (_frames - _intro.size())
				value = lerpf(value, _intro[overlap], float(overlap + 1) / _intro.size())
		_pcm.encode_s16(_frame * 2, int(clampf(value, -0.8, 0.8) * 32767.0))
		_frame += 1
	if _frame >= _frames:
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = RATE
		stream.stereo = false
		stream.data = _pcm
		if _building < 2:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = _intro.size()
			stream.loop_end = _frames
		_cache[CLIPS[_building]] = stream
		_building = -1
		_pcm = PackedByteArray()
		_intro = PackedFloat32Array()
		_assign_cached_streams()
	var cost := Time.get_ticks_usec() - started
	_synthesis_usec += cost
	_max_batch_usec = maxi(_max_batch_usec, cost)

func generated_streams() -> Array[AudioStreamWAV]:
	var streams: Array[AudioStreamWAV] = []
	for key in CLIPS:
		if _cache.has(key):
			streams.append(_cache[key])
	return streams

func debug_snapshot() -> Dictionary:
	var voices := 0
	for voice in [_wind, _water, _bird]:
		if is_instance_valid(voice) and voice.playing:
			voices += 1
	return {"cached_clips": _cache.size(), "ambient_volume": _ambient_volume, "muted": _muted,
		"environment": _environment.snapshot(), "last_event": _last_event, "event_count": _event_count,
		"water_gain": _water_gain, "wind_gain": _wind_gain, "playing_voices": voices,
		"synthesis_usec": _synthesis_usec, "max_batch_usec": _max_batch_usec}

extends GdUnitTestSuite
## Efeitos sonoros sintetizados (scripts/systems/sfx.gd): cada um existe, tem som e não estoura.

const SFX := preload("res://scripts/systems/sfx.gd")


func test_every_sound_is_short_audible_and_unclipped() -> void:
	for sound: String in SFX.SOUNDS:
		var wav: AudioStreamWAV = SFX.stream(sound)
		var samples := wav.data.size() / 2
		assert_int(samples).override_failure_message(sound).is_between(SFX.RATE / 20, SFX.RATE / 2)
		var peak := 0
		for i in samples: peak = maxi(peak, absi(wav.data.decode_s16(i * 2)))
		assert_int(peak).override_failure_message("%s pico %d" % [sound, peak]).is_between(2000, 32000)


func test_cache_returns_same_stream() -> void:
	assert_object(SFX.stream("pegar")).is_same(SFX.stream("pegar"))

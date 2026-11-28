extends GdUnitTestSuite
## Música da região: o trecho em loop volta ao começo sem perder o tempo que passou do
## fim; sem o arquivo da faixa, o nó fica em silêncio (nada toca antes da aprovação).

const MUSIC := preload("res://scripts/world/region_music.gd")


func test_wrap_keeps_overshoot() -> void:
	assert_float(MUSIC.wrap(100.0, 60.0, 160.0)).is_equal(100.0)
	assert_float(MUSIC.wrap(160.25, 60.0, 160.0)).is_equal_approx(60.25, 0.0001)
	assert_float(MUSIC.wrap(50.0, 0.0, 0.0)).is_equal(50.0)  # sem pontos de loop


func test_missing_track_is_silent() -> void:
	var music: Node = auto_free(MUSIC.new())
	music.track = "nao_existe"
	add_child(music)
	assert_int(music.get_child_count()).is_equal(0)

extends GdUnitTestSuite
## Relógio do multijogador (net_world.follow_clock): o convidado segue o anfitrião sem
## voltar o dia nem virar o dia duas vezes.

const NET_WORLD := preload("res://scripts/net/net_world.gd")


func _clock() -> Node:
	var clock: Node = auto_free(preload("res://scripts/systems/game_clock.gd").new())
	add_child(clock)
	clock.day_number = 3
	clock.set_time(10, 0)
	return clock


func test_behind_advances_once() -> void:
	var clock := _clock()
	var days: Array = []
	clock.day_changed.connect(func(d: int) -> void: days.append(d))
	NET_WORLD.follow_clock(clock, 4, 7 * 60.0)
	assert_int(clock.day_number).is_equal(4)
	assert_int(clock.get_hour()).is_equal(7)
	assert_array(days).is_equal([4])


func test_ahead_same_day_only_sets_time() -> void:
	var clock := _clock()
	NET_WORLD.follow_clock(clock, 3, 9 * 60.0)
	assert_int(clock.day_number).is_equal(3)
	assert_int(clock.get_hour()).is_equal(9)


func test_small_difference_is_ignored() -> void:
	var clock := _clock()
	NET_WORLD.follow_clock(clock, 3, 10 * 60.0 + 1.0)
	assert_int(clock.get_minute()).is_equal(0)


func test_never_goes_back_a_day() -> void:
	var clock := _clock()
	NET_WORLD.follow_clock(clock, 2, 10 * 60.0)
	assert_int(clock.day_number).is_equal(3)

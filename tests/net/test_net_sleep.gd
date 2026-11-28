extends GdUnitTestSuite
## Dormir no multijogador (playtest ID 35): o dia só vira quando todos dormem.

const NetSleep := preload("res://scripts/net/net_sleep.gd")

var _fake_src := """extends Node
signal message(data: Dictionary)
signal peer_joined(who: String)
signal peer_left()
var connected := true
var mode := "host"
var sent: Array = []
func send(data: Dictionary) -> void: sent.append(data)
"""


func _fake_session(mode: String) -> Node:
	var script := GDScript.new()
	script.source_code = _fake_src
	script.reload()
	var session: Node = auto_free(script.new())
	session.set("mode", mode)
	return session


func _sleep_node(session: Node) -> Node:
	var net: Node = auto_free(NetSleep.new())
	net.set("_session", session)
	return net


func after_test() -> void:
	GameClock.reset_new_game()


func test_everyone_asleep_rule() -> void:
	assert_bool(NetSleep.everyone_asleep(1, 2)).is_false()
	assert_bool(NetSleep.everyone_asleep(2, 2)).is_true()
	assert_bool(NetSleep.everyone_asleep(1, 1)).is_true()
	assert_bool(NetSleep.everyone_asleep(0, 0)).is_false()
	assert_str(NetSleep.waiting_text(1, 2, false)).is_equal("Esperando os outros (1/2)")
	assert_float(NetSleep.minutes_to_morning(22 * 60.0)).is_equal(8 * 60.0)


func test_solo_is_not_handled() -> void:
	var net := _sleep_node(null)
	assert_bool(net.call("request", false)).is_false()
	assert_bool(net.get("sleeping")).is_false()


func test_host_waits_for_the_guest_then_day_turns() -> void:
	GameClock.reset_new_game()
	GameClock.set_time(22, 0)
	var day := int(GameClock.day_number)
	var session := _fake_session("host")
	var net := _sleep_node(session)
	assert_bool(net.call("request", false)).is_true()
	assert_bool(net.get("sleeping")).is_true()
	assert_int(int(GameClock.day_number)).is_equal(day)  # sozinho na cama: não vira
	assert_dict(session.get("sent")[0]).is_equal({"t": "sleep", "on": true})
	net.call("_on_message", {"t": "sleep", "on": true})  # o convidado deitou
	assert_int(int(GameClock.day_number)).is_equal(day + 1)
	assert_int(GameClock.get_hour()).is_equal(6)
	assert_str(str(session.get("sent").back().t)).is_equal("wake")
	net.call("_process", 0.0)
	assert_bool(net.get("sleeping")).is_false()


func test_guest_never_turns_the_day_itself() -> void:
	GameClock.reset_new_game()
	GameClock.set_time(21, 0)
	var day := int(GameClock.day_number)
	var net := _sleep_node(_fake_session("guest"))
	net.call("_on_message", {"t": "sleep", "on": true})
	net.call("request", false)
	assert_int(int(GameClock.day_number)).is_equal(day)
	net.call("_on_message", {"t": "wake", "day": day + 1, "minutes": 360})  # anfitrião virou
	net.call("_process", 0.0)
	assert_int(int(GameClock.day_number)).is_equal(day + 1)
	assert_bool(net.get("sleeping")).is_false()


func test_bed_toggles_but_exhausted_stays_asleep() -> void:
	var net := _sleep_node(_fake_session("guest"))
	net.call("request", false)
	net.call("request", false)  # [F] de novo: levanta
	assert_bool(net.get("sleeping")).is_false()
	net.call("request", true)
	net.call("request", true)  # checagem de exaustão repete: continua dormindo
	net.call("request", false)
	assert_bool(net.get("sleeping")).is_true()

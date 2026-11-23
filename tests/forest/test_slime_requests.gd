extends GdUnitTestSuite
## Pedidos dos slimes: sorteio fixo por dia, atender rende laço extra uma vez só.

const REQ := preload("res://scripts/systems/slime_requests.gd")
const FEEDING := preload("res://scripts/systems/slime_feeding.gd")


func before_test() -> void:
	for k in [REQ.KEY, FEEDING.KEY, "forest_bag_items"]:
		if get_tree().has_meta(k): get_tree().remove_meta(k)


func _some_request() -> Array:
	for d in 200:
		var w := REQ.wanted(get_tree(), "brotinho/t/0", "brotinho", d)
		if not w.is_empty(): return [d, w]
	return []


func test_request_is_stable_and_rate_is_low() -> void:
	var count := 0
	for d in 1000:
		if not REQ.wanted(get_tree(), "brotinho/t/1", "brotinho", d).is_empty(): count += 1
	assert_int(count).is_between(250, 450)  # ~35%
	var found := _some_request()
	assert_str(REQ.wanted(get_tree(), "brotinho/t/0", "brotinho", found[0])).is_equal(found[1])


func test_cooked_lovers_ask_cooked_food() -> void:
	for d in 100:
		var w := REQ.wanted(get_tree(), "colhita/t/0", "colhita", d)
		if not w.is_empty(): assert_array(REQ.COOKED).contains([w])


func test_fulfill_gives_bonus_once() -> void:
	var found := _some_request()
	var before := FEEDING.points(get_tree(), "brotinho/t/0")
	assert_str(REQ.fulfill(get_tree(), "brotinho/t/0", "brotinho", found[0], "graveto")).is_empty()
	assert_str(REQ.fulfill(get_tree(), "brotinho/t/0", "brotinho", found[0], found[1])).is_not_empty()
	assert_int(FEEDING.points(get_tree(), "brotinho/t/0")).is_equal(before + REQ.BONUS)
	assert_str(REQ.wanted(get_tree(), "brotinho/t/0", "brotinho", found[0])).is_empty()
	assert_str(REQ.fulfill(get_tree(), "brotinho/t/0", "brotinho", found[0], found[1])).is_empty()

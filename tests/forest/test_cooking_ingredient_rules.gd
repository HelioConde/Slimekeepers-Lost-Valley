extends GdUnitTestSuite

const RULES := preload("res://scripts/systems/cooking_ingredient_rules.gd")

func test_recursos_disponiveis_sem_consumo() -> void:
	var required := {"a": 2, "b": 1, "c": 0}
	var stock := {"a": 2, "b": 4}
	var before_required := required.duplicate()
	var before_stock := stock.duplicate()
	var result := RULES.check(required, stock)
	assert_dict(result).is_equal({"valid": true, "available": true, "missing": {}})
	assert_dict(required).is_equal(before_required)
	assert_dict(stock).is_equal(before_stock)

func test_necessidade_vazia() -> void:
	assert_dict(RULES.check({}, {})).is_equal({"valid": true, "available": true, "missing": {}})

func test_recursos_insuficientes_em_ordem_de_id() -> void:
	var required := {"z": 3, "m": 2, "a": 4}
	var stock := {"z": 1, "m": 2}
	var before_required := required.duplicate()
	var before_stock := stock.duplicate()
	var result := RULES.check(required, stock)
	assert_dict(result).is_equal({"valid": true, "available": false, "missing": {"a": 4, "z": 2}})
	var missing: Dictionary = result["missing"]
	assert_array(missing.keys()).is_equal(["a", "z"])
	assert_dict(required).is_equal(before_required)
	assert_dict(stock).is_equal(before_stock)

func test_entradas_invalidas_em_ambos_os_mapas() -> void:
	var invalid_result := {"valid": false, "available": false, "missing": {}}
	var malformed := [null, [], "a", {"": 1}, {" \t": 0}, {7: 1}, {"a": -1}, {"a": 1.5}, {"a": true}, {"a": "2"}]
	for sample: Variant in malformed:
		assert_dict(RULES.check(sample, {})).is_equal(invalid_result)
		assert_dict(RULES.check({"outro": 3}, sample)).is_equal(invalid_result)

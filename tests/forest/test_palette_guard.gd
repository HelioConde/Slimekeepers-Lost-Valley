extends GdUnitTestSuite

## Guarda de paleta (V8): tingimento forte em sprite inteiro também pinta as
## folhas (rosetas azuis/magenta fora da paleta da referência).

const SCENES := ["res://scenes/regions/FlorestaDoDespertarV2.tscn", "res://scenes/regions/ValeDasNascentes.tscn"]
const MAX_CHANNEL := 1.2
const MIN_CHANNEL := 0.6


func test_no_strong_full_sprite_tints() -> void:
	var regex := RegEx.create_from_string(r"modulate = Color\(([0-9.]+), ([0-9.]+), ([0-9.]+), [0-9.]+\)")
	for path in SCENES:
		var text := FileAccess.get_file_as_string(path)
		for found in regex.search_all(text):
			for i in range(1, 4):
				var channel := float(found.get_string(i))
				assert_float(channel).override_failure_message("%s: %s" % [path, found.get_string()]).is_less_equal(MAX_CHANNEL)
				assert_float(channel).override_failure_message("%s: %s" % [path, found.get_string()]).is_greater_equal(MIN_CHANNEL)

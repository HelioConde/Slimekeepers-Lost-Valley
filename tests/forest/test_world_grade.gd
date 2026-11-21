extends GdUnitTestSuite

## Grade de cor do mundo: perfis contínuos por horário, manhã/tarde mais quentes
## que o meio-dia, noite fria; fica abaixo do HUD.

const Grade := preload("res://scripts/world/world_grade.gd")


func test_profiles_are_continuous() -> void:
	for minute in 1440:
		var a: Dictionary = Grade.profile_at(minute)
		var b: Dictionary = Grade.profile_at(minute + 1)
		assert_float(absf(a.vibrance - b.vibrance)).is_less(0.01)
		assert_float((a.highlight_tint as Vector3).distance_to(b.highlight_tint)).is_less(0.01)


func test_warm_mornings_and_afternoons_cool_nights() -> void:
	var morning: Vector3 = Grade.profile_at(7 * 60).highlight_tint
	var noon: Vector3 = Grade.profile_at(12 * 60).highlight_tint
	var dusk: Vector3 = Grade.profile_at(18 * 60 + 30).highlight_tint
	var night: Vector3 = Grade.profile_at(23 * 60).highlight_tint
	assert_float(morning.x - morning.z).is_greater(noon.x - noon.z)
	assert_float(dusk.x - dusk.z).is_greater(noon.x - noon.z)
	assert_float(night.z).is_greater(night.x)


func test_grade_sits_between_world_and_hud() -> void:
	var grade: CanvasLayer = auto_free(Grade.new())
	add_child(grade)
	await await_idle_frame()
	assert_int(grade.layer).is_equal(1)
	var hud_source := FileAccess.get_file_as_string("res://scripts/world.gd")
	assert_str(hud_source).contains("layer.layer = 2")

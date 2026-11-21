extends GdUnitTestSuite

## Plantas-lanterna (V9): quatro por ponte, brilho quente só à noite.

const Lanterns := preload("res://scripts/world/lantern_flowers.gd")


func test_four_per_bridge_and_glow_only_at_night() -> void:
	var holder: Node2D = auto_free(Node2D.new())
	add_child(holder)
	var lanterns: Node2D = Lanterns.new()
	var rects: Array[Rect2] = [Rect2(470, 1198, 280, 84), Rect2(2400, 1198, 280, 84)]
	lanterns.setup(rects, holder)
	holder.add_child(lanterns)
	assert_int(lanterns.plants.size()).is_equal(8)
	lanterns.apply_time(0.0, 0.1)
	for light in lanterns.lights: assert_float(light.energy).is_equal(0.0)
	lanterns.apply_time(1.0, 0.1)
	for light in lanterns.lights: assert_float(light.energy).is_greater(0.5)
	for halo in lanterns.halos: assert_bool(halo.has_meta("no_shadow")).is_true()

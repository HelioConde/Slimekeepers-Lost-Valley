extends SceneTree
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1; push_error(label)
func run():
	for scene in ["FlorestaDoDespertarV2", "ValeDasNascentes"]:
		var region = load("res://scenes/regions/%s.tscn" % scene).instantiate()
		root.add_child(region)
		for i in 4: await process_frame
		var lighting = region.get_node("DayNightLighting")
		var reflections = lighting.get_node_or_null("WaterReflections")
		check(reflections != null, "Water reflections installed in " + scene)
		if reflections:
			check(reflections.surfaces.size() >= 2, "Reflective water surfaces found")
			for overlay in reflections.surfaces:
				check(overlay.polygon == overlay.get_parent().polygon, "Reflection clips exactly to water polygon")
				check(overlay.position == Vector2.ZERO and overlay.z_index == 0, "Reflection preserves water transform/depth")
			var noon = reflections.profile_at(720)
			var dusk = reflections.profile_at(1110)
			var moon = reflections.profile_at(1320)
			check(dusk.strength > noon.strength, "Low sun creates stronger reflected light")
			check(dusk.color.r > dusk.color.b and moon.color.b > moon.color.r, "Sun is warm, moon is silver blue")
			check(moon.strength > 0, "Moon reflection enabled at night")
			var continuous := true
			for minute in 1440:
				var a = reflections.profile_at(minute)
				var b = reflections.profile_at(minute + 1)
				if absf(a.strength-b.strength) > .025 or absf(a.axis-b.axis) > .025: continuous = false
			check(continuous, "Continuous reflection across day and midnight")
			root.get_node("GameClock").set_time(22)
			lighting._process(0)
			check(is_equal_approx(reflections.material.get_shader_parameter("strength"), moon.strength), "Shader follows global clock")
			reflections.reduce_motion = true
			var before = reflections.elapsed
			reflections.update_for_time(1)
			check(reflections.elapsed == before, "Reduced motion freezes ripple shimmer")
		region.queue_free()
		await process_frame
	print("WATER_REFLECTIONS: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)

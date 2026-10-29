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
		for i in 10: await process_frame
		var lighting = region.get_node("DayNightLighting")
		var shadows = lighting.get_node_or_null("DayShadows")
		check(shadows != null, "Directional ground shadows installed: " + scene)
		if shadows:
			var morning = shadows.profile_at(420)
			var noon = shadows.profile_at(720)
			var dusk = shadows.profile_at(1110)
			var night = shadows.profile_at(1320)
			check(morning.vector.x < 0 and dusk.vector.x > 0, "Direction follows sun across sky")
			check(morning.vector.length() > noon.vector.length()*2 and dusk.vector.length() > noon.vector.length()*2, "Low sun lengthens shadows")
			check(night.opacity < morning.opacity, "Moonlight shadows are softer")
			var continuous := true
			for minute in 1440:
				var a = shadows.profile_at(minute)
				var b = shadows.profile_at(minute+1)
				if a.vector.distance_to(b.vector) > .09 or absf(a.opacity-b.opacity) > .02:continuous=false
			check(continuous,"No jump at period boundaries or midnight")
			check(shadows.z_index == -1 and not shadows.z_as_relative,"Shadow layer remains below actors and props")
			var player = region.player
			check(shadows.has_caster(player.sprite),"Player participates")
			var transform = shadows.projection_for(player.sprite, player.global_position, morning.vector)
			var base = Vector2(0, shadows.source_bottom(player.sprite))
			check(absf((transform*base).y-player.global_position.y)<.01,"Projected feet touch ground anchor")
			var animals = Sprite2D.new()
			animals.name = "Ambient_shadow_probe"
			animals.texture = load("res://assets/player/rotations/south.png")
			region.add_child(animals)
			shadows.update_for_time(0)
			check(shadows.has_caster(animals),"Runtime wildlife registers without scene reload")
			animals.queue_free()
			await process_frame
			shadows.update_for_time(0)
			check(shadows.count_category("object")>0 and shadows.count_category("tree")>0,"Trees and objects participate")
			var creature = get_first_node_in_group("living_slimes")
			if creature:
				check(shadows.has_caster(creature.sprite),"Slime participates")
				creature.swimming = true
				check(not shadows.casts_on_ground(creature.sprite),"Swimming slime keeps water ripples without ground projection")
				creature.swimming = false
		region.queue_free()
		await process_frame
	print("DAY_SHADOWS: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)

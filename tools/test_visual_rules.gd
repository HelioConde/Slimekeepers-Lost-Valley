extends SceneTree
## Whole-region invariants: visible depth, grounded pivots, safe fauna and preserved physics.
const RULES = preload("res://scripts/world/visual_rules.gd")
var checks := 0
var failures := 0
var report := {}

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	for label in ["FlorestaDoDespertarV2", "ValeDasNascentes"]:
		var region: Node2D = load("res://scenes/regions/%s.tscn" % label).instantiate()
		var solids := region.find_children("*", "StaticBody2D", true, false).size()
		root.add_child(region)
		current_scene = region
		for frame in 8: await physics_frame
		var stats: Dictionary = region.get_meta("visual_rules_applied")
		check(region.y_sort_enabled, label + " enables shared root sorting")
		check(region.player.z_index == 0, label + " keeps protagonist in the shared depth plane")
		var art_solids: int = region.get_node("MapArt").stats.solids if region.has_node("MapArt") else 0
		check(region.find_children("*", "StaticBody2D", true, false).size() == solids + art_solids,
			label + " preserves all original static collision bodies")
		check(stats.sorted_props > 300 and stats.thinned_plants > 0, label + " applies rules across the whole map")
		var cliffs := preload("res://scripts/world/region_surfaces.gd").cliff_faces(region)
		var cliff_plants_clear := true
		var checked := 0
		var cache := {}
		var pivots_ok := true
		for group_name in RULES.PROP_GROUPS:
			var group := region.get_node_or_null(group_name) as Node2D
			if group == null: continue
			check(group.z_index == 0 and group.y_sort_enabled, label + "/" + group_name + " shares actor Y-sort")
			for prop in group.get_children():
				var sprite := prop.get_node_or_null("Sprite") as Sprite2D
				if sprite == null or sprite.texture == null or not prop.visible: continue
				check(prop.z_index in [-2,0] and not prop.y_sort_enabled and sprite.z_index == 0,
					label + "/" + str(prop.name) + " is one foot-sorted or ground-only object")
				var path: String = sprite.texture.resource_path
				if RULES.is_plant(path) or prop.has_meta("tree"):
					for face in cliffs:
						if Geometry2D.is_point_in_polygon(prop.global_position,face): cliff_plants_clear=false
				if "steps" in path or "ramp" in path or "bridge" in path:
					check(prop.z_index < 0, label + " walkable surfaces cannot hide the protagonist")
				if not cache.has(path): cache[path] = sprite.texture.get_image().get_used_rect()
				var used: Rect2i = cache[path]
				var foot := Vector2(used.position.x + used.size.x * .5, used.end.y) + sprite.offset
				if sprite.centered: foot -= sprite.texture.get_size() * .5
				pivots_ok = pivots_ok and absf((sprite.transform * foot).y) <= 4
				checked += 1
		check(cliff_plants_clear, label + " has no visible plants rooted on vertical cliff faces")
		check(checked > 200 and pivots_ok, label + " visible original sprites keep grounded alpha pivots")
		var roots := region.get_node_or_null("AncientRoots")
		if roots != null:
			for line in roots.get_children():
				if line is Line2D:
					check(line.points[0].distance_to(line.points[-1]) < 40, "Ancient roots stay attached to the trunk")
		if label == "ValeDasNascentes":
			for bridge in preload("res://scripts/world/valley_layout.gd").BRIDGES:
				check(not region.ecosystem._valid_ground(bridge.get_center()), "Ambient fauna cannot spawn on bridge")
			for basin in preload("res://scripts/world/valley_layout.gd").basins():
				check(not region.ecosystem._valid_ground(basin[0]), "Ambient fauna cannot spawn in water")
		report[label] = {"rules": stats, "visible_pivots_checked": checked, "static_bodies_preserved": solids}
		region.free()
		await process_frame
	var player_height: float = load("res://assets/player/rotations/south.png").get_image().get_used_rect().size.y * .65
	for species in ["squirrel", "bird"]:
		var frames: SpriteFrames = load("res://assets/wildlife/living_v3/%s/frames.tres" % species)
		var scale_factor: float = preload("res://scripts/world/forest_life.gd").WILDLIFE_SCALE[species]
		var ratio: float = frames.get_frame_texture("idle",0).get_image().get_used_rect().size.y * scale_factor / player_height
		check(ratio >= .35 and ratio <= .65, species + " remains small and readable beside the protagonist")
		report[species + "_height_ratio"] = ratio
	FileAccess.open("res://docs/world/living_v3/visual_rules_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("VISUAL_RULES: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)

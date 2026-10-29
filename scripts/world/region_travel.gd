extends RefCounted
## Session-only region travel. Does not claim to be a save-game system.
const CLEARING := "res://scenes/regions/FlorestaDoDespertarV2.tscn"
const VALLEY := "res://scenes/regions/ValeDasNascentes.tscn"

static func travel(scene: Node2D, destination: String, arrival: String) -> void:
	var tree := scene.get_tree()
	if scene.get_meta("travelling",false): return
	scene.set_meta("travelling",true)
	if destination == VALLEY:
		var key := "forest_slime_friends" if scene.get_meta("forest_v2",false) else "clearing_friends"
		var friends: Dictionary = tree.get_meta(key,{}).duplicate()
		for slime: Node2D in scene.slimes:
			var id = slime.get("persistent_id")
			friends[id if id != null else slime.slime_type] = slime.befriended
		tree.set_meta(key,friends)
	if destination == CLEARING:
		tree.set_meta("valley_discoveries",scene.found_zones.duplicate())
	tree.set_meta("region_arrival",arrival)
	var error := tree.change_scene_to_file(destination)
	if error != OK:
		scene.set_meta("travelling",false)
		tree.remove_meta("region_arrival")
		push_error("Region transition failed: %s" % error)

static func restore_clearing(scene: Node2D) -> void:
	var tree := scene.get_tree()
	if tree.get_meta("region_arrival","") != "clearing_south": return
	tree.remove_meta("region_arrival")
	scene.player.position = Vector2(1600,2980)
	scene.player.get_node("Camera2D").reset_smoothing()
	var friends: Dictionary = tree.get_meta("clearing_friends",{})
	for slime: Node2D in scene.slimes:
		if friends.get(slime.slime_type,false):
			slime.make_friend()
			scene.friends_count += 1
	scene._update_hud()

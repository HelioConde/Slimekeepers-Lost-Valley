extends SceneTree
## Diagnóstico: lista quem gera cada sombra do DayShadows perto do jogador e a
## distância entre o ponto de apoio (pé) e a base visual do sprite.
##   godot --headless --path . --script res://tools/diag_shadows.gd -- --scene=FlorestaDoDespertarV2
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene := "FlorestaDoDespertarV2"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="): scene = arg.split("=")[1]
	var region: Node2D = load("res://scenes/regions/%s.tscn" % scene).instantiate()
	root.add_child(region)
	for i in 10: await process_frame
	var shadows = region.get_node("DayNightLighting/DayShadows")
	var center: Vector2 = region.get_node("Player").global_position
	var kinds := {}
	for id in shadows._casters:
		var sprite: Node2D = shadows._casters[id]
		var kind: String = shadows._kinds[id]
		kinds[kind] = kinds.get(kind, 0) + 1
		var foot: Vector2 = shadows.foot_for(sprite) if shadows.has_method("foot_for") else sprite.global_position
		var base_y: float = (sprite.global_transform * Vector2(0, shadows.ground_bottom(sprite))).y
		var gap := base_y - foot.y
		var near := foot.distance_to(center) < 700
		if near or absf(gap) > 24:
			var tex = shadows._texture_for(sprite)
			print("CASTER %s kind=%s foot=%s base_gap=%.0f tex=%s" % [region.get_path_to(sprite), kind, foot.round(), gap, tex.resource_path.get_file() if tex else "-"])
	print("KINDS ", kinds)
	quit(0)

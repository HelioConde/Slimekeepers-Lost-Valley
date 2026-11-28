extends SceneTree
## Auditoria de sombras de uma região (headless):
##   godot --headless --path . --script res://tools/diag_shadows.gd -- --scene=ValeDasNascentes
## Lista: quem projeta sombra (por tipo), sombras deslocadas da base, blobs pintados
## sem dono, sprites sólidos sem sombra e outras fontes de escurecimento no chão.
func _initialize() -> void: call_deferred("run")


func run() -> void:
	var scene := "FlorestaDoDespertarV2"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="): scene = arg.split("=")[1]
	var region: Node2D = load("res://scenes/regions/%s.tscn" % scene).instantiate()
	root.add_child(region)
	for i in 10: await process_frame
	var shadows = region.get_node("DayNightLighting/DayShadows")
	var kinds := {}
	var contact := 0
	var displaced: Array[String] = []
	for id in shadows._casters:
		var sprite: Node2D = shadows._casters[id]
		kinds[shadows._kinds[id]] = kinds.get(shadows._kinds[id], 0) + 1
		if shadows.has_contact(sprite): contact += 1
		var base_y: float = (sprite.global_transform * Vector2(0, shadows.ground_bottom(sprite))).y
		var gap: float = base_y - (shadows.foot_for(sprite) as Vector2).y
		if absf(gap) > 8.0 and sprite.is_visible_in_tree():
			displaced.append("%s gap=%.0f" % [region.get_path_to(sprite), gap])
	print("AUDIT %s casters=%s contact=%d" % [scene, kinds, contact])
	print("AUDIT %s deslocadas=%d %s" % [scene, displaced.size(), displaced.slice(0, 8)])
	# Blobs pintados (ContactShadow e afins) ainda visíveis: sombra sem dono se o
	# objeto ao lado não projeta sombra própria.
	var orphan := {}
	var owned_visible := 0
	for node in region.find_children("*", "Polygon2D", true, false):
		var name := str(node.name)
		if not (name.contains("Shadow") or name.contains("Shade")) or not node.is_visible_in_tree(): continue
		var owner_sprite := node.get_parent().get_node_or_null("Sprite") as Node2D
		if owner_sprite and shadows.has_caster(owner_sprite): owned_visible += 1
		else:
			var key := "%s/%s" % [str(node.get_parent().get_parent().name) if node.get_parent().get_parent() else "", name]
			orphan[key] = orphan.get(key, 0) + 1
	print("AUDIT %s blobs_visiveis_com_dono=%d sem_dono=%s" % [scene, owned_visible, orphan])
	# Sprites sólidos visíveis que não projetam sombra.
	var missing := {}
	for node in region.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if not sprite.is_visible_in_tree() or not sprite.texture or shadows.has_caster(sprite): continue
		if region.get_node("DayNightLighting").is_ancestor_of(sprite) or region.get_node_or_null("HUD") and region.get_node("HUD").is_ancestor_of(sprite): continue
		var file := sprite.texture.resource_path.get_file()
		if file.is_empty(): file = "(gerada) " + str(sprite.get_parent().name)
		missing[file] = missing.get(file, 0) + 1
	var keys := missing.keys()
	keys.sort_custom(func(a, b): return missing[a] > missing[b])
	for key in keys.slice(0, 25):
		print("AUDIT %s sem_sombra %s x%d" % [scene, key, missing[key]])
	quit(0)

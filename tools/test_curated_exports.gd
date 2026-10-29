extends SceneTree
var checks:=0
var failures:=0
var report:={}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func run() -> void:
	for map in ["FlorestaDoDespertarV2","ValeDasNascentes"]:
		var region: Node2D=load("res://scenes/regions/%s.tscn"%map).instantiate()
		var originals:=region.find_children("*","StaticBody2D",true,false)
		root.add_child(region)
		current_scene=region
		for i in 10: await physics_frame
		check(region.get_meta("map_art_ready",false),map+" enrichment finishes")
		var art: Node2D=region.get_node("MapArt")
		check(art.stats.replaced>15,map+" gets visible asset variety")
		check(art.stats.added>=10,map+" has curated groups")
		check(art.z_index==0 and art.y_sort_enabled,map+" shares actor depth")
		for body in originals: check(is_instance_valid(body) and body.is_inside_tree(),"Original collision body preserved")
		for prop in art.get_children():
			var sprite: Sprite2D=prop.get_node("Sprite")
			var used:=sprite.texture.get_image().get_used_rect()
			var foot:Vector2=sprite.transform*(Vector2(used.position.x+used.size.x*.5,used.end.y)+sprite.offset)
			check(foot.length()<.1,"New sprite has exact contact pivot")
			check(prop.z_index==0 and not prop.y_sort_enabled,"Each prop sorts as a single object")
			var solid:=prop.get_node_or_null("SolidBase")
			check(art.trail_distance(prop.position)>=(70 if solid else 46),"New prop leaves paths clear")
			check(not art._over_cliff(prop.position,used.size.y*sprite.scale.y),"New sprite does not intersect cliff face")
			if solid:
				var shape:CollisionShape2D=solid.get_node("Footprint")
				check(is_zero_approx(shape.position.y+shape.shape.size.y*.5),"Solid footprint ends at visible base")
				check(shape.shape.size.x<used.size.x*sprite.scale.x,"Solid footprint fits artwork")
			if map=="ValeDasNascentes":check(not region.habitat_manager.is_water(prop.position),"New land prop stays out of water")
		report[map]=art.stats.duplicate()
		region.queue_free()
		await process_frame
	FileAccess.open("res://docs/world/curated_exports/validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("CURATED_EXPORTS: ",checks," checks; ",failures," failures; ",report)
	quit(1 if failures else 0)

extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var result := {}
	for path in ["res://scenes/regions/FlorestaDoDespertarV2.tscn","res://scenes/regions/ValeDasNascentes.tscn"]:
		var scene: Node2D=load(path).instantiate()
		var groups := []
		for child in scene.get_children():
			if child is CanvasItem:
				groups.append({"name":str(child.name),"type":child.get_class(),"z":child.z_index,"ysort":child.y_sort_enabled,"children":child.get_child_count()})
		var samples := []
		var cache := {}
		var bad_groups := {}
		for sprite in scene.find_children("*","Sprite2D",true,false):
			if sprite.texture==null or sprite.region_enabled:continue
			var key:String=sprite.texture.resource_path
			if not cache.has(key):cache[key]=sprite.texture.get_image().get_used_rect()
			var used: Rect2i=cache[key]
			var foot: Vector2=Vector2(used.position.x+used.size.x*.5,used.end.y)+sprite.offset
			if sprite.centered:foot-=sprite.texture.get_size()*.5
			var prop:Node2D=sprite.get_parent()
			var foot_local:Vector2=sprite.transform*foot
			if sprite.name=="Sprite" and absf(foot_local.y)>4:
				samples.append({"path":str(scene.get_path_to(sprite)),"foot_offset":str(foot_local),"texture":key})
			var ancestor: Node=sprite.get_parent()
			if ancestor is Node2D and ancestor.name=="FlowerLog":
				samples.append({"path":str(scene.get_path_to(sprite)),"foot_offset":str(foot_local),"texture":key})
		result[path]={"root_y_sort":scene.y_sort_enabled,"groups":groups,"foot_outliers":samples}
		scene.free()
	FileAccess.open("res://docs/world/living_v3/visual_audit.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result))
	quit()

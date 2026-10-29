extends SceneTree
var failures:=0
var checks:=0
var cache:={}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS " if ok else "FAIL ",label)
func opaque(sprite: Sprite2D, world: Vector2) -> bool:
	var p:=sprite.to_local(world)-sprite.offset
	if sprite.centered:p+=sprite.texture.get_size()*.5
	var key:=sprite.texture.resource_path
	if not cache.has(key):cache[key]=sprite.texture.get_image()
	var im:Image=cache[key]
	return p.x>=0 and p.y>=0 and p.x<im.get_width() and p.y<im.get_height() and im.get_pixelv(Vector2i(p)).a>.5
func visibility(prop: Node2D, region: Node2D) -> float:
	var sprite: Sprite2D=prop.get_node("Sprite")
	var used:=sprite.texture.get_image().get_used_rect()
	var trees:=[]
	for label in preload("res://scripts/world/visual_rules.gd").PROP_GROUPS:
		var group:=region.get_node_or_null(label)
		if not group:continue
		for node in group.get_children():
			var tree:=node.get_node_or_null("Sprite") as Sprite2D
			if not tree or not tree.texture or not node.visible or node.global_position.y<=prop.global_position.y:continue
			var path:=tree.texture.resource_path.to_lower()
			if ("oak" in path or "pine" in path or node.has_meta("tree")) and not "log" in path:trees.append(tree)
	var total:=0
	var visible:=0
	for y in range(used.position.y,used.end.y,3):
		for x in range(used.position.x,used.end.x,3):
			var world:=sprite.to_global(Vector2(x,y)+sprite.offset)
			if sprite.centered:world=sprite.to_global(Vector2(x,y)+sprite.offset-sprite.texture.get_size()*.5)
			if not opaque(sprite,world):continue
			total+=1
			var hidden:=false
			for tree in trees:
				if opaque(tree,world):hidden=true;break
			if not hidden:visible+=1
	return float(visible)/maxi(1,total)
func run() -> void:
	for map in ["FlorestaDoDespertarV2","ValeDasNascentes"]:
		var baseline:=[]
		for visit in 2:
			var region:Node2D=load("res://scenes/regions/%s.tscn"%map).instantiate()
			if visit==1 and map=="FlorestaDoDespertarV2":set_meta("region_arrival","clearing_south")
			root.add_child(region)
			current_scene=region
			# Simulate movement/arrival before deferred artwork initialization.
			if visit==1:region.player.position=Vector2(3020,3240) if map=="FlorestaDoDespertarV2" else Vector2(745,1450)
			for i in 10:await physics_frame
			var art:Node2D=region.get_node("MapArt")
			var snapshot:=[]
			var furniture:=0
			for prop in art.get_children():
				var key:String=prop.get_meta("curated_asset")
				snapshot.append([key,prop.position])
				if key in ["bench","wood_post"]:furniture+=1
				if visit==0 and key in ["ruins_a","ruins_b"]:
					var ratio:=visibility(prop,region)
					check(ratio>=.7,map+" "+key+" visible fraction="+str(snappedf(ratio,.01)))
			check(furniture==0,map+" wilderness has no benches or lamp posts (including their colliders)")
			if visit==0:baseline=snapshot
			else:check(snapshot==baseline,map+" decoration is independent of arrival/player position")
			region.queue_free()
			await process_frame
	print("MAP_COMPOSITION: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)

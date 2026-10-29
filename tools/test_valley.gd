extends SceneTree
const L=preload("res://scripts/world/valley_layout.gd")
var scene:Node2D
var actor:CharacterBody2D
var checks:=0
var failures:=0
var samples:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",message)
func occupied(at:Vector2)->bool:
	var q:=PhysicsShapeQueryParameters2D.new()
	var body:CollisionShape2D=actor.get_node("CollisionShape2D")
	q.shape=body.shape
	q.transform=Transform2D(0,at+body.position)
	q.collision_mask=2
	q.exclude=[actor.get_rid()]
	q.collide_with_areas=false
	samples+=1
	return not actor.get_world_2d().direct_space_state.intersect_shape(q,1).is_empty()
func run()->void:
	scene=load("res://scenes/regions/ValeDasNascentes.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	actor=scene.player
	for i in 4:await physics_frame
	check(actor.position.is_equal_approx(L.SPAWN),"North spawn is stable")
	check(scene.get_node("Ground").get_used_cells().size()==10000,"100 x 100 editable ground")
	for name_ in L.routes():
		var c:Curve2D=L.routes()[name_]
		var blocked:Array[Vector2]=[]
		var previous:=c.sample_baked(0)
		for i in int(ceil(c.get_baked_length()/8))+1:
			var at:=c.sample_baked(minf(i*8,c.get_baked_length()))
			if occupied(at) or actor.test_move(Transform2D(0,previous),at-previous):blocked.append(at)
			previous=at
		check(blocked.is_empty(),"Continuous route "+name_)
		if not blocked.is_empty():print("  BLOCKED ",blocked.slice(0,4)," ... ",blocked.slice(maxi(0,blocked.size()-3)))
	for b in L.basins():check(occupied(b[0]),"Deep basin blocks at "+str(b[0]))
	for i in L.BRIDGES.size():check(not occupied(L.BRIDGES[i].get_center()),"Bridge center %d"%i)
	for p in L.HABITATS:check(not occupied(p),"Habitat accessible "+str(p))
	check(scene.get_node("SlimeSpawnPoints").get_child_count()==6,"Six reserved water habitats")
	check(scene.get_node("Elevations/ElevationLevel3") is TileMapLayer,"Three editable elevation layers")
	check(scene.get_node("Waterfalls").get_child_count()==3,"Three integrated waterfalls")
	actor.position=Vector2(1120,2510)
	for i in 4:await physics_frame
	Input.action_press("interact")
	await process_frame
	await process_frame
	Input.action_release("interact")
	check(scene.popup.text.contains("juncos"),"Wetland examination works")
	actor.position=Vector2(1780,3160)
	for i in 4:await physics_frame
	Input.action_press("interact")
	await process_frame
	await process_frame
	Input.action_release("interact")
	check(current_scene==scene and scene.popup.text.contains("breve"),"Future exit stays in Map 2")
	print("VALLEY_TEST ",checks," checks; ",failures," failures; ",samples," samples")
	quit(1 if failures else 0)

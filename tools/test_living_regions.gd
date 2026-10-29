extends SceneTree
const Travel = preload("res://scripts/world/region_travel.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func settle() -> void:
	for i in 8: await physics_frame
func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(960,540)
	var forest: Node2D = load(Travel.CLEARING).instantiate()
	root.add_child(forest)
	current_scene = forest
	await settle()
	check(forest.slimes.filter(func(s):return s.slime_type=="brotinho").size()==8,"Eight existing Brotinhos retained")
	if OS.get_cmdline_user_args().has("--require-complete-art"):
		check(forest.slimes.filter(func(s):return s.slime_type=="musguinho").size()==2,"Two real Musguinhos occupy shady habitats")
	check(forest.slimes.size()<=10,"Forest cap ten")
	for slime in forest.slimes:
		check(forest.habitat_manager.is_position_allowed(slime.global_position,slime.habitat,slime),"Forest spawn validates physical habitat: "+slime.persistent_id)
	var friend_id: String = forest.slimes[0].persistent_id
	forest.slimes[0].make_friend()
	get_root().get_node("GameClock").set_time(22)
	forest.set_environment_conditions("night",0.2,0.7,0.1)
	check(forest.habitat_manager.environmental_state.period=="night","Weather reaches forest creature controller")
	Travel.travel(forest,Travel.VALLEY,"valley_north")
	await settle()
	var valley: Node2D = current_scene
	check(valley.scene_file_path==Travel.VALLEY,"Forest transitions into existing valley")
	check(valley.slimes.size()==8,"Eight aquatic slimes fill six real bank habitats")
	check(valley.habitat_manager.environmental_state.period=="night","Environmental inputs survive region travel")
	check(is_equal_approx(valley.habitat_manager.environmental_state.rain,0.2) and is_equal_approx(valley.habitat_manager.environmental_state.wind,0.7),"Clock profile preserves weather across regions")
	var ids := {}
	for slime in valley.slimes:
		check(slime.slime_type=="bolhinha","Valley uses water species")
		check(not ids.has(slime.persistent_id),"Aquatic identities unique")
		ids[slime.persistent_id]=true
		check(valley.habitat_manager.is_position_allowed(slime.global_position,slime.habitat,slime),"Water slime starts on traversable bank")
		check(slime.sprite.sprite_frames.get_frame_count("move")>1,"Aquatic movement uses actual frames")
	var target = valley.slimes.filter(func(s):return s.habitat.id=="V03")[0]
	var aquatic_id: String = target.persistent_id
	valley.player.position=target.position+Vector2(0,24)
	await settle()
	var discovered_before: int = valley.found_zones.size()
	Input.action_press("interact")
	await process_frame
	await process_frame
	Input.action_release("interact")
	await settle()
	check(target.befriended,"Actual E befriends aquatic slime at the Lagoas POI")
	check(valley.found_zones.size()==discovered_before,"One E does not also trigger the overlapping POI")
	valley._update_living_goal()
	check(valley.friends_count==1,"Aquatic friendship is counted")
	var forest_friends: Dictionary = get_meta("forest_slime_friends",{})
	check(forest_friends.values().count(true)==1 and forest_friends.has(friend_id) and not forest_friends.has(aquatic_id),"Aquatic friendship does not contaminate forest counter")
	get_root().get_node("GameClock").set_time(16)
	valley.set_environment_conditions("afternoon",0.0,1.0,0.0)
	valley.ecosystem.set_reduced_motion(true)
	check(valley.slimes[0].is_physics_processing(),"Reduced decorative motion preserves creature gameplay")
	Travel.travel(valley,Travel.CLEARING,"clearing_south")
	await settle()
	forest=current_scene
	check(forest.slimes.filter(func(s):return s.persistent_id==friend_id and s.befriended).size()==1,"Forest friend restored exactly once")
	check(get_nodes_in_group("living_slimes").size()==forest.slimes.size(),"Valley creatures freed on leaving")
	Travel.travel(forest,Travel.VALLEY,"valley_north")
	await settle()
	valley=current_scene
	check(valley.slimes.size()==8,"Repeated travel does not duplicate water population")
	check(valley.slimes.filter(func(s):return s.persistent_id==aquatic_id and s.befriended).size()==1,"Aquatic friendship restored exactly once")
	check(get_nodes_in_group("living_slimes").size()==8,"No previous map creatures leaked")
	valley.queue_free()
	await settle()
	check(get_nodes_in_group("living_slimes").is_empty(),"Region teardown frees all creatures")
	print("LIVING_REGIONS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

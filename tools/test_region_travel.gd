extends SceneTree
const Travel=preload("res://scripts/world/region_travel.gd")
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,msg:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",msg)
func settle()->void:
	for i in 5:await physics_frame
	# HUD and scene changes run on idle frames; physics catch-up alone is insufficient.
	await process_frame
	await process_frame
func press_e()->void:
	Input.action_press("interact")
	await process_frame
	await process_frame
	Input.action_release("interact")
	await settle()
func run()->void:
	var clearing:Node2D=load(Travel.CLEARING).instantiate()
	root.add_child(clearing)
	current_scene=clearing
	await settle()
	clearing.slimes[0].make_friend()
	clearing.friends_count=1
	var friend_id: String = clearing.slimes[0].persistent_id
	clearing.player.position=Vector2(3220,6280)
	await settle()
	check(clearing.hud_hint.text.contains("Viajar"),"Clearing south shows travel prompt")
	await press_e()
	check(current_scene.name=="ValeDasNascentes","E enters Map 2")
	if current_scene.name!="ValeDasNascentes":quit(1);return
	check(current_scene.player.position.is_equal_approx(Vector2(1600,180)),"Arrival stays clear of return trigger")
	current_scene.player.position=Vector2(1600,70)
	await settle()
	check(current_scene.hud_hint.text.contains("Voltar"),"North shows return prompt")
	await press_e()
	check(current_scene.scene_file_path==Travel.CLEARING,"E returns to the existing Map 1 scene")
	check(current_scene.player.position.is_equal_approx(Vector2(3220,6140)),"Return spawn is inside the expanded south trail")
	var preserved := false
	var unbefriended := 0
	for slime in current_scene.slimes:
		if slime.persistent_id == friend_id: preserved=slime.befriended
		if not slime.befriended: unbefriended+=1
	check(current_scene.friends_count==1 and preserved,"Friendship preserved by unique id across travel")
	var expected_population := 10 if ResourceLoader.exists("res://assets/slimes/living_v3/musguinho/frames.tres") else 8
	check(unbefriended==expected_population-1 and current_scene.slimes.size()==expected_population,"All other slimes unchanged; no duplicates on return")
	check(not has_meta("region_arrival"),"Arrival marker consumed once")
	print("REGION_TRAVEL ",checks," checks; ",failures," failures")
	current_scene.queue_free()
	await process_frame
	quit(1 if failures else 0)

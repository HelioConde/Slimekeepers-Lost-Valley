extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok:bool, label:String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func run() -> void:
	var valley:Node2D=load("res://scenes/regions/ValeDasNascentes.tscn").instantiate()
	root.add_child(valley)
	current_scene=valley
	await process_frame
	var life:Node2D=valley.get_node_or_null("UnderwaterLife")
	check(life!=null,"Underwater ecosystem exists below the surface")
	check(valley.has_node("WaterBed"),"Visible mineral bed exists")
	if life:
		check(life.fish_centers.size()>=18,"Schools populate the connected basins")
		check(life.plants.size()>=80,"Submerged plants populate the bed")
		check(not life.fish_position(0,0,0).is_equal_approx(life.fish_position(0,0,5)),"Fish swim over time")
		check(life.z_index<valley.get_node("Water").z_index,"Water film covers fish and plants")
		var contained:=true
		for t in range(0,180,3):
			for i in life.fish_centers.size():
				for member in 3:
					if not life.is_water(life.fish_position(i,member,float(t)),12):contained=false
		check(contained,"Fish remain in water across a three minute cycle")
		life.set_reduced_motion(true)
		var frozen:float=life.elapsed
		life._process(2.0)
		check(is_equal_approx(life.elapsed,frozen),"Reduced motion freezes aquatic animation")
	for fall in valley.get_node("Waterfalls").get_children():
		var foam:Node2D=fall.get_node_or_null("LivingFoam")
		check(foam!=null,"Living foam for "+fall.name)
		if foam:
			var contained:=true
			for t in range(0,60,2):
				for p:Vector2 in foam.ripple_pixels(float(t)):
					if not foam.is_water(p+fall.position):contained=false
			check(contained,"Ripples stay on water for "+fall.name)
			check(foam.ripple_pixels(0)!=foam.ripple_pixels(1),"Ripples spread for "+fall.name)
			foam.set_reduced_motion(true)
			var frozen:float=foam.elapsed
			foam._process(2.0)
			check(is_equal_approx(foam.elapsed,frozen),"Reduced motion freezes "+fall.name)
	print("VALLEY_WATER_TEST ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)

extends SceneTree
var failed := false
func _initialize(): call_deferred("run")
func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run():
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var region := Node2D.new()
	root.add_child(region)
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,720),Vector2(0,720)])
	ground.color = Color(.63,.69,.44)
	ground.z_index = -10
	region.add_child(ground)
	var player = load("res://scenes/player.tscn").instantiate()
	player.get_node("Camera2D").enabled = false
	player.position = Vector2(640,360)
	region.add_child(player)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var lighting = load("res://scripts/world/day_night_lighting.gd").new()
	region.add_child(lighting)
	for i in 4: await process_frame
	var shadows = lighting.get_node("DayShadows")
	root.get_node("GameClock").stop()
	var samples := {}
	for hour in [7,12,17,22]:
		root.get_node("GameClock").set_time(hour)
		lighting._process(0)
		shadows.show()
		var on: Image = await frame_image()
		on.save_png("res://docs/world/day_night/shadow_probe_%02d.png"%hour)
		shadows.hide()
		var off: Image = await frame_image()
		var count := 0
		var sum_x := 0.0
		var min_x := 1280
		var max_x := 0
		for y in range(350,450):
			for x in range(520,770):
				var a := on.get_pixel(x,y)
				var b := off.get_pixel(x,y)
				if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > .02:
					count += 1
					sum_x += x
					min_x = mini(min_x,x)
					max_x = maxi(max_x,x)
		if count == 0: failed=true
		samples[hour] = {"pixels":count,"center_x":sum_x/maxi(count,1),"width":max_x-min_x}
		print("SHADOW_RENDER ",hour," ",samples[hour])
	if samples[7].center_x >= 638 or samples[17].center_x <= 642:failed=true
	if samples[7].width <= samples[12].width or samples[17].width <= samples[12].width:failed=true
	print("SHADOW_RENDER_TEST: ","FAIL" if failed else "PASS"," — native morning/afternoon direction, noon length and moon visibility")
	region.queue_free()
	await process_frame
	quit(1 if failed else 0)

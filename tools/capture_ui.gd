extends SceneTree
## Run with a native renderer: --script res://tools/capture_ui.gd -- menu review 1280 720
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if args.size()>0 else "menu"
	var label := args[1] if args.size()>1 else "review"
	var width := int(args[2]) if args.size()>2 else 1280
	var height := int(args[3]) if args.size()>3 else 720
	root.size = Vector2i(width,height)
	var path := "res://scenes/world.tscn" if mode == "gameplay" else "res://scenes/start_menu.tscn"
	var scene := (load(path) as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(1.6).timeout
	if mode != "gameplay" and not scene.has_node("Actions"):
		push_error("Menu did not initialize; capture rejected.")
		quit(1)
		return
	if mode == "options":
		scene._show_options()
		await create_timer(0.2).timeout
	if mode == "focus" or mode == "pressed":
		var option := scene.get_node("Actions").get_child(2) as Button
		option.grab_focus()
		if mode == "pressed":
			var click := InputEventMouseButton.new()
			click.position = option.get_global_rect().get_center()
			click.global_position = click.position
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			root.push_input(click,true)
		await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	var output := "res://docs/ui/captures/%s_%s_%dx%d.png" % [mode,label,width,height]
	var error := shot.save_png(output)
	print("CAPTURE ",output," result=",error)
	quit(error)

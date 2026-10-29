extends SceneTree
## Headless integration checks of real navigation and the prototype's mission.
## Run: Godot --headless --path <project> --script res://tools/test_menu.gd
## Does not toggle preferences, write user:// files or create a fake save.

var failures: Array[String] = []
var checks: int = 0
var _prefs_existed: bool = false
var _prefs_before := PackedByteArray()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_prefs_existed = FileAccess.file_exists("user://presentation.cfg")
	if _prefs_existed:
		_prefs_before = FileAccess.get_file_as_bytes("user://presentation.cfg")
	root.size = Vector2i(1280, 720)
	var menu := load("res://scenes/start_menu.tscn").instantiate() as Control
	root.add_child(menu)
	current_scene = menu
	await _settle()
	var actions := menu.get_node("Actions") as VBoxContainer
	if not _check(actions.get_child_count() == 4, "Menu contains the four intended actions"):
		_finish()
		return
	var new_game := actions.get_child(0) as Button
	var continue_button := actions.get_child(1) as Button
	var options := actions.get_child(2) as Button
	var exit_button := actions.get_child(3) as Button
	_check(new_game.text == "Novo Jogo" and options.text == "Opções" and exit_button.text == "Sair", "Action labels preserve the actual destinations")
	_check(continue_button.disabled and continue_button.focus_mode == Control.FOCUS_NONE, "Continue is disabled without a save system")
	_check(root.gui_get_focus_owner() == new_game, "Initial focus is New Game")
	var original_motion: bool = menu.reduce_motion
	var water := menu.get_node("Panorama/Valley").get_child(1)
	menu._apply_reduced_motion(true)
	var stopped_age: float = water.age
	await create_timer(0.12).timeout
	_check(is_equal_approx(water.age,stopped_age), "Reduced motion stops the new distant water layer")
	menu._apply_reduced_motion(false)
	await create_timer(0.12).timeout
	_check(water.age > stopped_age, "Turning reduced motion off resumes distant water")
	menu._apply_reduced_motion(original_motion)
	await _key(KEY_DOWN)
	_check(root.gui_get_focus_owner() == options, "Keyboard Down skips disabled Continue")
	await _key(KEY_DOWN)
	_check(root.gui_get_focus_owner() == exit_button, "Keyboard Down reaches Exit")
	await _key(KEY_DOWN)
	_check(root.gui_get_focus_owner() == new_game, "Keyboard navigation wraps to New Game")
	await _joy(JOY_BUTTON_DPAD_DOWN)
	_check(root.gui_get_focus_owner() == options, "Simulated controller D-pad skips disabled Continue")
	await _joy(JOY_BUTTON_DPAD_DOWN)
	_check(root.gui_get_focus_owner() == exit_button, "Simulated controller D-pad reaches Exit")
	await _joy(JOY_BUTTON_DPAD_UP)
	_check(root.gui_get_focus_owner() == options, "Simulated controller D-pad Up returns to Options")
	# Explicit focus prevents a failed preceding navigation from activating Exit.
	options.grab_focus()
	await _key(KEY_ENTER)
	var modal: Control = menu.get("options_layer")
	if not _check(is_instance_valid(modal), "Enter activates the Options action"):
		_finish()
		return
	var reduce_motion := modal.find_child("ReduceMotion", true, false) as CheckButton
	_check(root.gui_get_focus_owner() == reduce_motion, "Options begins with focus inside the modal")
	_check(new_game.focus_mode == Control.FOCUS_NONE and options.focus_mode == Control.FOCUS_NONE and exit_button.focus_mode == Control.FOCUS_NONE, "Background actions cannot steal keyboard focus")
	for index in range(10):
		await _key(KEY_TAB)
		var focused := root.gui_get_focus_owner()
		_check(focused != null and modal.is_ancestor_of(focused), "Tab remains inside Options (%d/10)" % (index + 1))
	_check(root.gui_get_focus_owner() == reduce_motion, "Modal Tab loop returns to first control")
	await _key(KEY_ESCAPE)
	_check(not is_instance_valid(menu.get("options_layer")), "Escape closes Options")
	_check(root.gui_get_focus_owner() == options, "Closing Options restores focus to its opener")
	_check(continue_button.disabled and continue_button.focus_mode == Control.FOCUS_NONE, "Continue remains unavailable after modal close")
	_check(new_game.focus_mode == Control.FOCUS_ALL and exit_button.focus_mode == Control.FOCUS_ALL, "Other actions regain keyboard focus")
	await _mouse_click(options.get_global_rect().get_center())
	_check(is_instance_valid(menu.get("options_layer")), "Mouse click opens Options")
	await _key(KEY_ESCAPE)
	await _mouse_click(new_game.get_global_rect().get_center())
	await _settle()
	var world := current_scene
	if not _check(world != null and world.scene_file_path == "res://scenes/regions/FlorestaDoDespertarV2.tscn", "New Game opens the expanded playable forest"):
		_finish()
		return
	_check(root.content_scale_size == Vector2i(960, 540), "Entering gameplay restores its existing logical canvas")
	var player: CharacterBody2D = world.get("player")
	for i in 6: await physics_frame
	var slimes: Array = world.get("slimes")
	var expected_population := 10 if ResourceLoader.exists("res://assets/slimes/living_v3/musguinho/frames.tres") else 8
	_check(slimes.size() == expected_population and int(world.get("friends_count")) == 0, "A new game starts the habitat population with no stale friendships")
	_check(slimes.filter(func(s):return s.slime_type=="brotinho").size()==8,"New game preserves eight Brotinhos")
	for index in slimes.size():
		var slime := slimes[index] as Node2D
		player.global_position = slime.global_position + Vector2(0, 24)
		await _settle()
		await _key(KEY_E)
		_check(bool(slime.get("befriended")), "E befriends actual slime %d" % (index + 1))
		_check(int(world.get("friends_count")) == index + 1, "Mission counter updates from gameplay (%d/%d)" % [index + 1,expected_population])
	await _key(KEY_E)
	_check(int(world.get("friends_count")) == expected_population, "Repeated interaction does not duplicate a friendship")
	var goal: Label = world.get("hud_goal")
	_check(goal.text.contains("%d/%d"%[expected_population,expected_population]), "HUD reports all genuine friendships")
	var return_button := world.get_node("HUD/Interface/ReturnToMenu") as Button
	return_button.grab_focus()
	await _key(KEY_ENTER)
	await _settle()
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/start_menu.tscn", "Gameplay Menu button returns to the title scene")
	_check(root.content_scale_size == Vector2i.ZERO, "Returning to the menu restores presentation sizing")
	if current_scene != null and current_scene.has_node("Actions"):
		_check(current_scene.get_node("Actions").get_child(1).disabled, "Returning does not invent a save or enable Continue")
	_finish()

func _key(code: Key, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.shift_pressed = shift
	event.pressed = true
	Input.parse_input_event(event)
	await _settle()
	event = event.duplicate() as InputEventKey
	event.pressed = false
	Input.parse_input_event(event)
	await _settle()

func _joy(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await _settle()
	event = event.duplicate() as InputEventJoypadButton
	event.pressed = false
	Input.parse_input_event(event)
	await _settle()

func _mouse_click(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	await _settle()
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event,true)
	await _settle()

func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func _check(condition: bool, description: String) -> bool:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)
	return condition

func _finish() -> void:
	var prefs_exist_after := FileAccess.file_exists("user://presentation.cfg")
	_check(prefs_exist_after == _prefs_existed, "Test did not create or remove presentation preferences")
	if _prefs_existed and prefs_exist_after:
		_check(FileAccess.get_file_as_bytes("user://presentation.cfg") == _prefs_before, "Saved presentation preferences remain byte-identical")
	print("MENU_INTEGRATION: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

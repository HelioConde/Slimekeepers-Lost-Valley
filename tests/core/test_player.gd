extends GdUnitTestSuite

## Movimento em 8 direções, animações montadas a partir dos assets e limites do mundo.

const PlayerScene := preload("res://scenes/player.tscn")
const MOVE_ACTIONS := ["move_left", "move_right", "move_up", "move_down", "sprint"]


func after_test() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)


func _spawn_player() -> CharacterBody2D:
	var player: CharacterBody2D = PlayerScene.instantiate()
	add_child(player)
	auto_free(player)
	return player


func test_direction_names_cover_all_eight_sectors() -> void:
	var player := _spawn_player()
	var cases := {
		Vector2.DOWN: "south", Vector2(1, 1): "south-east",
		Vector2.RIGHT: "east", Vector2(1, -1): "north-east",
		Vector2.UP: "north", Vector2(-1, -1): "north-west",
		Vector2.LEFT: "west", Vector2(-1, 1): "south-west",
	}
	for direction in cases:
		assert_str(player._get_direction_name(direction)).override_failure_message(str(direction)).is_equal(cases[direction])


func test_frames_include_idle_walk_and_run_for_every_direction() -> void:
	var player := _spawn_player()
	var frames: SpriteFrames = player.sprite.sprite_frames
	for direction in player.DIRS:
		for prefix_and_count in [["idle_", 4], ["walk_", 6], ["run_", 8]]:  # idle = respiração em laço (4 quadros)
			var anim: String = prefix_and_count[0] + direction
			assert_bool(frames.has_animation(anim)).override_failure_message(anim).is_true()
			assert_int(frames.get_frame_count(anim)).override_failure_message(anim).is_equal(prefix_and_count[1])
			for i in frames.get_frame_count(anim):
				assert_object(frames.get_frame_texture(anim, i)).override_failure_message("%s[%d]" % [anim, i]).is_not_null()


func test_starts_idle_facing_south_with_foot_collider() -> void:
	var player := _spawn_player()
	assert_str(player.current_animation).is_equal("idle_south")
	var shape := player.get_node("CollisionShape2D").shape as RectangleShape2D
	assert_object(shape).is_not_null()
	assert_vector(shape.size).is_equal(Vector2(18, 12))


func test_walk_and_sprint_speeds_and_facing() -> void:
	var player := _spawn_player()
	player.global_position = player.world_bounds.get_center()
	Input.action_press("move_right")
	player._physics_process(1.0 / 60.0)
	assert_float(player.velocity.length()).is_equal_approx(player.WALK_SPEED, 0.01)
	assert_str(player.facing).is_equal("east")
	assert_str(player.current_animation).is_equal("walk_east")
	Input.action_press("sprint")
	player._physics_process(1.0 / 60.0)
	assert_float(player.velocity.length()).is_equal_approx(player.RUN_SPEED, 0.01)
	assert_str(player.current_animation).is_equal("run_east")


func test_releasing_input_keeps_facing_and_returns_to_idle() -> void:
	var player := _spawn_player()
	player.global_position = player.world_bounds.get_center()
	Input.action_press("move_up")
	player._physics_process(1.0 / 60.0)
	Input.action_release("move_up")
	player._physics_process(1.0 / 60.0)
	assert_vector(player.velocity).is_equal(Vector2.ZERO)
	assert_str(player.current_animation).is_equal("idle_north")


func test_position_is_clamped_to_world_bounds() -> void:
	var player := _spawn_player()
	player.global_position = Vector2(-500, 5000)
	player._physics_process(1.0 / 60.0)
	assert_vector(player.global_position).is_equal(Vector2(player.world_bounds.position.x, player.world_bounds.end.y))


func test_tool_animations_exist_and_lock_movement() -> void:
	var player = auto_free(load("res://scenes/player.tscn").instantiate())
	add_child(player)
	await await_idle_frame()
	var frames: SpriteFrames = player.sprite.sprite_frames
	for dir in player.DIRS:
		for tool in ["hoe", "water", "axe"]:
			var anim := "%s_%s" % [tool, dir]
			assert_bool(frames.has_animation(anim)).override_failure_message(anim).is_true()
			assert_int(frames.get_frame_count(anim)).is_greater_equal(8)
			assert_bool(frames.get_animation_loop(anim)).is_false()
	player.facing = "east"
	var duration: float = player.play_tool("hoe")
	assert_float(duration).is_greater(0.3)
	assert_str(player.current_animation).is_equal("hoe_east")
	assert_bool(player.is_using_tool()).is_true()
	Input.action_press("move_right")
	player._physics_process(0.016)
	Input.action_release("move_right")
	assert_vector(player.velocity).is_equal(Vector2.ZERO)
	assert_str(player.current_animation).is_equal("hoe_east")


func test_moni_has_every_tool_animation() -> void:
	# A arte vem do protagonista escolhido; a Moni tem o mesmo conjunto do Aren.
	get_tree().set_meta("protagonist", "moni")
	var player = auto_free(load("res://scenes/player.tscn").instantiate())
	add_child(player)
	await await_idle_frame()
	get_tree().remove_meta("protagonist")
	var frames: SpriteFrames = player.sprite.sprite_frames
	for dir in player.DIRS:
		for tool in ["hoe", "water", "axe"]:
			var anim := "%s_%s" % [tool, dir]
			assert_bool(frames.has_animation(anim)).override_failure_message(anim).is_true()
			assert_str(frames.get_frame_texture(anim, 0).resource_path).contains("player_moni/tools/")


func test_south_swing_holds_high_and_on_impact() -> void:
	# Golpe aprovado (sul): 9 quadros; pausa no alto (3) e no impacto (7) mais longas
	# que a descida (5, 6). Vale para machado e enxada.
	var player = auto_free(load("res://scenes/player.tscn").instantiate())
	add_child(player)
	await await_idle_frame()
	var frames: SpriteFrames = player.sprite.sprite_frames
	for tool in ["axe", "hoe"]:
		var anim: String = tool + "_south"
		assert_int(frames.get_frame_count(anim)).is_equal(9)
		assert_float(frames.get_frame_duration(anim, 3)).is_greater(frames.get_frame_duration(anim, 5))
		assert_float(frames.get_frame_duration(anim, 7)).is_greater(frames.get_frame_duration(anim, 6))
	player.facing = "south"
	assert_float(player.play_tool("axe")).is_equal_approx(9.5 / 10.0, 0.01)


func test_south_watering_is_frontal_and_timed() -> void:
	# Regar aprovado (sul): 8 quadros, jato (quadro 5) mais longo que a inclinação.
	var player = auto_free(load("res://scenes/player.tscn").instantiate())
	add_child(player)
	await await_idle_frame()
	var frames: SpriteFrames = player.sprite.sprite_frames
	assert_int(frames.get_frame_count("water_south")).is_equal(8)
	assert_float(frames.get_frame_duration("water_south", 4)).is_greater(frames.get_frame_duration("water_south", 2))
	player.facing = "south"
	assert_float(player.play_tool("water")).is_equal_approx(11.3 / 10.0, 0.01)


func test_watering_side_and_back_are_timed_for_both() -> void:
	# Regar de lado (leste; oeste = espelho) e de costas aprovados: 8 quadros com o
	# mesmo tempo do regar de frente. Aren e Moni.
	for who in ["aren", "moni"]:
		get_tree().set_meta("protagonist", who)
		var player = auto_free(load("res://scenes/player.tscn").instantiate())
		add_child(player)
		await await_idle_frame()
		var frames: SpriteFrames = player.sprite.sprite_frames
		for dir in ["east", "west", "north"]:
			var anim: String = "water_" + dir
			assert_int(frames.get_frame_count(anim)).override_failure_message(who + " " + anim).is_equal(8)
			assert_float(frames.get_frame_duration(anim, 4)).is_greater(frames.get_frame_duration(anim, 2))
			player.facing = dir
			player._tool_time = 0.0
			assert_float(player.play_tool("water")).is_equal_approx(11.3 / 10.0, 0.01)
	get_tree().remove_meta("protagonist")


func test_side_swing_holds_high_and_on_impact() -> void:
	# Golpe de lado aprovado (leste; oeste = espelho): 8 quadros, pausa no alto (2)
	# e no impacto (5) maiores que o rastro (3, 4). Aren e Moni.
	for who in ["aren", "moni"]:
		get_tree().set_meta("protagonist", who)
		var player = auto_free(load("res://scenes/player.tscn").instantiate())
		add_child(player)
		await await_idle_frame()
		var frames: SpriteFrames = player.sprite.sprite_frames
		for anim in ["axe_east", "axe_west", "hoe_east", "hoe_west", "axe_north", "hoe_north"]:
			assert_int(frames.get_frame_count(anim)).override_failure_message(who + " " + anim).is_equal(8)
			assert_float(frames.get_frame_duration(anim, 2)).is_greater(frames.get_frame_duration(anim, 3))
			assert_float(frames.get_frame_duration(anim, 5)).is_greater(frames.get_frame_duration(anim, 4))
	get_tree().remove_meta("protagonist")


func test_diagonals_use_side_tool_animation() -> void:
	# Sem diagonais próprias: sudeste/nordeste usam leste; sudoeste/noroeste, oeste.
	var player = auto_free(load("res://scenes/player.tscn").instantiate())
	add_child(player)
	await await_idle_frame()
	for pair in [["south-east", "axe_east"], ["north-east", "hoe_east"], ["south-west", "axe_west"], ["north-west", "hoe_west"]]:
		player.facing = pair[0]
		player._tool_time = 0.0
		player.play_tool(pair[1].split("_")[0])
		assert_str(player.current_animation).is_equal(pair[1])


func test_pick_actions_for_both_and_hold_on_ground() -> void:
	# Pegar no chão aprovado: uma mão (6 quadros) e duas mãos (8), 4 direções, Aren e
	# Moni; a pausa com a mão no chão é a maior. Segurar para no quadro do chão e
	# soltar levanta até o fim.
	for who in ["aren", "moni"]:
		get_tree().set_meta("protagonist", who)
		var player = auto_free(load("res://scenes/player.tscn").instantiate())
		add_child(player)
		await await_idle_frame()
		var frames: SpriteFrames = player.sprite.sprite_frames
		for dir in ["south", "east", "west", "north"]:
			for pair in [["pick_small", 6, 3], ["pick_big", 8, 4]]:
				var anim: String = "%s_%s" % [pair[0], dir]
				assert_int(frames.get_frame_count(anim)).override_failure_message(who + " " + anim).is_equal(pair[1])
				assert_float(frames.get_frame_duration(anim, pair[2])).is_greater(frames.get_frame_duration(anim, 1))
		player.facing = "north-west"
		player._tool_time = 0.0
		assert_float(player.play_tool("pick_small")).is_equal_approx(7.6 / 10.0, 0.01)
		assert_str(player.current_animation).is_equal("pick_small_west")
		player._tool_time = 0.0
		player.facing = "south"
		for i in 50:  # ~1 s de [E] segurado (a descida leva 0,44 s)
			player.hold_pose("pick_big", player.PICK_BIG_GROUND)
			await get_tree().create_timer(0.02).timeout
		assert_str(player.current_animation).is_equal("pick_big_south")
		# Fazendo força: alterna entre o quadro do chão e o anterior.
		assert_int(player.sprite.frame).is_between(player.PICK_BIG_GROUND - 1, player.PICK_BIG_GROUND)
		assert_bool(player.sprite.is_playing()).is_false()
		player.sprite.frame = player.PICK_BIG_GROUND
		assert_float(player.release_pose()).is_equal_approx(3.4 / 10.0, 0.01)
		assert_bool(player.sprite.is_playing()).is_true()
	get_tree().remove_meta("protagonist")

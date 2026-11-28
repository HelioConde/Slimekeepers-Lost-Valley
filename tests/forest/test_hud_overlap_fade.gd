extends GdUnitTestSuite

## HUD: painéis permanentes ficam translúcidos quando o jogador passa por baixo,
## sem esconder informação nem bloquear cliques; voltam ao normal depois.

const Fade := preload("res://scripts/ui/hud_overlap_fade.gd")


func _rig() -> Array:
	var world: Node2D = auto_free(Node2D.new())
	add_child(world)
	var player := Node2D.new()
	world.add_child(player)
	var layer := CanvasLayer.new()
	world.add_child(layer)
	var interface := Control.new()
	interface.size = Vector2(960, 540)
	layer.add_child(interface)
	var panel := PanelContainer.new()
	panel.name = "MissionPanel"
	panel.position = Vector2(18, 16)
	panel.size = Vector2(300, 60)
	interface.add_child(panel)
	var fade: Node = Fade.new()
	fade.target = player
	interface.add_child(fade)
	return [player, panel, fade]


func test_panel_fades_while_player_is_under_it_and_returns() -> void:
	var parts := _rig()
	var player: Node2D = parts[0]
	var panel: PanelContainer = parts[1]
	var fade: Node = parts[2]
	var to_world := get_viewport().get_canvas_transform().affine_inverse()
	player.global_position = to_world * Vector2(120, 80)  # pés logo abaixo do painel
	for i in 30: fade.step(1.0 / 30.0)
	assert_float(panel.modulate.a).is_less_equal(Fade.FADED_ALPHA + 0.01)
	assert_bool(panel.visible).is_true()
	player.global_position = to_world * Vector2(600, 400)
	for i in 30: fade.step(1.0 / 30.0)
	assert_float(panel.modulate.a).is_equal_approx(1.0, 0.01)


func test_player_box_covers_head_above_feet() -> void:
	var box: Rect2 = Fade.player_screen_box(Vector2(400, 300), Transform2D.IDENTITY)
	assert_bool(box.has_point(Vector2(400, 260))).is_true()
	assert_bool(box.has_point(Vector2(400, 330))).is_false()

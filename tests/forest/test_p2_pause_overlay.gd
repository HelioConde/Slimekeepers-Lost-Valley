extends GdUnitTestSuite

## p2-keyboard-feedback: Esc pausa a exploração com foco no botão Continuar e
## Esc/Continuar retomam. Nunca aguarda frames com a árvore pausada.

const PauseOverlay := preload("res://scripts/ui/pause_overlay.gd")
const REGION_SCRIPTS := [
	"res://scripts/world/forest_region.gd",
	"res://scripts/world/valley_region.gd",
	"res://scripts/world/clearing_region.gd",
]


func after_test() -> void:
	get_tree().paused = false


func _spawn() -> CanvasLayer:
	var overlay: CanvasLayer = PauseOverlay.new()
	add_child(overlay)
	auto_free(overlay)
	return overlay


func _press_cancel(overlay: CanvasLayer) -> void:
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	overlay._unhandled_input(event)


func test_starts_hidden_and_keeps_running_while_paused() -> void:
	var overlay := _spawn()
	assert_bool(overlay.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_int(overlay.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)


func test_escape_pauses_and_focuses_continue() -> void:
	var overlay := _spawn()
	_press_cancel(overlay)
	assert_bool(get_tree().paused).is_true()
	assert_bool(overlay.is_open()).is_true()
	var button: Button = overlay.continue_button
	assert_str(button.text).is_equal("Continuar")
	assert_object(button.get_viewport().gui_get_focus_owner()).is_same(button)
	get_tree().paused = false


func test_escape_again_resumes() -> void:
	var overlay := _spawn()
	_press_cancel(overlay)
	_press_cancel(overlay)
	assert_bool(get_tree().paused).is_false()
	assert_bool(overlay.is_open()).is_false()


func test_continue_button_resumes() -> void:
	var overlay := _spawn()
	_press_cancel(overlay)
	overlay.continue_button.pressed.emit()
	assert_bool(get_tree().paused).is_false()
	assert_bool(overlay.is_open()).is_false()


func test_ignores_other_actions_and_released_cancel() -> void:
	var overlay := _spawn()
	var interact := InputEventAction.new()
	interact.action = "interact"
	interact.pressed = true
	overlay._unhandled_input(interact)
	var released := InputEventAction.new()
	released.action = "ui_cancel"
	released.pressed = false
	overlay._unhandled_input(released)
	assert_bool(get_tree().paused).is_false()


func test_does_not_steal_an_existing_pause() -> void:
	var overlay := _spawn()
	get_tree().paused = true
	_press_cancel(overlay)
	assert_bool(overlay.is_open()).is_false()
	assert_bool(get_tree().paused).is_true()


func test_every_exploration_region_installs_the_overlay() -> void:
	for path in REGION_SCRIPTS:
		var source := FileAccess.get_file_as_string(path)
		assert_str(source).override_failure_message(path).contains("PauseOverlay.new()")

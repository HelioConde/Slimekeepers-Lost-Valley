extends GdUnitTestSuite

## Regressões do Godot MCP:
## 1. No editor os autoloads de bridge não existem; _queue_input descartava eventos.
##    Agora grava a fila em user:// que o MCPInputBridge do jogo consome.
## 2. Bridges paravam com get_tree().paused; precisam de PROCESS_MODE_ALWAYS.

const BaseCommands := preload("res://addons/godot_mcp/commands/base_commands.gd")
const InputBridge := preload("res://addons/godot_mcp/services/mcp_input_bridge.gd")
const BRIDGES := [
	"res://addons/godot_mcp/services/mcp_input_bridge.gd",
	"res://addons/godot_mcp/services/mcp_runtime_bridge.gd",
	"res://addons/godot_mcp/services/mcp_screenshot_bridge.gd",
]

var _queue_path := OS.get_user_data_dir().path_join("mcp_input_queue.json")


func before_test() -> void:
	DirAccess.remove_absolute(_queue_path)


func after_test() -> void:
	DirAccess.remove_absolute(_queue_path)
	Input.action_release("ui_cancel")


func test_queue_input_writes_file_without_bridge_node() -> void:
	var commands: Node = auto_free(BaseCommands.new())
	commands._queue_input([{"type": "action", "action": "ui_cancel", "pressed": true}])
	commands._queue_input([{"type": "action", "action": "ui_cancel", "pressed": false}])
	assert_bool(FileAccess.file_exists(_queue_path)).is_true()
	var queued = JSON.parse_string(FileAccess.get_file_as_string(_queue_path))
	assert_array(queued).has_size(2)
	assert_str(queued[0]["action"]).is_equal("ui_cancel")


func test_bridge_applies_queued_action_and_consumes_file() -> void:
	var commands: Node = auto_free(BaseCommands.new())
	commands._queue_input([{"type": "action", "action": "ui_cancel", "pressed": true}])
	var bridge: Node = auto_free(InputBridge.new())
	bridge._process(0.0)
	assert_bool(Input.is_action_pressed("ui_cancel")).is_true()
	assert_bool(FileAccess.file_exists(_queue_path)).is_false()


func test_key_event_sets_physical_keycode_for_physical_bindings() -> void:
	var bridge: Node = auto_free(InputBridge.new())
	var event: InputEventKey = bridge._key_event(KEY_ESCAPE, true)
	assert_int(event.keycode).is_equal(KEY_ESCAPE)
	assert_int(event.physical_keycode).is_equal(KEY_ESCAPE)
	assert_bool(event.is_action_pressed("ui_cancel")).is_true()


func test_bridges_keep_running_while_tree_is_paused() -> void:
	for path in BRIDGES:
		var bridge: Node = auto_free(load(path).new())
		add_child(bridge)
		assert_int(bridge.process_mode).override_failure_message(path).is_equal(Node.PROCESS_MODE_ALWAYS)

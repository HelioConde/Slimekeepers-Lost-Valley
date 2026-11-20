extends GdUnitTestSuite

## Regressão: get_project_info devolvia autoloads vazios porque lia a chave
## inexistente "autoload" em vez das chaves "autoload/<Nome>".

const ProjectCommands := preload("res://addons/godot_mcp/commands/project_commands.gd")


func test_collect_autoloads_reads_each_autoload_entry() -> void:
	var autoloads: Dictionary = ProjectCommands.collect_autoloads()
	assert_dict(autoloads).contains_key_value("GameClock", "*res://scripts/systems/game_clock.gd")
	assert_dict(autoloads).contains_keys(["MCPRuntimeBridge", "MCPInputBridge", "MCPScreenshotBridge"])


func test_collect_autoloads_keys_have_no_prefix() -> void:
	for key in ProjectCommands.collect_autoloads().keys():
		assert_str(str(key)).not_contains("autoload/")

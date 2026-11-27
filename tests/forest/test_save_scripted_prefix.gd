extends GdUnitTestSuite
## Testes e capturas rodam por script: o autosave não pode cair nos espaços do jogador
## (2026-11-27: abrir a Floresta num teste sobrescreveu o espaço 1).

const Save := preload("res://scripts/systems/save_game.gd")


func after_test() -> void:
	Save.prefix = Save.DEFAULT_PREFIX


func test_default_prefix_is_redirected_when_scripted() -> void:
	assert_bool(Save.scripted_run()).is_true()
	Save.prefix = Save.DEFAULT_PREFIX
	assert_str(Save.slot_path(1)).starts_with(Save.SCRIPTED_PREFIX)
	assert_str(Save.slot_path(1)).is_not_equal("user://slimekeepers_slot_1.txt")


func test_explicit_test_prefix_is_kept() -> void:
	Save.prefix = "user://test_x_"
	assert_str(Save.slot_path(2)).is_equal("user://test_x_2.txt")

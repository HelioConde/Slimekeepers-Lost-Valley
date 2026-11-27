extends SceneTree
## Atalho de teste do primeiro boss: abre a Floresta já no pé da arena do Mirante
## Rochoso, com o boss liberado, espada, arco e 30 flechas. Por ser rodado por script,
## salva em user://test_run_slot_* e não mexe no save do jogador.
## Uso: godot --path . --script res://tools/play_boss.gd


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	set_meta("tutorial_step", 99)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	current_scene = region
	for i in 10: await process_frame
	var admin := region.get_node_or_null("AdminCommands")
	if admin: print(admin.call("run", "boss"))
	admin.call("run", "vida")
	admin.call("run", "energia")
	var hotbar := preload("res://scripts/systems/hotbar_state.gd")
	hotbar.select(self, hotbar.slots(self).find("espada"))
	var arena: Node2D = region.get_node("BossArena")
	(region.get("player") as Node2D).global_position = arena.global_position + Vector2(0, 160)

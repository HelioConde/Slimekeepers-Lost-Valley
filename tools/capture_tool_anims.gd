extends SceneTree
## Captura real: Novo Jogo com Aren e com Moni, machado/enxada/regador na bolsa,
## cada ferramenta selecionada na barra e usada. Confere que a animação existe em
## todas as direções e salva o meio do golpe ao lado da barra.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/capture_tool_anims.gd -- OUT_DIR

const HELPER := preload("res://tools/new_game_helper.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const TOOLS := {"machado": "axe", "enxada": "hoe", "regador": "water"}
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else ""
	if not out.is_empty(): DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for who in ["aren", "moni"]:
		change_scene_to_file("res://scenes/start_menu.tscn")
		for i in 30: await process_frame
		current_scene.call("_start_game")
		await HELPER.through_selection(self, who)
		var player: CharacterBody2D = current_scene.get("player")
		for item in TOOLS: BAG.add_item(self, item)
		for i in 10: await process_frame
		for item in TOOLS:
			var tool: String = TOOLS[item]
			for dir in player.DIRS:
				check(player.sprite.sprite_frames.has_animation("%s_%s" % [tool, dir]), "%s %s_%s" % [who, tool, dir])
			HOTBAR.select(self, HOTBAR.slots(self).find(item))
			for facing in (["south", "east", "west", "north"] if tool != "water" else ["south"]):
				player.facing = facing
				player.play_tool(tool)
				# Impacto: sul = quadro 7, lado = quadro 5; regador: meio da animação.
				var target := 4 if tool == "water" else (7 if facing == "south" else 5)
				for i in 240:
					if player.sprite.frame >= target: break
					await process_frame
				check(HOTBAR.selected_item(self) == item, "%s: barra com %s" % [who, item])
				if not out.is_empty():
					await RenderingServer.frame_post_draw
					var suffix: String = "" if facing == "south" else "_" + facing
					root.get_texture().get_image().save_png("%s/%s_%s%s.png" % [out, who, tool, suffix])
				while player.is_using_tool(): await process_frame
	print("TOOL_ANIMS: %d failures" % failures)
	quit(1 if failures else 0)

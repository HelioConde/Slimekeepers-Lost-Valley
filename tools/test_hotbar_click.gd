extends SceneTree
## Clique num espaço da barra rápida escolhe o item (pedido do usuário, 2026-11-23).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_hotbar_click.gd

const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 20: await process_frame
	var bar: Control = region.get_node("HUD/Interface/Hotbar")
	var slots: Array = bar.find_children("*", "Control", true, false).filter(func(c: Control) -> bool: return c.mouse_filter == Control.MOUSE_FILTER_STOP)
	check(slots.size() >= 10, "10 espaços clicáveis (%d)" % slots.size())
	var target: Control = slots[2]
	var at := target.get_global_rect().get_center()
	var vp := region.get_viewport()
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		vp.push_input(ev, true)
		await process_frame
	check(HOTBAR.selected_index(self) == 2, "clique no 3º espaço escolhe ele (%d)" % HOTBAR.selected_index(self))
	# Playtest ID 37: a dica longa do modo construção não alarga a barra.
	var width := bar.size.x
	region.get("hud_hint").text = "[F] Construir a casa aqui · arraste para escolher o tamanho · clique direito cancela · Esc sai do modo construção"
	bar.call("_update_title")
	for i in 3: await process_frame
	check(absf(bar.size.x - width) < 1.0, "dica longa não alarga a barra (%.0f → %.0f)" % [width, bar.size.x])
	var badges: Array = bar.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	check("0" in badges and not "10" in badges, "décimo espaço numerado 0 (ID 38)")
	print("HOTBAR_CLICK: %d failures" % failures)
	quit(1 if failures else 0)

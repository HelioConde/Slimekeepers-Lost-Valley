extends SceneTree
## Itens no chão e clique do mouse (pedidos do usuário, 2026-11-22), na Floresta:
## - pegar um graveto: o item cai e quica, só depois entra na bolsa (ímã);
## - fora do alcance do ímã o item fica no chão; perto, é puxado;
## - bolsa cheia: o item espera no chão;
## - clique esquerdo dentro do alcance = [E] (vira para o clique; segurar = segurar [E]).
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_drops_and_click.gd

const BAG := preload("res://scripts/systems/forest_bag.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func click(region: Node2D, world: Vector2, hold: float) -> void:
	var vp := region.get_viewport()
	var screen: Vector2 = vp.get_canvas_transform() * world
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = screen
	down.global_position = screen
	Input.warp_mouse(screen)
	vp.push_input(down, true)  # coordenadas da viewport (a janela é esticada)
	await create_timer(hold).timeout
	var up := down.duplicate()
	up.pressed = false
	vp.push_input(up, true)
	await process_frame


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for k in ["forest_bag_items", "forage_taken"]:
		if has_meta(k): remove_meta(k)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	await physics_frame
	for i in 5: await process_frame
	var player: Node2D = region.get("player")
	(player.get_node("Camera2D") as Camera2D).position_smoothing_enabled = false
	var drops: Node2D = region.get("item_drops")
	check(is_instance_valid(drops), "Floresta tem itens no chão (ímã)")
	var forage: Node2D = region.get("forage")
	var sticks: Array = forage.spots.filter(func(s: Dictionary) -> bool: return s.item == "graveto")
	# 1) Pegar com [E]: cai, quica e só depois vai para a bolsa.
	var spot: Dictionary = sticks[0]
	player.global_position = spot.at + Vector2(0, 8)
	for i in 3: await physics_frame
	var down := InputEventAction.new()
	down.action = "interact"
	down.pressed = true
	Input.parse_input_event(down)
	await create_timer(1.2).timeout  # graveto: segurar [F] 1 s
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	check(BAG.count_item(self, "graveto") == 0 and drops.pending() == 1, "Graveto caiu no chão (ainda não está na bolsa)")
	await create_timer(2.2).timeout
	check(BAG.count_item(self, "graveto") == 1 and drops.pending() == 0, "Depois das quicadas o ímã leva o graveto à bolsa")
	# 2) Fora do alcance fica; perto, é puxado.
	drops.spawn("pedra_pequena", 1, player.global_position + Vector2(200, 0))
	await create_timer(1.8).timeout
	check(drops.pending() == 1 and BAG.count_item(self, "pedra_pequena") == 0, "Item longe (200 px) fica no chão")
	player.global_position = (drops.drops[0].node as Node2D).global_position + Vector2(-30, 0)  # vai até o item
	for i in 3: await physics_frame
	await create_timer(1.6).timeout
	check(drops.pending() == 0 and BAG.count_item(self, "pedra_pequena") == 1, "Chegando perto, o ímã puxa o item")
	# 3) Bolsa cheia: espera no chão.
	BAG.add_item(self, "fibra", 99)
	drops.spawn("fibra", 1, player.global_position + Vector2(16, 0))
	await create_timer(1.8).timeout
	check(drops.pending() == 1, "Bolsa cheia: o item espera no chão")
	BAG.spend_item(self, "fibra", 10)
	await create_timer(1.6).timeout
	check(drops.pending() == 0 and BAG.count_item(self, "fibra") == 90, "Com espaço, o item entra na bolsa")
	# 4) Clique esquerdo no graveto = [E].
	var spot2: Dictionary = sticks[1]
	player.global_position = spot2.at + Vector2(-40, 0)
	player.facing = "west"
	for i in 3: await physics_frame
	for i in 3: await process_frame
	await click(region, spot2.at, 1.3)  # segurar o clique = segurar [F]
	check(str(player.facing) == "east", "Clique vira o personagem para o ponto clicado (%s)" % player.facing)
	await create_timer(2.2).timeout
	check(BAG.count_item(self, "graveto") == 2, "Clique esquerdo (segurado) pega o graveto como o [F] (%d, pull=%s, drops=%d, taken=%s)" % [BAG.count_item(self, "graveto"), region.get("gathering").get("_pull_id") if region.get("gathering") else "?", drops.pending(), "-"])
	# Clique longe (fora do alcance) não faz nada.
	var before := BAG.count_item(self, "graveto")
	await click(region, player.global_position + Vector2(300, 0), 0.1)
	await create_timer(0.5).timeout
	check(BAG.count_item(self, "graveto") == before, "Clique fora do alcance não age")
	print("DROPS_CLICK: %d failures" % failures)
	quit(1 if failures else 0)

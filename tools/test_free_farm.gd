extends SceneTree
## Plantio livre (FAZENDA.md) no jogo real, Floresta e Vale: sem canteiros nem campo
## fixo; com a enxada ara a grama livre à frente (decoração some), planta semente
## silvestre, rega, cresce com os dias, colhe folhas frescas e cozinha no fogão.
## Árvore/pedra/água não são aráveis.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_free_farm.gd -- [OUT_DIR]

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const FARM := preload("res://scripts/systems/farm_state.gd")
const REGIONS := {"floresta": "res://scenes/regions/FlorestaDoDespertarV2.tscn",
	"vale": "res://scenes/regions/ValeDasNascentes.tscn"}
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func press() -> void:
	var down := InputEventAction.new()
	down.action = "interact"
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	await create_timer(1.6).timeout  # termina o golpe/rega


func select(item: String) -> void:
	HOTBAR.select(self, HOTBAR.slots(self).find(item))
	await process_frame


func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var clock: Node = root.get_node("GameClock")
	for name: String in REGIONS:
		for k in [FARM.KEY, BAG.INVENTORY_KEY, "player_energy", "player_house", "forage_taken", FARM.CAN_KEY]:
			if has_meta(k): remove_meta(k)
		var region: Node2D = load(REGIONS[name]).instantiate()
		root.add_child(region)
		for i in 30: await process_frame
		await physics_frame
		for i in 5: await process_frame
		var farm: Node2D = region.get("farm")
		check(is_instance_valid(farm) and farm.free_area, "%s: plantio livre presente" % name)
		check(region.get_node_or_null("StarterGarden") == null and region.get_node_or_null("CookingStation") == null, "%s: sem canteiros nem fogueira" % name)
		var player: Node2D = region.get("player")
		(player.get_node("Camera2D") as Camera2D).position_smoothing_enabled = false
		for item in ["enxada", "regador"]: BAG.add_item(self, item)
		BAG.add_item(self, "sementes_silvestres", 2)
		for i in 3: await process_frame
		# Célula livre ao sul do jogador (procura em volta do início).
		var cell := Vector2i(-1, -1)
		var start: Vector2i = farm.cell_at(player.global_position)
		for r in range(2, 14):
			for dx in range(-r, r + 1):
				var c := start + Vector2i(dx, r)
				if farm.contains(c) and farm.contains(c + Vector2i(0, -1)):
					cell = c
					break
			if cell.x != -1: break
		check(cell.x != -1, "%s: chão livre arável perto do início %s" % [name, str(cell)])
		player.global_position = Vector2((cell + Vector2i(0, -1)) * 32) + Vector2(16, 16)
		player.facing = "south"
		for i in 3: await physics_frame
		await select("enxada")
		for i in 3: await process_frame
		check(str(region.hud_hint.text).contains("Arar"), "%s: enxada na grama oferece arar (%s)" % [name, region.hud_hint.text])
		await press()
		check(FARM.is_tilled(self, cell, farm.field_id), "%s: enxada ara a célula à frente" % name)
		if not out.is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_arado.png" % [out, name])
		await select("sementes_silvestres")
		await press()
		check(FARM.crop(self, cell, farm.field_id) == "folhas_silvestres" and BAG.count_item(self, "sementes_silvestres") == 1, "%s: planta semente silvestre" % name)
		var days := 0
		while not FARM.is_ready(self, cell, farm.field_id) and days < 8:
			await select("regador")
			await press()
			clock.advance_minutes(24 * 60.0)
			for i in 3: await process_frame
			days += 1
		check(FARM.is_ready(self, cell, farm.field_id), "%s: regada todo dia, fica pronta em %d dias" % [name, days])
		check(FARM.can_water(self) == FARM.CAN_MAX - days, "%s: cada rega gasta 1 de água do regador (%d)" % [name, FARM.can_water(self)])
		await press()
		check(BAG.count_item(self, "folhas_frescas") >= 1, "%s: colhe folhas frescas" % name)
		# Regador vazio não rega; enche olhando para a água (lago da Floresta).
		if name == "floresta":
			set_meta(FARM.CAN_KEY, 0)
			var dry_cell := cell + Vector2i(1, 0)
			if farm.contains(dry_cell):
				player.global_position = Vector2((dry_cell + Vector2i(0, -1)) * 32) + Vector2(16, 16)
				player.facing = "south"
				for i in 3: await physics_frame
				await select("enxada")
				await press()
				await select("regador")
				for i in 3: await process_frame
				check(str(region.hud_hint.text).contains("vazio"), "floresta: regador vazio avisa (%s)" % region.hud_hint.text)
				await press()
				check(not FARM.is_watered(self, dry_cell, farm.field_id), "floresta: regador vazio não rega")
			var spring: Node2D = region.get_node("NaturalSpring")
			var bank: Vector2 = spring.get_node("InteractionPoint").global_position
			var pool: Polygon2D = region.get_node("NaturalSpring/Pool/Water")
			var center := Vector2.ZERO
			for v in pool.polygon: center += pool.to_global(v)
			center /= pool.polygon.size()
			player.global_position = bank
			player.facing = player._get_direction_name(center - bank)
			for i in 3: await physics_frame
			for i in 3: await process_frame
			check(str(region.hud_hint.text).contains("Encher"), "floresta: na margem, regador oferece encher (%s)" % region.hud_hint.text)
			await press()
			check(FARM.can_water(self) == FARM.CAN_MAX, "floresta: [E] na água enche o regador")
		# Árvore não é arável.
		var chop: Node = region.get("gathering").choppable if region.get("gathering") else region.get("choppable")
		var any_tree: Node2D = chop.trees[chop.trees.keys()[0]]
		check(not farm.contains(farm.cell_at(any_tree.global_position + Vector2(0, -8))), "%s: tronco de árvore não é arável" % name)
		region.queue_free()
		await process_frame
		await process_frame
	print("FREE_FARM: %d failures" % failures)
	quit(1 if failures else 0)

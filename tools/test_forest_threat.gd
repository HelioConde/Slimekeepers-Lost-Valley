extends SceneTree
## Slimes da Floresta antes do boss e pet (decisões do usuário, 2026-11-27;
## docs/gameplay/BOSS_BROTINHO.md, "Liberar o boss"): pontos (matar 1, domar 5, total 20),
## dificuldade pela mistura, morte com gosma e volta em 2 dias, amigos protegidos,
## agressão sem perseguir (Bolhinha foge; comida na mão acalma; tutorial nunca ataca),
## pet que segue e ajuda (Brotinho atira, Bolhinha cura, Musguinho deixa lento) e desmaia.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/test_forest_threat.gd

const THREAT := preload("res://scripts/combat/forest_threat.gd")
const ARENA := preload("res://scripts/combat/boss_arena.gd")
const HEALTH := preload("res://scripts/systems/health_state.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const COMBAT := preload("res://scripts/combat/player_combat.gd")
const PET := preload("res://scripts/combat/slime_pet.gd")
var failures := 0
var region: Node2D
var player: CharacterBody2D


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures += 1


func frames(n: int = 3) -> void:
	for i in n: await process_frame


func slime_of(species: String) -> Node2D:
	for slime: Node2D in region.get("slimes"):
		if not is_instance_valid(slime) or str(slime.get("slime_type")) != species: continue
		if bool(slime.get("befriended")) or (slime.get("habitat") as Dictionary).get("near_spawn", false): continue
		return slime
	return null


## Jogador ao lado do slime, parado.
func stand_by(slime: Node2D, gap: float) -> void:
	player.global_position = slime.global_position + Vector2(gap, 0)
	player.velocity = Vector2.ZERO
	await frames(2)


func goo_dropped(item: String) -> bool:
	var drops: Node = region.get("item_drops")
	if drops:
		for entry: Dictionary in drops.get("drops"):
			if str(entry.get("item", "")) == item: return true
	return BAG.count_item(self, item) > 0


func run() -> void:
	set_meta("tutorial_step", 99)
	region = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	current_scene = region
	await frames(30)
	player = region.get("player")
	# --- Pontos e dificuldade ---------------------------------------------------------
	set_meta(THREAT.FRIENDS_KEY, {})
	set_meta(THREAT.KILLS_KEY, 19)
	check(THREAT.points(self) == 19 and not ARENA.unlocked(self), "19 pontos: boss ainda não aparece")
	set_meta(THREAT.KILLS_KEY, 20)
	check(ARENA.unlocked(self) and THREAT.difficulty(self) == "dificil", "matar 20: boss liberado, difícil")
	set_meta(THREAT.KILLS_KEY, 0)
	set_meta(THREAT.FRIENDS_KEY, {"a": true, "b": true, "c": true, "d": true})
	check(ARENA.unlocked(self) and THREAT.difficulty(self) == "facil", "domar 4: boss liberado, fácil")
	set_meta(THREAT.KILLS_KEY, 10)
	set_meta(THREAT.FRIENDS_KEY, {"a": true, "b": true})
	check(THREAT.points(self) == 20 and THREAT.difficulty(self) == "medio", "matar 10 e domar 2: liberado, médio")
	check(is_equal_approx(float(THREAT.BOSS_HP.facil), 0.7) and is_equal_approx(float(THREAT.BOSS_HP.dificil), 1.3), "vida do boss: fácil 70%, difícil 130%")
	set_meta(THREAT.KILLS_KEY, 0)
	set_meta(THREAT.FRIENDS_KEY, {})
	set_meta(THREAT.DEAD_KEY, {})
	# Anda pelo mapa para os slimes nascerem (o spawn não nasce dentro da tela).
	for spot in [Vector2(1800, 2400), Vector2(4200, 4200), Vector2(2400, 4600), Vector2(4600, 2200)]:
		player.global_position = spot
		await create_timer(1.5).timeout
	var count := (region.get("slimes") as Array).size()
	check(count >= 3, "slimes da Floresta nasceram (%d)" % count)
	var mean := slime_of("brotinho")
	if mean == null: mean = slime_of("musguinho")
	check(mean != null, "há um slime agressivo para testar")
	if mean == null:
		quit(1)
		return
	# --- Agressão ----------------------------------------------------------------------
	HOTBAR.select(self, -1)
	set_meta(HEALTH.KEY, 100)
	await stand_by(mean, 34.0)
	await create_timer(1.2).timeout
	check(HEALTH.current(self) < 100 and (100 - HEALTH.current(self)) % THREAT.SLIME_DAMAGE == 0, "slime ataca quem chega perto: -%d por golpe (vida %d)" % [THREAT.SLIME_DAMAGE, HEALTH.current(self)])
	# Não persegue: longe do pulo, não chega no jogador.
	await create_timer(1.8).timeout
	set_meta(HEALTH.KEY, 100)
	await stand_by(mean, 140.0)
	await create_timer(2.0).timeout
	check(HEALTH.current(self) == 100 and mean.global_position.distance_to(player.global_position) > 90.0, "não persegue o jogador que se afasta")
	# Comida na mão: não ataca.
	BAG.add_item(self, "cenoura_assada", 3)
	HOTBAR.select(self, HOTBAR.slots(self).find("cenoura_assada"))
	set_meta(HEALTH.KEY, 100)
	await stand_by(mean, 34.0)
	await create_timer(1.5).timeout
	check(HEALTH.current(self) == 100, "com comida na mão o slime não ataca (vida %d)" % HEALTH.current(self))
	HOTBAR.select(self, -1)
	# Bolhinha foge e não ataca.
	var bubble := slime_of("bolhinha")
	if bubble == null:  # a Floresta de hoje não tem Bolhinha: cria uma num habitat para testar
		var manager: Node2D = region.get("habitat_manager")
		var home: Dictionary = (manager.get("habitats") as Array)[0]
		bubble = manager.SLIME_SCRIPT.new()  # sem preload: o script usa o autoload GameClock
		bubble.configure(manager, player, home, "bolhinha/TESTE/0")
		bubble.position = home.center
		region.add_child(bubble)
		manager.emit_signal("slime_spawned", bubble)
		await frames(3)
	if bubble:
		set_meta(HEALTH.KEY, 100)
		await stand_by(bubble, 60.0)
		var before := bubble.global_position.distance_to(player.global_position)
		await create_timer(2.0).timeout
		var after := bubble.global_position.distance_to(player.global_position)
		check(HEALTH.current(self) == 100 and after > before, "Bolhinha foge e não ataca (%.0f -> %.0f px)" % [before, after])
	else:
		print("SKIP: nenhuma Bolhinha por perto")
	# Tutorial: o slime perto da casa nunca ataca.
	var saved: Dictionary = mean.get("habitat")
	mean.set("habitat", {"near_spawn": true})
	check(not bool(mean.call("aggressive")), "slime do tutorial (perto da casa) nunca ataca")
	mean.set("habitat", saved)
	# Área pacificada (boss vencido): não ataca.
	set_meta(THREAT.PACIFIED_KEY, {THREAT.AREA: true})
	check(not bool(mean.call("aggressive")), "depois do boss vencido, slimes não atacam")
	set_meta(THREAT.PACIFIED_KEY, {})
	# --- Morte, gosma e volta ----------------------------------------------------------
	var id := str(mean.get("persistent_id"))
	var species := str(mean.get("slime_type"))
	for i in 3: mean.call("take_hit", COMBAT.SWORD_DAMAGE, player.global_position)
	await create_timer(0.6).timeout
	check(not is_instance_valid(mean), "3 golpes de espada matam o slime")
	check(THREAT.kills(self) == 1 and THREAT.is_dead(self, id), "morte conta 1 ponto e marca o slime como morto")
	check(goo_dropped("gosma_" + species), "solta gosma de %s" % species)
	var clock: Node = root.get_node("GameClock")
	clock.set("day_number", int(clock.get("day_number")) + 1)
	check(THREAT.is_dead(self, id), "um dia depois ainda não voltou")
	clock.set("day_number", int(clock.get("day_number")) + 1)
	check(not THREAT.is_dead(self, id), "dois dias depois o spawn pode trazer de volta")
	# --- Amigo protegido -----------------------------------------------------------------
	var friend := slime_of("brotinho")
	if friend == null: friend = slime_of("musguinho")
	friend.call("make_friend")
	var hp_before: int = friend.get("hp")
	friend.call("take_hit", COMBAT.SWORD_DAMAGE, player.global_position)
	check(int(friend.get("hp")) == hp_before and not friend.is_in_group("combat_target"), "amigo não toma golpe (protegido)")
	# --- Pet --------------------------------------------------------------------------
	region.call("slime_action", friend, "pet", "")
	await frames(3)
	var helper: Node = friend.get_node_or_null("SlimePet")
	check(helper != null and THREAT.pet_id(self) == str(friend.get("persistent_id")), "Levar comigo: o amigo vira pet")
	player.global_position += Vector2(260, 0)
	await create_timer(3.0).timeout
	check(friend.global_position.distance_to(player.global_position) < 90.0, "pet segue o jogador (%.0f px)" % friend.global_position.distance_to(player.global_position))
	# Na luta.
	set_meta(COMBAT.GOD_KEY, true)
	set_meta(ARENA.UNLOCK_KEY, true)
	var arena: Node2D = region.get_node("BossArena")
	player.global_position = arena.global_position + Vector2(0, 100)
	await create_timer(2.5).timeout
	var boss: Node2D = arena.get("boss")
	check(is_instance_valid(boss), "boss surgiu com o pet junto")
	boss.set("_busy", true)
	friend.global_position = player.global_position + Vector2(30, 0)
	var effect_ok := false
	match str(friend.get("slime_type")):
		"brotinho":
			var hp0: int = boss.get("hp")
			await create_timer(5.0).timeout
			effect_ok = int(boss.get("hp")) < hp0
		"musguinho":
			helper.set("_cooldown", 0.0)
			await create_timer(0.5).timeout
			effect_ok = float(boss.get("slowed")) > 0.0
	check(effect_ok, "pet %s ajuda na luta" % friend.get("slime_type"))
	# A outra espécie de ataque/apoio: Musguinho deixa o boss lento (ou Brotinho atira).
	var other_species := "musguinho" if str(friend.get("slime_type")) == "brotinho" else "brotinho"
	var other := slime_of(other_species)
	if other:
		other.call("make_friend")
		THREAT.set_pet(self, str(other.get("persistent_id")))
		region.call("sync_pet")
		await frames(3)
		other.global_position = player.global_position + Vector2(-30, 0)
		var helper2: Node = other.get_node_or_null("SlimePet")
		var hp1: int = boss.get("hp")
		if helper2: helper2.set("_cooldown", 0.0)
		await create_timer(2.5).timeout
		var ok2 := float(boss.get("slowed")) > 0.0 if other_species == "musguinho" else int(boss.get("hp")) < hp1
		check(friend.get_node_or_null("SlimePet") == null and ok2, "trocar de pet: só um por vez; pet %s ajuda na luta" % other_species)
	else:
		print("SKIP: nenhum %s livre para testar" % other_species)
	# Bolhinha cura.
	if is_instance_valid(bubble):
		bubble.call("make_friend")
		THREAT.set_pet(self, str(bubble.get("persistent_id")))
		region.call("sync_pet")
		await frames(3)
		bubble.global_position = player.global_position + Vector2(-30, 0)
		set_meta(COMBAT.GOD_KEY, false)
		set_meta(HEALTH.KEY, 50)
		await create_timer(2.5).timeout
		check(HEALTH.current(self) > 50, "pet Bolhinha cura o jogador (vida %d)" % HEALTH.current(self))
		set_meta(COMBAT.GOD_KEY, true)
	# Desmaio: golpes do boss no pet.
	var pet_node: Node2D = null
	for slime: Node2D in region.get("slimes"):
		if is_instance_valid(slime) and slime.get_node_or_null("SlimePet"): pet_node = slime
	check(pet_node != null, "há um pet em campo")
	if pet_node:
		var pet_helper: Node = pet_node.get_node("SlimePet")
		var pid := str(pet_node.get("persistent_id"))
		boss.call("_impact", pet_node.global_position, 40.0, 22, Color.RED)
		check(int(pet_helper.get("hp")) == PET.PET_HP - 22, "pet toma dano do golpe do boss")
		for i in 8: boss.call("_impact", pet_node.global_position, 40.0, 22, Color.RED)
		await frames(3)
		check(not is_instance_valid(pet_node) and THREAT.pet_id(self) == "" and THREAT.pet_resting(self, pid), "pet desmaia, volta para casa e descansa até amanhã")
	print("FOREST_THREAT: %d failures" % failures)
	quit(1 if failures else 0)

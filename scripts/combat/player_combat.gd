extends Node
## Ataques do jogador no combate com boss (docs/gameplay/BOSS_BROTINHO.md): com a espada
## ou o arco escolhidos na barra, [F]/clique ataca. Espada: golpe largo em arco à frente, o dano
## sai no quadro de contato. Arco: gasta 1 flecha e atira para onde o jogador olha.
## Alvos: nós no grupo "boss_target" com take_hit(dano, origem) e hit_radius().
## shortcut: a espada usa a animação do machado e o arco nenhuma, até a arte nova.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const HEALTH := preload("res://scripts/systems/health_state.gd")
const SWORD_DAMAGE := 14
## Golpe largo como no Stardew (pedido do usuário, 2026-11-27): arco na frente, alcance
## até a borda do alvo; dá para acertar de longe e correr.
const SWORD_REACH := 110.0
const SWORD_ARC := deg_to_rad(140.0)
const ARROW_DAMAGE := 9
const ARROW_SPEED := 560.0
## Arco (teste do usuário, 2026-11-27): atira para onde o mouse aponta, com alcance
## limitado; a flecha cai no limite.
const BOW_RANGE := 380.0
const ARROW_RANGE := BOW_RANGE + 20.0
const BOW_COOLDOWN := 0.45

var player: CharacterBody2D
var _bow_cd := 0.0


func _ready() -> void:
	name = "PlayerCombat"


static func is_weapon(item: String) -> bool:
	return item in preload("res://scripts/systems/item_catalog.gd").WEAPONS


## Dano no jogador; rolando não pega. Devolve se acertou.
static func hurt_player(target: Node2D, amount: int) -> bool:
	if not is_instance_valid(target) or bool(target.get("invulnerable")): return false
	HEALTH.change(target.get_tree(), -amount)
	var sprite: CanvasItem = target.get("sprite")
	if sprite:
		sprite.modulate = Color(1.0, 0.45, 0.45, sprite.modulate.a)
		target.get_tree().create_timer(0.18).timeout.connect(func() -> void:
			if is_instance_valid(sprite): sprite.modulate = Color(1, 1, 1, sprite.modulate.a))
	return true


func _process(delta: float) -> void:
	_bow_cd = maxf(0.0, _bow_cd - delta)
	if not is_instance_valid(player) or not player.is_physics_processing(): return  # janela aberta
	var item: String = HOTBAR.selected_item(get_tree())
	if not is_weapon(item) or not Input.is_action_just_pressed("interact"): return
	if player.is_using_tool() or player.is_rolling(): return
	if item == "espada": swing()
	elif item == "arco": shoot()


func swing() -> void:
	var anim: float = player.play_tool("axe")
	var forward: Vector2 = player._facing_vector()
	var hit := func() -> void:
		_slash(forward)
		for target: Node2D in get_tree().get_nodes_in_group("boss_target"):
			if in_sword_arc(player.global_position, forward, target.global_position, float(target.call("hit_radius"))):
				target.call("take_hit", SWORD_DAMAGE, player.global_position)
	if anim > 0.0: player.tool_impact.connect(hit, CONNECT_ONE_SHOT)
	else: hit.call()


## Dentro do arco da espada: até SWORD_REACH da borda do alvo e no ângulo à frente.
static func in_sword_arc(from: Vector2, forward: Vector2, target: Vector2, target_radius: float) -> bool:
	var to_target := target - from
	if to_target.length() - target_radius > SWORD_REACH: return false
	if to_target.length() <= target_radius: return true  # colado no alvo
	return absf(forward.angle_to(to_target)) <= SWORD_ARC * 0.5


## Rastro do golpe (provisório, até a arte nova): meia-lua branca que some rápido.
func _slash(forward: Vector2) -> void:
	var trail := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 13:
		points.append(Vector2.from_angle(forward.angle() - SWORD_ARC * 0.5 + SWORD_ARC * i / 12.0) * SWORD_REACH * 0.9)
	for i in range(12, -1, -1):
		points.append(Vector2.from_angle(forward.angle() - SWORD_ARC * 0.5 + SWORD_ARC * i / 12.0) * SWORD_REACH * 0.55)
	trail.polygon = points
	trail.color = Color(1, 1, 1, 0.55)
	trail.scale = Vector2(1.0, 0.75)  # chão em perspectiva
	trail.global_position = player.global_position + Vector2(0, -14)
	trail.z_index = 6
	player.get_parent().add_child(trail)
	var fade := trail.create_tween()
	fade.tween_property(trail, "modulate:a", 0.0, 0.18)
	fade.tween_callback(trail.queue_free)


## `at`: ponto no mundo para onde atirar (padrão: o mouse).
func shoot(at: Variant = null) -> bool:
	if _bow_cd > 0.0: return false
	if BAG.count_item(get_tree(), "flecha") <= 0:
		var region := player.get_parent()
		if region and region.has_method("say"): region.call("say", "no_arrows", "Sem flechas! Faço mais na bancada (graveto e pedrinha).")
		return false
	BAG.spend_item(get_tree(), "flecha", 1)
	_bow_cd = BOW_COOLDOWN
	var arrow := Arrow.new()
	var aim: Vector2 = at if at != null else player.get_global_mouse_position()
	arrow.direction = bow_aim(player.global_position + Vector2(0, -16), aim, player._facing_vector())
	arrow.global_position = player.global_position + Vector2(0, -16) + arrow.direction * 18.0
	player.get_parent().add_child(arrow)
	return true


## Direção do tiro até o ponto mirado; mouse em cima do jogador: para a frente.
static func bow_aim(from: Vector2, at: Vector2, forward: Vector2) -> Vector2:
	return forward if from.distance_to(at) < 8.0 else (at - from).normalized()


## Flecha simples (linha desenhada) que acerta o primeiro alvo de boss no caminho.
class Arrow extends Node2D:
	var direction := Vector2.RIGHT
	var _travel := 0.0

	func _ready() -> void:
		z_index = 5
		rotation = direction.angle()

	func _process(delta: float) -> void:
		var step := ARROW_SPEED * delta
		global_position += direction * step
		_travel += step
		for target: Node2D in get_tree().get_nodes_in_group("boss_target"):
			if (target.global_position + Vector2(0, -20)).distance_to(global_position) <= float(target.call("hit_radius")):
				target.call("take_hit", ARROW_DAMAGE, global_position - direction * 40.0)
				queue_free()
				return
		if _travel > ARROW_RANGE: queue_free()

	func _draw() -> void:
		draw_line(Vector2(-14, 0), Vector2(8, 0), Color("#8a5a32"), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(12, 0), Vector2(6, -3), Vector2(6, 3)]), Color("#c8ccd4"))
		draw_line(Vector2(-14, 0), Vector2(-18, -3), Color.WHITE, 1.0)
		draw_line(Vector2(-14, 0), Vector2(-18, 3), Color.WHITE, 1.0)

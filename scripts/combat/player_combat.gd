extends Node
## Ataques do jogador no combate com boss (docs/gameplay/BOSS_BROTINHO.md): com a espada
## ou o arco escolhidos na barra, [F]/clique ataca. Espada: golpe largo em arco à frente, o dano
## sai no quadro de contato. Arco: gasta 1 flecha e atira para onde o jogador olha.
## Alvos: nós no grupo "combat_target" (boss e slimes não amigos da Floresta) com
## take_hit(dano, origem) e hurt_rect() ou hit_radius().
## shortcut: a espada usa a animação do machado e o arco nenhuma, até a arte nova.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOTBAR := preload("res://scripts/systems/hotbar_state.gd")
const HEALTH := preload("res://scripts/systems/health_state.gd")
const GOD_KEY := "debug_infinite_health"  ## vida infinita nos testes de combate (admin "imortal")
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
## Ataque pedido no meio de outro golpe ou rolamento: sai assim que der (nada se perde).
## Fila curta (teste do usuário, 2026-11-27: um clique virava dois golpes e não dava para
## desviar). O mouse manda um 2º clique colado no 1º (clique duplo no mesmo quadro em
## que solta). Clique no meio do golpe só vale nos últimos QUEUE_WINDOW s dele; antes
## disso é ignorado, como no Stardew. Rolar cancela o que estava na fila.
const QUEUE_TIME := 0.3
const QUEUE_WINDOW := 0.15
var _queued := 0.0
var _aim := Vector2.INF  ## ponto mirado no último clique/[F] (mouse); INF = para a frente
var _mouse_screen := Vector2.INF  ## última posição do mouse na tela (eventos de movimento)


func _ready() -> void:
	name = "PlayerCombat"
	if is_instance_valid(player) and player.has_signal("rolled"):
		player.rolled.connect(func() -> void: _queued = 0.0)  # rolar cancela o ataque na fila


func _input(event: InputEvent) -> void:
	if event is InputEventMouse: _mouse_screen = (event as InputEventMouse).position


## Ponto do mundo sob o mouse agora (a câmera pode ter andado desde o último movimento).
func mouse_world() -> Vector2:
	if _mouse_screen == Vector2.INF: return Vector2.INF
	return get_viewport().get_canvas_transform().affine_inverse() * _mouse_screen


## Clique aceito agora? Livre, ou já no fim do golpe/recarga (fica na fila).
func _accepts_click(item: String) -> bool:
	if player.is_rolling(): return false
	if item == "arco" and _bow_cd > QUEUE_WINDOW: return false
	if player.is_using_tool() and float(player.get("_tool_time")) > QUEUE_WINDOW: return false
	return true


static func is_weapon(item: String) -> bool:
	return item in preload("res://scripts/systems/item_catalog.gd").WEAPONS


## Dano no jogador; rolando não pega. Devolve se acertou.
static func hurt_player(target: Node2D, amount: int) -> bool:
	if not is_instance_valid(target) or bool(target.get("invulnerable")): return false
	if not bool(target.get_tree().get_meta(GOD_KEY, false)): HEALTH.change(target.get_tree(), -amount)
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
	if not is_weapon(item):
		_queued = 0.0
		return
	if Input.is_action_just_pressed("roll"): _queued = 0.0  # quer desviar: nada de ataque na fila
	if Input.is_action_just_pressed("interact") and _accepts_click(item):
		_queued = QUEUE_TIME
		var clicked: Variant = player.get_parent().get("click_point")
		_aim = clicked if clicked is Vector2 and clicked != Vector2.INF else mouse_world()
	if _queued <= 0.0: return
	_queued -= delta
	if player.is_using_tool() or player.is_rolling(): return
	if item == "arco" and _bow_cd > 0.0: return
	_queued = 0.0
	if item == "espada": swing()
	elif item == "arco": shoot()


func swing() -> void:
	var anim: float = player.play_tool("axe")
	var forward: Vector2 = player._facing_vector()
	if _aim != Vector2.INF and _aim.distance_to(player.global_position) > 4.0:
		forward = (_aim - player.global_position).normalized()  # corta para onde o mouse mirou
	# O que estava ao alcance no clique conta também: o boss que se move durante a
	# preparação do golpe (salto) não escapa de um clique certo (teste 2026-11-27).
	var locked: Array[Node2D] = []
	for target: Node2D in get_tree().get_nodes_in_group("combat_target"):
		if in_sword_arc(player.global_position, forward, hurt_rect_of(target)): locked.append(target)
	var hit := func() -> void:
		_slash(forward)
		for target: Node2D in get_tree().get_nodes_in_group("combat_target"):
			if target in locked or in_sword_arc(player.global_position, forward, hurt_rect_of(target)):
				target.call("take_hit", SWORD_DAMAGE, player.global_position)
	if anim > 0.0: player.tool_impact.connect(hit, CONNECT_ONE_SHOT)
	else: hit.call()


## Área de acerto do alvo: o desenho (hurt_rect) ou, sem ele, um quadrado do raio.
static func hurt_rect_of(target: Node2D) -> Rect2:
	if target.has_method("hurt_rect"): return target.call("hurt_rect")
	var r := float(target.call("hit_radius"))
	return Rect2(target.global_position - Vector2(r, r * 2.0), Vector2(r * 2.0, r * 2.0))


## Dentro do arco da espada: o ponto mais perto do alvo está até SWORD_REACH e o alvo
## (ponto mais perto ou centro) está no ângulo à frente.
static func in_sword_arc(from: Vector2, forward: Vector2, rect: Rect2) -> bool:
	if rect.has_point(from): return true  # colado no alvo
	var closest := from.clamp(rect.position, rect.end)
	if from.distance_to(closest) > SWORD_REACH: return false
	var half := SWORD_ARC * 0.5
	return absf(forward.angle_to(closest - from)) <= half or absf(forward.angle_to(rect.get_center() - from)) <= half


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
	arrow.rect_of = hurt_rect_of
	arrow.origin = player.global_position + Vector2(0, -16)
	var aim: Vector2 = at if at != null else (_aim if _aim != Vector2.INF else mouse_world())
	if aim.distance_to(player.global_position) > 4.0: player.facing = player._get_direction_name(aim - player.global_position)
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
	var rect_of: Callable  # hurt_rect_of da classe de fora (classe interna não a vê)
	var origin := Vector2.INF  # mão do jogador: o 1º trecho vai dela até a flecha (queima-roupa)
	var _travel := 0.0

	func _ready() -> void:
		z_index = 5
		rotation = direction.angle()

	func _process(delta: float) -> void:
		var from := global_position if origin == Vector2.INF else origin
		origin = Vector2.INF
		var step := ARROW_SPEED * delta
		global_position += direction * step
		_travel += step
		for target: Node2D in get_tree().get_nodes_in_group("combat_target"):
			if _crosses((rect_of.call(target) as Rect2).grow(6.0), from, global_position):
				target.call("take_hit", ARROW_DAMAGE, global_position - direction * 40.0)
				queue_free()
				return
		if _travel > ARROW_RANGE: queue_free()

	## O trecho percorrido neste quadro passa pelo alvo (não só o ponto final).
	static func _crosses(rect: Rect2, a: Vector2, b: Vector2) -> bool:
		var steps := maxi(1, ceili(a.distance_to(b) / 4.0))
		for i in steps + 1:
			if rect.has_point(a.lerp(b, float(i) / steps)): return true
		return false

	func _draw() -> void:
		draw_line(Vector2(-14, 0), Vector2(8, 0), Color("#8a5a32"), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(12, 0), Vector2(6, -3), Vector2(6, 3)]), Color("#c8ccd4"))
		draw_line(Vector2(-14, 0), Vector2(-18, -3), Color.WHITE, 1.0)
		draw_line(Vector2(-14, 0), Vector2(-18, 3), Color.WHITE, 1.0)

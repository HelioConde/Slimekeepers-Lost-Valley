extends CharacterBody2D
## Shared peaceful creature: bounded visits, rest, environmental preferences and social pauses.
signal friendship_started(persistent_id: String)
const FRAMES: SpriteFrames = preload("res://assets/slimes/bestiary/brotinho/brotinho_frames.tres")
const SPECIES := preload("res://scripts/world/slime_species.gd")
const VARIANTS := preload("res://scripts/systems/slime_variants.gd")
static var HEART: Texture2D = preload("res://scripts/ui/hud_skin.gd").heart(true)
static var NOTICE: Texture2D = _notice_icon()
const WALK_SPEED := 30.0
const ACTIVE_DISTANCE := 1000.0

var slime_type := "brotinho"
var persistent_id := ""
var befriended := false
var variant := "comum"  ## slime_variants.gd: comum, raro, arco_iris (fixa por identidade)
var habitat: Dictionary = {}
var personality: Dictionary = {}
var sprite: AnimatedSprite2D
var manager: Node2D
var player: Node2D
var behavior := "rest"
var energy := 0.75
var _rng := RandomNumberGenerator.new()
var _target := Vector2.ZERO
var _decision_time := 1.0
var _happy_time := 0.0
## Reação ao jogador enquanto feliz: "comer" (alimentado) ou "receber_carinho" (cumprimentado).
var reaction := ""
var _hop_time := 0.0
var _social_cooldown := 0.0
var _curiosity_cooldown := 0.0
var _threat_timer := 0.0
var _moving := false
var _social_partner: Node2D
var _session_key := "forest_slime_friends"
var swimming := false
## Combate antes do boss (forest_threat.gd, decisões do usuário 2026-11-27): slime não
## amigo toma golpes, morre soltando gosma e volta em 2 dias; agressivo, ataca quem chega
## perto com um pulo avisado (sem perseguir); a Bolhinha foge. Amigo é protegido.
const THREAT := preload("res://scripts/combat/forest_threat.gd")
const COMBAT := preload("res://scripts/combat/player_combat.gd")
const SLIME_HP := 30
const ATTACK_RANGE := 52.0  ## começa o pulo quando o jogador chega a esta distância
const LUNGE := 40.0  ## o pulo avança no máximo isto (não persegue)
const WINDUP := 0.45  ## aviso antes do pulo
const ATTACK_COOLDOWN := 1.6
const FLEE_RANGE := 120.0  ## Bolhinha foge de quem chega a esta distância
var hp := SLIME_HP
var is_pet := false  ## amigo que segue o jogador (slime_pet.gd move e cuida dele)
var _dead := false
var _attack_cd := 0.0
var _attacking := false
var _water_material: ShaderMaterial
var _swim_path := PackedVector2Array()

func configure(habitat_manager: Node2D, observed_player: Node2D, habitat_data: Dictionary, instance_id: String) -> void:
	manager = habitat_manager
	player = observed_player
	habitat = habitat_data
	persistent_id = instance_id
	slime_type = instance_id.get_slice("/", 0)
	variant = VARIANTS.of(instance_id)
	personality = SPECIES.definition(slime_type)
	_session_key = str(manager.session_key)
	_rng.seed = hash(persistent_id)
	_decision_time = _rng.randf_range(1.5, 4.0)
	_social_cooldown = _rng.randf_range(4.0, 10.0)
	energy = _rng.randf_range(0.6, 0.9)
	name = "%s_%s" % [personality.name, persistent_id.replace("/", "_")]

func _ready() -> void:
	add_to_group("living_slimes")
	collision_layer = 0
	collision_mask = 2
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 28.0
	collision.shape = capsule
	collision.position = Vector2(0, -10)
	add_child(collision)
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.sprite_frames = load(personality.frames) as SpriteFrames
	sprite.position = Vector2(0, -18)
	sprite.scale = Vector2.ONE * float(personality.scale)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	if slime_type == "bolhinha":
		for body in manager.water_bodies: add_collision_exception_with(body)
		_water_material = ShaderMaterial.new()
		_water_material.shader = preload("res://scripts/world/slime_swimming.gdshader")
		sprite.material = _water_material
	var friends: Dictionary = get_tree().get_meta(_session_key, {})
	befriended = bool(friends.get(persistent_id, false))
	if not befriended and not THREAT.area_of(_session_key).is_empty(): add_to_group("combat_target")
	_play_animation("idle")
	if variant != VARIANTS.COMMON: _add_variant_glow()

func _draw() -> void:
	if swimming:
		draw_set_transform(Vector2(0,1),0,Vector2(1,.3))
		draw_arc(Vector2.ZERO,17,0,TAU,24,Color(.71,.91,.87,.65),1)
		draw_arc(Vector2(0,4),21,.2,2.8,16,Color(.61,.83,.80,.36),1)
		draw_set_transform(Vector2.ZERO)
		return
	# A contact ellipse belongs to the ground; only its softness changes during a hop.
	var lift := maxf(0.0, -18.0 - sprite.position.y) if is_instance_valid(sprite) else 0.0
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 12.0 - lift * 0.5, Color(0.06, 0.11, 0.08, 0.18 - lift * 0.025))
	draw_set_transform(Vector2.ZERO)

## Raro: brilhos dourados; arco-íris: brilhos coloridos e o corpo trocando de tom bem de leve.
func _add_variant_glow() -> void:
	var sparks := CPUParticles2D.new()
	sparks.name = "VariantSparkles"
	sparks.amount = 6
	sparks.lifetime = 1.4
	sparks.position = Vector2(0, -18)
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 14.0
	sparks.gravity = Vector2(0, -10)
	sparks.initial_velocity_min = 2.0
	sparks.initial_velocity_max = 6.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 1.0
	sparks.texture = _star_texture()
	var ramp := Gradient.new()
	if variant == VARIANTS.RARE:
		ramp.colors = PackedColorArray([Color(1, 0.95, 0.6, 0), Color(1, 0.85, 0.3, 1), Color(1, 0.95, 0.6, 0)])
	else:
		ramp.colors = PackedColorArray([Color(1, 0.4, 0.5, 0), Color(0.5, 1, 0.6, 1), Color(0.5, 0.6, 1, 0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	sparks.color_ramp = ramp
	sparks.z_index = 2
	add_child(sparks)


## Estrelinha de pixel 5x5 (cruz com centro claro) para os brilhos da variante.
static func _star_texture() -> ImageTexture:
	var image := Image.create(5, 5, false, Image.FORMAT_RGBA8)
	for i in 5:
		image.set_pixel(2, i, Color(1, 1, 1, 0.75))
		image.set_pixel(i, 2, Color(1, 1, 1, 0.75))
	image.set_pixel(2, 2, Color.WHITE)
	return ImageTexture.create_from_image(image)


var _request_wait := 0.0
## Pedido do dia (slime_requests.gd): balãozinho com a comida por cima, só para amigos e
## com o jogador perto.
func _update_request_bubble(delta: float) -> void:
	_request_wait -= delta
	if _request_wait > 0.0: return
	_request_wait = 0.5
	var want := ""
	if befriended and is_instance_valid(player) and player.global_position.distance_to(global_position) < 240.0:
		want = preload("res://scripts/systems/slime_requests.gd").wanted(get_tree(), persistent_id, slime_type, GameClock.day_number)
	var bubble := get_node_or_null("RequestBubble") as Sprite2D
	if want.is_empty():
		if bubble: bubble.queue_free()
		return
	if bubble == null:
		bubble = Sprite2D.new()
		bubble.name = "RequestBubble"
		bubble.texture = _bubble_texture()
		bubble.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bubble.position = Vector2(0, -50)
		bubble.z_index = 5
		var icon := Sprite2D.new()
		icon.name = "Icon"
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.scale = Vector2(0.5, 0.5)
		icon.position = Vector2(0, -1)
		bubble.add_child(icon)
		add_child(bubble)
	(bubble.get_node("Icon") as Sprite2D).texture = preload("res://scripts/systems/item_catalog.gd").icon(want)


## Balão de fala branco 20x18 com rabinho (desenhado em pixel).
static func _bubble_texture() -> ImageTexture:
	var image := Image.create(20, 19, false, Image.FORMAT_RGBA8)
	var ink := Color("#3d2a1e")
	var paper := Color("#fffaf0")
	for y in 16:
		for x in 20:
			var corner := (x < 2 or x > 17) and (y < 2 or y > 13)
			if corner: continue
			var edge := x == 0 or x == 19 or y == 0 or y == 15 or ((x == 1 or x == 18) and (y == 1 or y == 14))
			image.set_pixel(x, y, ink if edge else paper)
	for i in 3:  # rabinho
		for x in range(9 - (2 - i), 11 + (2 - i) - 1):
			image.set_pixel(x, 15 + i, paper if i < 2 else ink)
		image.set_pixel(9 - (2 - i), 15 + i, ink)
		image.set_pixel(10 + (2 - i), 15 + i, ink)
	return ImageTexture.create_from_image(image)


func _process(delta: float) -> void:
	_update_request_bubble(delta)
	if variant == VARIANTS.RAINBOW and is_instance_valid(sprite):
		var hue := fmod(Time.get_ticks_msec() / 4000.0, 1.0)
		sprite.self_modulate = Color.WHITE.lerp(Color.from_hsv(hue, 0.7, 1.0), 0.35)


## Interação com o jogador: toca a reação (sprite novo do Brotinho tem "comer" e
## "receber_carinho"; quem não tem usa "happy").
func react(kind: String) -> void:
	reaction = kind
	_happy_time = 2.4
	if not is_instance_valid(sprite): return
	# Para, olha para quem interagiu, se espreme de alegria e solta um coração.
	if behavior not in ["sleep", "flee"]: _rest(2.4)
	if is_instance_valid(player):
		sprite.flip_h = player.global_position.x < global_position.x
		if player.has_method("face"): player.face(global_position)  # os dois se olham
	if sprite.sprite_frames.has_animation(kind): sprite.play(kind)
	if kind in ["receber_carinho", "comer"]:
		preload("res://scripts/systems/sfx.gd").play(get_tree(), "coracao", global_position)
		_squash()
		_float_heart(Vector2.ZERO, 0.0)
	else:
		_float_heart(Vector2.ZERO, 0.0, NOTICE)  # desconfiado: só olha, sem coração


## "!" de pixel no balão claro: o slime notou o jogador.
static func _notice_icon() -> ImageTexture:
	var rows := [".OOOOO.", "OOOXOOO", "OOOXOOO", "OOOXOOO", "OOOOOOO", "OOOXOOO", ".OOOOO.", "..OO...", "..O...."]
	var image := Image.create(7, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 7:
			var c: String = rows[y][x]
			if c == "X": image.set_pixel(x, y, Color("#5c1a1f"))
			elif c == "O": image.set_pixel(x, y, Color("#f3e2c8"))
	return ImageTexture.create_from_image(image)


func _squash() -> void:
	var base := Vector2.ONE * float(personality.get("scale", 1.0))
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base * Vector2(1.14, 0.86), 0.08)
	tween.tween_property(sprite, "scale", base * Vector2(0.92, 1.1), 0.1)
	tween.tween_property(sprite, "scale", base, 0.14)


## Coração de pixel (o mesmo do HUD do laço) que sobe e some sobre o slime.
func _float_heart(offset: Vector2, delay: float, icon: Texture2D = HEART) -> void:
	var heart := Sprite2D.new()
	heart.name = "ReactionHeart" if icon == HEART else "ReactionNotice"
	heart.texture = icon
	heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	heart.scale = Vector2(2, 2)
	heart.z_index = 5
	heart.position = Vector2(0, -46) + offset
	heart.modulate.a = 0.0
	add_child(heart, true)  # nomes legíveis: ReactionHeart, ReactionHeart2...
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(heart, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(heart, "position:y", heart.position.y - 16.0, 1.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "modulate:a", 0.0, 0.3)
	tween.tween_callback(heart.queue_free)


func display_name() -> String:
	var tag: String = VARIANTS.NAMES.get(variant, "")
	return str(personality.name) + ("" if tag.is_empty() else " " + tag)

func make_friend() -> bool:
	if befriended:
		return false
	befriended = true
	remove_from_group("combat_target")  # amigo: golpes passam sem acertar
	var friends: Dictionary = get_tree().get_meta(_session_key, {})
	friends[persistent_id] = true
	get_tree().set_meta(_session_key, friends)
	_happy_time = 2.4
	_rest(2.4)
	_play_animation("happy")
	if is_instance_valid(sprite):
		for i in 3: _float_heart(Vector2((i - 1) * 14, absi(i - 1) * 4), i * 0.15)  # amizade nova: três corações
		preload("res://scripts/systems/sfx.gd").play(get_tree(), "coracao", global_position)
	friendship_started.emit(persistent_id)
	return true

func _physics_process(delta: float) -> void:
	_update_swimming()
	if is_pet or _dead: return  # slime_pet.gd move o pet; morto só some
	_attack_cd = maxf(0.0, _attack_cd - delta)
	if _attacking: return
	if is_instance_valid(player) and _threat_step(): return
	_happy_time = maxf(0.0, _happy_time - delta)
	if _happy_time <= 0.0: reaction = ""
	if not is_instance_valid(player) or not is_instance_valid(manager):
		return
	if global_position.distance_squared_to(player.global_position) > ACTIVE_DISTANCE * ACTIVE_DISTANCE:
		_rest(maxf(_decision_time, 1.0))
		_idle_animation()
		return
	_social_cooldown = maxf(0.0, _social_cooldown - delta)
	_curiosity_cooldown = maxf(0.0, _curiosity_cooldown - delta)
	_decision_time -= delta
	_threat_timer -= delta
	energy = clampf(energy + delta * (0.025 if behavior in ["rest", "sleep"] else -0.009), 0.0, 1.0)
	if _happy_time > 0.0:
		_idle_animation()
		return
	if _threat_timer <= 0.0:
		_threat_timer = 0.35
		if behavior != "flee":
			_try_retreat()
	if behavior == "sleep" and str(manager.environmental_state.get("period", "day")) != "night" and energy > 0.3:
		_rest(1.5)
	if _decision_time <= 0.0:
		if behavior != "rest":
			_rest(_rng.randf_range(1.8, 4.0))
		else:
			_choose_behavior()
	if _moving:
		while not _swim_path.is_empty() and global_position.distance_to(_swim_path[0])<4: _swim_path.remove_at(0)
		if behavior == "social" and is_instance_valid(_social_partner):
			_target = _social_partner.global_position + _social_partner.global_position.direction_to(global_position) * 58.0
		if global_position.distance_to(_target) <= 6.0:
			_arrive()
		elif not move_toward_point(_swim_path[0] if not _swim_path.is_empty() else _target, delta):
			_rest(_rng.randf_range(2.0, 4.0))
	else:
		_idle_animation()

# --- Combate (antes do boss) -------------------------------------------------------

## Agressivo agora? Não amigo, Floresta sem boss vencido, fora do tutorial perto da casa
## e o jogador sem comida na mão.
func aggressive() -> bool:
	var area := THREAT.area_of(_session_key)
	if befriended or area.is_empty() or habitat.get("near_spawn", false): return false
	if THREAT.pacified(get_tree(), area): return false
	var held: String = preload("res://scripts/systems/hotbar_state.gd").selected_item(get_tree())
	return not preload("res://scripts/systems/slime_feeding.gd").is_food(held)


## Um passo do comportamento agressivo; true = cuidou do quadro.
func _threat_step() -> bool:
	if not aggressive(): return false
	var distance := global_position.distance_to(player.global_position)
	if slime_type == "bolhinha":
		if distance < FLEE_RANGE and behavior != "flee":
			var away := global_position + player.global_position.direction_to(global_position) * 90.0
			if manager.is_position_allowed(away, habitat, self): _begin_visit("flee", away, 2.5)
		return false
	if distance > ATTACK_RANGE or _attack_cd > 0.0: return false
	_attack(player.global_position)
	return true


## Pulo avisado: encolhe vermelho, salta até LUNGE na direção de onde o jogador estava e
## machuca se ele ainda estiver lá (rolar ou correr desvia).
func _attack(at: Vector2) -> void:
	_attacking = true
	_moving = false
	velocity = Vector2.ZERO
	sprite.flip_h = at.x < global_position.x
	var base_scale := sprite.scale
	var windup := create_tween()
	windup.tween_property(sprite, "scale", base_scale * Vector2(1.25, 0.75), WINDUP)
	windup.parallel().tween_property(sprite, "modulate", Color(1.4, 0.7, 0.7), WINDUP)
	await windup.finished
	if _dead or not is_instance_valid(player):
		_attacking = false
		return
	var landing := global_position + (at - global_position).limit_length(LUNGE)
	var jump := create_tween()
	jump.tween_property(sprite, "scale", base_scale * Vector2(0.85, 1.2), 0.08)
	jump.parallel().tween_property(self, "global_position", landing, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump.tween_property(sprite, "scale", base_scale, 0.1)
	jump.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.1)
	await get_tree().create_timer(0.18).timeout
	if not _dead and is_instance_valid(player) and player.global_position.distance_to(global_position) < 30.0:
		COMBAT.hurt_player(player, THREAT.SLIME_DAMAGE)
	_attack_cd = ATTACK_COOLDOWN
	_attacking = false
	_rest(0.8)


## Área de acerto = o desenho do slime.
func hurt_rect() -> Rect2:
	var size := Vector2(30, 28) * float(personality.get("scale", 1.0)) * 1.2
	return Rect2(sprite.global_position - size / 2.0, size)


func hit_radius() -> float:
	return 16.0


func take_hit(amount: int, from: Vector2) -> void:
	if befriended or _dead: return  # amigos são protegidos
	hp -= amount
	sprite.modulate = Color(1.8, 1.8, 1.8)
	get_tree().create_timer(0.08).timeout.connect(func() -> void: if is_instance_valid(sprite) and not _attacking: sprite.modulate = Color.WHITE)
	var push := (global_position - from).normalized() * 14.0
	if manager.is_position_allowed(global_position + push, habitat, self): global_position += push
	_rest(0.6)
	if hp <= 0: _die()


## Morre: conta o ponto, solta a gosma da espécie e some (o spawn o traz em 2 dias).
func _die() -> void:
	_dead = true
	remove_from_group("combat_target")
	var area := THREAT.area_of(_session_key)
	THREAT.record_kill(get_tree(), persistent_id, area)
	var region: Node = manager.get("region")
	var drops: Node = region.get("item_drops") if region else null
	var item := "gosma_" + slime_type
	if preload("res://scripts/systems/item_catalog.gd").ITEMS.has(item):
		if drops: drops.call("spawn", item, 1, global_position)
		else: preload("res://scripts/systems/forest_bag.gd").add_item(get_tree(), item, 1)
	if region and region.has_method("_notify"):
		var points := THREAT.points(get_tree(), area)
		region.call("_notify", "%s derrotado. Magia no %s: %d/%d." % [display_name(), THREAT.AREAS[area].spot, mini(points, THREAT.UNLOCK_POINTS), THREAT.UNLOCK_POINTS] if points < THREAT.UNLOCK_POINTS + THREAT.KILL_POINTS else "%s derrotado." % display_name())
	var fade := create_tween()
	fade.tween_property(sprite, "scale", sprite.scale * Vector2(1.4, 0.2), 0.25)
	fade.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	fade.tween_callback(queue_free)


func _try_retreat() -> bool:
	var player_velocity := Vector2.ZERO
	if player is CharacterBody2D:
		player_velocity = (player as CharacterBody2D).velocity
	var trigger_distance := 110.0 + float(personality.shyness) * 60.0
	if global_position.distance_to(player.global_position) < trigger_distance and player_velocity.length() > 175.0 and player_velocity.dot(global_position - player.global_position) > 0.0:
		var retreat := global_position + player.global_position.direction_to(global_position) * 72.0
		if manager.is_position_allowed(retreat, habitat, self):
			_begin_visit("flee", retreat, 3.0)
		else:
			_rest(2.0)
		return true
	return false

func _choose_behavior() -> void:
	if _try_retreat():
		return
	if str(manager.environmental_state.get("period", "day")) == "night" or energy < 0.23:
		behavior = "sleep"
		_moving = false
		_decision_time = _rng.randf_range(8.0, 13.0)
		return
	if slime_type == "bolhinha" and not manager.water_bodies.is_empty():
		var points: Array = habitat.get("water_points",[])
		if not points.is_empty():
			var target: Vector2 = points[_rng.randi_range(0,points.size()-1)]
			if swimming and _rng.randf() < .25: target = habitat.center
			if manager.is_position_allowed(target,habitat,self):
				_begin_visit("swim",target,global_position.distance_to(target)/WALK_SPEED+4)
				return
	if global_position.distance_to(player.global_position) < 150.0 + float(personality.curiosity) * 80.0 and _curiosity_cooldown <= 0.0:
		behavior = "curious"
		_moving = false
		_decision_time = _rng.randf_range(2.0, 3.5)
		_curiosity_cooldown = 9.0
		sprite.flip_h = player.global_position.x < global_position.x
		_squash()
		_float_heart(Vector2.ZERO, 0.0, NOTICE)  # notou o jogador
		return
	if _social_cooldown <= 0.0 and _rng.randf() < float(personality.sociability) and try_social_interaction():
		return
	if _rng.randf() < 0.35 + (1.0 - float(personality.energy)) * 0.2:
		_rest(_rng.randf_range(3.0, 6.0))
		return
	var point_key := "flower_points"
	if personality.preference == "shade":
		point_key = "shade_points" if not habitat.get("shade_points", []).is_empty() else "mushroom_points"
	elif personality.preference == "water":
		point_key = "water_points"
	var points: Array = habitat.get(point_key, [])
	if not points.is_empty():
		var start := _rng.randi_range(0, points.size() - 1)
		for index in points.size():
			var point: Vector2 = points[(start + index) % points.size()]
			if manager.is_position_allowed(point, habitat, self):
				_begin_visit("splash" if personality.preference == "water" else "plants", point, 7.0)
				return
	# A short return toward the habitat's quiet center gives exploration a destination.
	var center: Vector2 = habitat.get("center", global_position)
	var candidate := center + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * _rng.randf_range(20.0, 90.0)
	candidate = global_position.move_toward(candidate, 105.0)
	if manager.is_position_allowed(candidate, habitat, self):
		_begin_visit("explore", candidate, 4.0)
	else:
		_rest(3.0)

func try_social_interaction() -> bool:
	if _social_cooldown > 0.0 or behavior in ["sleep", "flee", "play", "social"]:
		return false
	for other in manager.spawned:
		if not is_instance_valid(other) or other == self or other.habitat.get("id") != habitat.get("id"):
			continue
		if other._social_cooldown > 0.0 or other.behavior not in ["rest", "curious"] or other._happy_time > 0.0:
			continue
		if global_position.distance_to(other.global_position) > 220.0:
			continue
		var candidate: Vector2 = other.global_position + other.global_position.direction_to(global_position) * 58.0
		if not manager.is_position_allowed(candidate, habitat, self):
			continue
		_social_partner = other
		other._social_partner = self
		_social_cooldown = _rng.randf_range(17.0, 25.0)
		other._social_cooldown = _social_cooldown
		other.behavior = "curious"
		other._moving = false
		other._decision_time = 6.0
		_begin_visit("social", candidate, 6.0)
		return true
	return false

func _begin_visit(action: String, point: Vector2, duration: float) -> void:
	_swim_path = PackedVector2Array()
	if action == "swim":
		_swim_path = manager.swimming_route(global_position,point,habitat,self)
		if _swim_path.is_empty():
			_rest(2)
			return
		var distance := global_position.distance_to(_swim_path[0])
		for i in range(1,_swim_path.size()): distance += _swim_path[i-1].distance_to(_swim_path[i])
		duration = distance/WALK_SPEED+4
	behavior = action
	_target = point
	_moving = true
	_decision_time = duration

func _arrive() -> void:
	_moving = false
	velocity = Vector2.ZERO
	if behavior == "social" and is_instance_valid(_social_partner) and _social_partner.behavior == "curious":
		behavior = "play"
		_social_partner.behavior = "play"
		_social_partner._moving = false
		_social_partner._decision_time = 2.4
		_social_partner._hop_time = 0.0
		_decision_time = 2.4
		_hop_time = 0.0
		if is_instance_valid(sprite) and is_instance_valid(_social_partner.sprite):
			sprite.flip_h = _social_partner.global_position.x < global_position.x  # um olha para o outro
			_social_partner.sprite.flip_h = not sprite.flip_h
			_squash()
			_social_partner._squash()
			_float_heart(Vector2.ZERO, 0.2)
	elif behavior in ["plants", "splash", "swim"]:
		if behavior == "swim": behavior = "splash" if swimming else "rest"
		_decision_time = _rng.randf_range(2.0, 3.5)
	else:
		_rest(_rng.randf_range(2.0, 4.0))
	_idle_animation()

func _rest(duration: float) -> void:
	_swim_path = PackedVector2Array()
	behavior = "rest"
	_moving = false
	velocity = Vector2.ZERO
	_decision_time = duration

func move_toward_point(target: Vector2, delta: float) -> bool:
	var direction := global_position.direction_to(target)
	var step := direction * minf(WALK_SPEED * delta, global_position.distance_to(target))
	if not manager.is_position_allowed(global_position + step, habitat, self):
		velocity = Vector2.ZERO
		return false
	velocity = direction * WALK_SPEED
	var hit := move_and_collide(step)
	_update_swimming()
	sprite.flip_h = direction.x < 0.0
	_play_animation("idle" if swimming else "move")
	_hop_time += delta
	sprite.position.y = -14.0 + sin(_hop_time*3.0) if swimming else -18.0 - absf(sin(_hop_time * 7.0)) * 2.0
	queue_redraw()
	return hit == null

func _idle_animation() -> void:
	velocity = Vector2.ZERO
	var waterline := -14.0 if swimming else -18.0
	if sprite.position.y != waterline:
		sprite.position.y = waterline
		queue_redraw()
	var animation := "idle"
	if _happy_time > 0.0:
		animation = reaction if not reaction.is_empty() and sprite.sprite_frames.has_animation(reaction) else "happy"
	elif behavior == "sleep":
		animation = "sleep"
	elif behavior == "curious":
		animation = "curious"
	elif behavior == "plants":
		animation = "plant"
	elif behavior in ["play", "splash"]:
		animation = behavior
	_play_animation(animation)

func _update_swimming() -> void:
	if slime_type != "bolhinha" or not is_instance_valid(manager): return
	var wet: bool = manager.is_water(global_position)
	if wet != swimming:
		swimming = wet
		if _water_material: _water_material.set_shader_parameter("swimming",wet)
		queue_redraw()

func _play_animation(requested: String) -> void:
	var aliases := {"curious": "blink", "plant": "procurar_terreno", "play": "comemorar", "splash": "happy"}
	var animation := requested
	if not sprite.sprite_frames.has_animation(animation):
		animation = str(aliases.get(requested, "idle"))
	if not sprite.sprite_frames.has_animation(animation):
		animation = "idle"
	if sprite.animation != StringName(animation) or not sprite.is_playing():
		sprite.play(animation)

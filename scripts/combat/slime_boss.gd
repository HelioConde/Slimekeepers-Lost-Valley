extends Node2D
## Boss Slime (docs/gameplay/BOSS_BROTINHO.md): um slime com magia demais, ~3x maior que
## o normal (sem braços nem pernas). Todo golpe é avisado: área marcada no chão e pose de
## carga; rolar (Espaço) desvia. Rolamento perfeito (logo antes do impacto) abre o boss
## por STAGGER_TIME com dano dobrado. Na metade da vida entra na fase 2 (avisos curtos
## e combinações). shortcut: arte do slime normal ampliada até a arte nova (PixelLab).

signal defeated
signal hp_changed(hp: int, max_hp: int)

const SPECIES := preload("res://scripts/world/slime_species.gd")
const COMBAT := preload("res://scripts/combat/player_combat.gd")
const SIZE := 3.0
const MAX_HP := 300
const DUO_HP := 1.6  ## em dupla, mais vida (decisão do usuário)
const BODY_RADIUS := 46.0
const MOVE_SPEED := 46.0
const STAGGER_TIME := 2.0
const SLOW_FACTOR := 0.4
const PERFECT_WINDOW := 0.26  ## s antes do impacto em que o rolamento conta como perfeito
## [aviso fase 1, aviso fase 2, dano]. Teste do usuário (2026-11-27): avisos mais longos
## e o dano só cai depois que a zona some (LAND_DELAY), trazido por um projétil.
const ROOTS := [1.2, 0.85, 14]
const SLAM := [1.5, 1.1, 22]
const LAND_DELAY := 0.15  ## s entre a zona sumir e o projétil cair
const SEEDS := [0.75, 0.5, 10]
const ROOT_RADIUS := 36.0
const SLAM_RADIUS := 78.0
const SEED_SPEED := 230.0
const SEED_RADIUS := 11.0

var species := "brotinho"
var display_name := "Brotinho Gigante"
var player: Node2D
var arena_center := Vector2.ZERO
var arena_radius := 260.0
var max_hp := MAX_HP
var hp := MAX_HP
var phase := 1
var staggered := 0.0
var sprite: AnimatedSprite2D
var _warnings: Array = []  # {at, radius, time, total, color}
var _bursts: Array = []  # {at, radius, time}
var _seeds: Array = []  # {at, vel, life}
var _lobs: Array = []  # {from, to, time, total, height, color}: projéteis em arco
var _busy := false
var slowed := 0.0  ## s de lentidão (pet Musguinho): anda e salta mais devagar
var _dead := false
var _rest := 1.4
var _base_scale := Vector2.ONE
var _art_rect := Rect2(-16, -16, 32, 32)
## Ordem de desenho (teste do usuário, 2026-11-27: o jogador perto ficava atrás do boss):
## o boss entra no y-sort da região com a origem no pé; o chão (avisos) vai para uma
## camada de chão e o que voa (projéteis) para uma camada acima de tudo.
var _sprite_y := -20.0
var _ground: Node2D
var _air: Node2D  # parte desenhada do quadro, em pixels, a partir do centro


## hp_factor: dificuldade pela mistura de mortes e amizades (forest_threat.gd).
func configure(target: Node2D, center: Vector2, radius: float, boss_species: String, duo: bool, hp_factor := 1.0) -> void:
	player = target
	arena_center = center
	arena_radius = radius
	species = boss_species
	display_name = "Musguinho Gigante" if species == "musguinho" else "Brotinho Gigante"
	max_hp = int(MAX_HP * (DUO_HP if duo else 1.0) * hp_factor)
	hp = max_hp


func _ready() -> void:
	add_to_group("boss_target")
	add_to_group("combat_target")
	_ground = preload("res://scripts/combat/ground_layer.gd").new()
	_ground.painter = _draw_ground
	get_parent().add_child.call_deferred(_ground)
	_air = Node2D.new()
	_air.z_index = 10
	_air.draw.connect(_draw_air)
	add_child(_air)
	var info: Dictionary = SPECIES.definition(species)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load(str(info.frames))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_base_scale = Vector2.ONE * float(info.get("scale", 1.0)) * SIZE
	sprite.scale = _base_scale * 0.2
	sprite.position = Vector2(0, -20)
	add_child(sprite)
	var frame := sprite.sprite_frames.get_frame_texture(sprite.sprite_frames.get_animation_names()[0], 0)
	if frame:
		var used := frame.get_image().get_used_rect()
		_art_rect = Rect2(Vector2(used.position) - frame.get_size() / 2.0, used.size)
	_sprite_y = -_art_rect.end.y * _base_scale.y  # base do desenho no pé (origem)
	sprite.position = Vector2(0, _sprite_y)
	sprite.play("idle" if sprite.sprite_frames.has_animation("idle") else sprite.sprite_frames.get_animation_names()[0])
	_busy = true  # entrada: cresce com um tremor antes de começar
	var grow := create_tween()
	grow.tween_property(sprite, "scale", _base_scale, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	grow.tween_callback(func() -> void: _busy = false)
	hp_changed.emit(hp, max_hp)


## Lentidão do pet Musguinho: o boss anda mais devagar e os golpes demoram mais.
func slow(seconds: float) -> void:
	slowed = maxf(slowed, seconds)
	sprite.modulate = Color(0.75, 0.9, 0.7)
	get_tree().create_timer(seconds).timeout.connect(func() -> void: if is_instance_valid(sprite) and slowed <= 0.05: sprite.modulate = Color.WHITE)


func hit_radius() -> float:
	return BODY_RADIUS


## Área de acerto = o desenho do boss na tela (folha e bordas contam), não só o centro.
## Teste do usuário (2026-11-27): clicar em partes do boss não acertava.
func hurt_rect() -> Rect2:
	var size := _art_rect.size * sprite.scale.abs()
	var offset := _art_rect.position * sprite.scale.abs()
	return Rect2(sprite.global_position + offset, size)


func take_hit(amount: int, from: Vector2) -> void:
	if _dead: return
	var dealt := amount * (2 if staggered > 0.0 else 1)
	hp = maxi(0, hp - dealt)
	hp_changed.emit(hp, max_hp)
	_damage_number(dealt, staggered > 0.0)
	sprite.modulate = Color(1.8, 1.8, 1.8)
	get_tree().create_timer(0.08).timeout.connect(func() -> void: if is_instance_valid(sprite): sprite.modulate = Color.WHITE)
	position += (global_position - from).normalized() * (6.0 if staggered > 0.0 else 2.0)  # tranco
	if phase == 1 and hp <= max_hp / 2:
		phase = 2
		_say("A magia transborda! Os golpes ficam mais rápidos.")
	if hp == 0: _die()


## Número de dano que sobe e some (como no Stardew): todo acerto se vê na hora.
func _damage_number(amount: int, critical: bool) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_override("font", preload("res://assets/fonts/ui_font.tres"))
	label.add_theme_font_size_override("font_size", 22 if critical else 16)
	label.add_theme_color_override("font_color", Color("#ffd23f") if critical else Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color("#2a1a14"))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	var rect := hurt_rect()
	label.position = to_local(Vector2(rect.get_center().x + randf_range(-18, 18), rect.position.y)) - Vector2(12, 10)
	add_child(label)
	var rise := label.create_tween()
	rise.set_parallel()
	rise.tween_property(label, "position:y", label.position.y - 34.0, 0.6).set_ease(Tween.EASE_OUT)
	rise.tween_property(label, "modulate:a", 0.0, 0.25).set_delay(0.4)
	rise.chain().tween_callback(label.queue_free)


func _process(delta: float) -> void:
	_tick_effects(delta)
	_air.queue_redraw()
	if _dead or not is_instance_valid(player): return
	if staggered > 0.0:
		staggered -= delta
		sprite.rotation = sin(Time.get_ticks_msec() * 0.03) * 0.12  # zonzo
		if staggered <= 0.0: sprite.rotation = 0.0
		return
	if _busy: return
	_rest -= delta
	var to_player: Vector2 = player.global_position - global_position
	slowed = maxf(0.0, slowed - delta)
	if to_player.length() > 90.0:
		position += to_player.normalized() * MOVE_SPEED * (SLOW_FACTOR if slowed > 0.0 else 1.0) * delta
		sprite.flip_h = to_player.x < 0.0
	if _rest > 0.0: return
	_busy = true
	var attacks := ["roots", "slam", "seeds"]
	var pick: String = attacks.pick_random()
	match pick:
		"roots": _roots()
		"slam": _slam()
		"seeds": _seeds_attack()


func _t(table: Array) -> float:
	return float(table[0] if phase == 1 else table[1]) * (1.0 / SLOW_FACTOR * 0.5 if slowed > 0.0 else 1.0)


## Raízes: três círculos sob o jogador, um depois do outro.
func _roots() -> void:
	var count := 3 if phase == 1 else 5
	for i in count:
		if _dead: return
		var at: Vector2 = player.global_position
		_lob(at, _t(ROOTS) + LAND_DELAY, 90.0, Color("#7a5230"))  # semente que vira raiz
		await _warn(at, ROOT_RADIUS, _t(ROOTS), Color(0.85, 0.3, 0.15))
		await get_tree().create_timer(LAND_DELAY).timeout
		if _dead: return
		_impact(at, ROOT_RADIUS, int(ROOTS[2]), Color(0.45, 0.32, 0.18))
		await get_tree().create_timer(0.15).timeout
	_finish(1.1)


## Pancada: carrega, pula onde o jogador estava (a sombra avisa) e cai.
func _slam() -> void:
	var target: Vector2 = player.global_position
	await _squash(0.45)
	if _dead: return
	var flight := _t(SLAM) + LAND_DELAY  # o próprio boss é o projétil: salta e cai
	var jump := create_tween()
	jump.tween_property(self, "position", position + (target - global_position), flight)
	var arc := create_tween()
	arc.tween_property(sprite, "position:y", _sprite_y - 150.0, flight * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arc.tween_property(sprite, "position:y", _sprite_y, flight * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _warn(target, SLAM_RADIUS, _t(SLAM), Color(0.25, 0.2, 0.2))
	await arc.finished
	if _dead: return
	_impact(target, SLAM_RADIUS, int(SLAM[2]), Color(0.55, 0.45, 0.3))
	_shake(9.0)
	_finish(1.3)


## Chuva de sementes: carrega e solta em leque (fase 2: duas ondas).
func _seeds_attack() -> void:
	for wave in (1 if phase == 1 else 2):
		await _squash(_t(SEEDS))
		if _dead: return
		var count := 10 if phase == 1 else 14
		for i in count:
			var angle := TAU * i / count + wave * 0.2
			_seeds.append({"at": global_position + Vector2(0, -20), "vel": Vector2.from_angle(angle) * SEED_SPEED, "life": 2.6})
	_finish(1.2)


func _finish(rest: float) -> void:
	_rest = rest * (0.75 if phase == 2 else 1.0)
	_busy = false


func _squash(seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale", _base_scale * Vector2(1.18, 0.82), seconds * 0.8)
	tween.tween_property(sprite, "scale", _base_scale, seconds * 0.2)
	await tween.finished


## Projétil em arco do boss até `to`, chegando em `seconds` (desenho; o dano é do golpe).
func _lob(to: Vector2, seconds: float, height: float, color: Color) -> void:
	_lobs.append({"from": global_position, "to": to, "time": seconds, "total": seconds, "height": height, "color": color})


func _warn(at: Vector2, radius: float, seconds: float, color: Color) -> void:
	_warnings.append({"at": at, "radius": radius, "time": seconds, "total": seconds, "color": color})
	await get_tree().create_timer(seconds).timeout


## Impacto: acerta se o jogador estiver na área e não estiver rolando; rolamento logo
## antes do impacto é perfeito e deixa o boss zonzo.
func _impact(at: Vector2, radius: float, damage: int, color: Color) -> void:
	_bursts.append({"at": at, "radius": radius, "time": 0.3, "color": color})
	for pet: Node in get_tree().get_nodes_in_group("boss_pet"):  # o pet também apanha
		if (pet.call("body") as Node2D).global_position.distance_to(at) <= radius: pet.call("take_boss_hit", damage)
	if not is_instance_valid(player) or player.global_position.distance_to(at) > radius: return
	if player.is_rolling() and (Time.get_ticks_msec() - float(player.rolling_since)) / 1000.0 <= PERFECT_WINDOW:
		staggered = STAGGER_TIME
		_say("Perfeito! O %s ficou zonzo." % display_name)
		return
	COMBAT.hurt_player(player, damage)


func _tick_effects(delta: float) -> void:
	for w in _warnings: w.time -= delta
	_warnings = _warnings.filter(func(w) -> bool: return w.time > 0.0)
	for l in _lobs: l.time -= delta
	_lobs = _lobs.filter(func(l) -> bool: return l.time > 0.0)
	for b in _bursts: b.time -= delta
	_bursts = _bursts.filter(func(b) -> bool: return b.time > 0.0)
	for s in _seeds:
		s.at += s.vel * delta
		s.life -= delta
		if is_instance_valid(player) and s.life > 0.0 and (s.at as Vector2).distance_to(player.global_position + Vector2(0, -12)) < SEED_RADIUS + 10.0:
			if COMBAT.hurt_player(player, int(SEEDS[2])): s.life = 0.0
		for pet: Node in get_tree().get_nodes_in_group("boss_pet"):
			if s.life > 0.0 and (s.at as Vector2).distance_to((pet.call("body") as Node2D).global_position + Vector2(0, -12)) < SEED_RADIUS + 10.0:
				pet.call("take_boss_hit", int(SEEDS[2]))
				s.life = 0.0
		if (s.at as Vector2).distance_to(arena_center) > arena_radius + 40.0: s.life = 0.0
	_seeds = _seeds.filter(func(s) -> bool: return s.life > 0.0)


## Chão: avisos, impactos e sombras dos projéteis (camada de chão, sob o jogador).
func _draw_ground(layer: Node2D) -> void:
	for w in _warnings:  # aviso: círculo que enche até o impacto
		var fill: float = 1.0 - w.time / w.total
		layer.draw_set_transform(layer.to_local(w.at), 0.0, Vector2(1.0, 0.55))
		layer.draw_circle(Vector2.ZERO, w.radius, Color(w.color, 0.18))
		layer.draw_circle(Vector2.ZERO, w.radius * fill, Color(w.color, 0.32))
		layer.draw_arc(Vector2.ZERO, w.radius, 0.0, TAU, 40, Color(w.color, 0.9), 2.0)
	for b in _bursts:
		layer.draw_set_transform(layer.to_local(b.at), 0.0, Vector2(1.0, 0.55))
		layer.draw_circle(Vector2.ZERO, b.radius * (1.2 - b.time), Color(b.color, b.time * 2.0))
	for l in _lobs:
		var k: float = 1.0 - l.time / l.total
		layer.draw_set_transform(layer.to_local((l.from as Vector2).lerp(l.to, k)), 0.0, Vector2(1.0, 0.5))
		layer.draw_circle(Vector2.ZERO, 5.0 + 4.0 * k, Color(0, 0, 0, 0.3))
	if is_instance_valid(sprite) and not _dead:  # sombra do boss (some ao saltar)
		var lift := clampf((_sprite_y - sprite.position.y) / 150.0, 0.0, 1.0)
		layer.draw_set_transform(layer.to_local(global_position), 0.0, Vector2(1.0, 0.4))
		layer.draw_circle(Vector2.ZERO, _art_rect.size.x * _base_scale.x * 0.45 * (1.0 - lift * 0.4), Color(0, 0, 0, 0.25 - lift * 0.1))
	layer.draw_set_transform(Vector2.ZERO)


## Ar: projéteis em voo (acima de tudo).
func _draw_air() -> void:
	for l in _lobs:
		var k: float = 1.0 - l.time / l.total
		var air: Vector2 = _air.to_local((l.from as Vector2).lerp(l.to, k)) + Vector2(0, -sin(k * PI) * float(l.height))
		_air.draw_circle(air, 7.0, l.color)
		_air.draw_circle(air + Vector2(-2, -2), 2.5, Color("#d8f5b0"))
	for s in _seeds:
		_air.draw_circle(_air.to_local(s.at), 6.0, Color("#6fbf4a") if species == "brotinho" else Color("#7d9a6a"))
		_air.draw_circle(_air.to_local(s.at), 3.0, Color("#d8f5b0"))


func _die() -> void:
	_dead = true
	remove_from_group("combat_target")
	_warnings.clear()
	_seeds.clear()
	_lobs.clear()
	if is_instance_valid(_ground): _ground.queue_free()
	var shrink := create_tween()  # a magia sai e ele volta ao tamanho normal
	shrink.tween_property(sprite, "modulate", Color(1.6, 2.0, 1.6), 0.4)
	shrink.tween_property(sprite, "scale", _base_scale / SIZE, 1.0).set_trans(Tween.TRANS_BACK)
	shrink.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	shrink.tween_callback(func() -> void: defeated.emit())


func _shake(strength: float) -> void:
	var camera: Camera2D = player.get_node_or_null("Camera2D") if is_instance_valid(player) else null
	if camera == null: return
	var tween := create_tween()
	for i in 6: tween.tween_property(camera, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength, 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)


func _say(text: String) -> void:
	var region := get_parent()
	if region and region.has_method("_notify"): region.call("_notify", text)

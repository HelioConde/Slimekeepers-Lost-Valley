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
const PERFECT_WINDOW := 0.26  ## s antes do impacto em que o rolamento conta como perfeito
## [aviso fase 1, aviso fase 2, dano]
const ROOTS := [0.85, 0.55, 14]
const SLAM := [1.1, 0.8, 22]
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
var _busy := false
var _dead := false
var _rest := 1.4
var _base_scale := Vector2.ONE


func configure(target: Node2D, center: Vector2, radius: float, boss_species: String, duo: bool) -> void:
	player = target
	arena_center = center
	arena_radius = radius
	species = boss_species
	display_name = "Musguinho Gigante" if species == "musguinho" else "Brotinho Gigante"
	max_hp = int(MAX_HP * (DUO_HP if duo else 1.0))
	hp = max_hp


func _ready() -> void:
	add_to_group("boss_target")
	z_index = 2
	var info: Dictionary = SPECIES.definition(species)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load(str(info.frames))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_base_scale = Vector2.ONE * float(info.get("scale", 1.0)) * SIZE
	sprite.scale = _base_scale * 0.2
	sprite.position = Vector2(0, -20)
	add_child(sprite)
	sprite.play("idle" if sprite.sprite_frames.has_animation("idle") else sprite.sprite_frames.get_animation_names()[0])
	_busy = true  # entrada: cresce com um tremor antes de começar
	var grow := create_tween()
	grow.tween_property(sprite, "scale", _base_scale, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	grow.tween_callback(func() -> void: _busy = false)
	hp_changed.emit(hp, max_hp)


func hit_radius() -> float:
	return BODY_RADIUS


func take_hit(amount: int, from: Vector2) -> void:
	if _dead: return
	var dealt := amount * (2 if staggered > 0.0 else 1)
	hp = maxi(0, hp - dealt)
	hp_changed.emit(hp, max_hp)
	sprite.modulate = Color(1.8, 1.8, 1.8)
	get_tree().create_timer(0.08).timeout.connect(func() -> void: if is_instance_valid(sprite): sprite.modulate = Color.WHITE)
	position += (global_position - from).normalized() * (6.0 if staggered > 0.0 else 2.0)  # tranco
	if phase == 1 and hp <= max_hp / 2:
		phase = 2
		_say("A magia transborda! Os golpes ficam mais rápidos.")
	if hp == 0: _die()


func _process(delta: float) -> void:
	_tick_effects(delta)
	queue_redraw()
	if _dead or not is_instance_valid(player): return
	if staggered > 0.0:
		staggered -= delta
		sprite.rotation = sin(Time.get_ticks_msec() * 0.03) * 0.12  # zonzo
		if staggered <= 0.0: sprite.rotation = 0.0
		return
	if _busy: return
	_rest -= delta
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > 90.0:
		position += to_player.normalized() * MOVE_SPEED * delta
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
	return float(table[0] if phase == 1 else table[1])


## Raízes: três círculos sob o jogador, um depois do outro.
func _roots() -> void:
	var count := 3 if phase == 1 else 5
	for i in count:
		if _dead: return
		var at: Vector2 = player.global_position
		await _warn(at, ROOT_RADIUS, _t(ROOTS), Color(0.85, 0.3, 0.15))
		_impact(at, ROOT_RADIUS, int(ROOTS[2]), Color(0.45, 0.32, 0.18))
		await get_tree().create_timer(0.15).timeout
	_finish(1.1)


## Pancada: carrega, pula onde o jogador estava (a sombra avisa) e cai.
func _slam() -> void:
	var target: Vector2 = player.global_position
	await _squash(0.45)
	if _dead: return
	var jump := create_tween()
	jump.tween_property(self, "position", position + (target - global_position), _t(SLAM)).set_trans(Tween.TRANS_SINE)
	await _warn(target, SLAM_RADIUS, _t(SLAM), Color(0.25, 0.2, 0.2))
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


func _warn(at: Vector2, radius: float, seconds: float, color: Color) -> void:
	_warnings.append({"at": at, "radius": radius, "time": seconds, "total": seconds, "color": color})
	await get_tree().create_timer(seconds).timeout


## Impacto: acerta se o jogador estiver na área e não estiver rolando; rolamento logo
## antes do impacto é perfeito e deixa o boss zonzo.
func _impact(at: Vector2, radius: float, damage: int, color: Color) -> void:
	_bursts.append({"at": at, "radius": radius, "time": 0.3, "color": color})
	if not is_instance_valid(player) or player.global_position.distance_to(at) > radius + 8.0: return
	if player.is_rolling() and (Time.get_ticks_msec() - float(player.rolling_since)) / 1000.0 <= PERFECT_WINDOW:
		staggered = STAGGER_TIME
		_say("Perfeito! O %s ficou zonzo." % display_name)
		return
	COMBAT.hurt_player(player, damage)


func _tick_effects(delta: float) -> void:
	for w in _warnings: w.time -= delta
	_warnings = _warnings.filter(func(w) -> bool: return w.time > 0.0)
	for b in _bursts: b.time -= delta
	_bursts = _bursts.filter(func(b) -> bool: return b.time > 0.0)
	for s in _seeds:
		s.at += s.vel * delta
		s.life -= delta
		if is_instance_valid(player) and s.life > 0.0 and (s.at as Vector2).distance_to(player.global_position + Vector2(0, -12)) < SEED_RADIUS + 10.0:
			if COMBAT.hurt_player(player, int(SEEDS[2])): s.life = 0.0
		if (s.at as Vector2).distance_to(arena_center) > arena_radius + 40.0: s.life = 0.0
	_seeds = _seeds.filter(func(s) -> bool: return s.life > 0.0)


func _draw() -> void:
	for w in _warnings:  # aviso: círculo que enche até o impacto
		var at: Vector2 = to_local(w.at)
		var fill: float = 1.0 - w.time / w.total
		draw_set_transform(at, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, w.radius, Color(w.color, 0.18))
		draw_circle(Vector2.ZERO, w.radius * fill, Color(w.color, 0.32))
		draw_arc(Vector2.ZERO, w.radius, 0.0, TAU, 40, Color(w.color, 0.9), 2.0)
		draw_set_transform(Vector2.ZERO)
	for b in _bursts:
		var at2: Vector2 = to_local(b.at)
		draw_set_transform(at2, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, b.radius * (1.2 - b.time), Color(b.color, b.time * 2.0))
		draw_set_transform(Vector2.ZERO)
	for s in _seeds:
		draw_circle(to_local(s.at), 6.0, Color("#6fbf4a") if species == "brotinho" else Color("#7d9a6a"))
		draw_circle(to_local(s.at), 3.0, Color("#d8f5b0"))


func _die() -> void:
	_dead = true
	_warnings.clear()
	_seeds.clear()
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

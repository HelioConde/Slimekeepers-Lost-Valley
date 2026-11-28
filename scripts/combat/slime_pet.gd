extends Node
## Pet (decisão do usuário, 2026-11-27): o slime amigo levado pelo disco ("Levar comigo")
## segue o jogador e ajuda na luta com o boss pela espécie:
## - Brotinho atira sementes no boss;
## - Bolhinha cura o jogador;
## - Musguinho deixa o boss lento por alguns segundos.
## Toma dano dos golpes do boss, aguenta mais que o jogador (PET_HP) e, se desmaiar,
## volta para casa e descansa até o dia seguinte (forest_threat.gd).
## Filho do próprio slime (forest_slime.gd com is_pet = true).

const THREAT := preload("res://scripts/combat/forest_threat.gd")
const HEALTH := preload("res://scripts/systems/health_state.gd")
const PET_HP := 150  ## jogador tem 100
const SPEED := 150.0
const FOLLOW_GAP := 46.0
const TELEPORT := 520.0
const STUCK_TIME := 1.0  ## longe demais (porta, rolamento longo): aparece ao lado
const SHOT_EVERY := 2.2  ## Brotinho
const SHOT_DAMAGE := 4
const SHOT_SPEED := 380.0
const HEAL_EVERY := 6.0  ## Bolhinha
const HEAL := 10
const SLOW_EVERY := 10.0  ## Musguinho
const SLOW_TIME := 3.0
const HELP_RANGE := 520.0  ## só ajuda com o boss por perto

var slime: CharacterBody2D
var player: Node2D
var hp := PET_HP
var _cooldown := 1.5
var _stuck := 0.0  ## s sem chegar perto (árvore, pedra no caminho)
var _last_gap := 0.0


func _ready() -> void:
	name = "SlimePet"
	slime = get_parent()
	player = slime.get("player")
	slime.set("is_pet", true)
	slime.remove_from_group("combat_target")
	add_to_group("boss_pet")


func _exit_tree() -> void:
	if is_instance_valid(slime): slime.set("is_pet", false)


func body() -> Node2D:
	return slime


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	_follow(delta)
	_help(delta)


func _follow(delta: float) -> void:
	var behind: Vector2 = -player.call("_facing_vector") if player.has_method("_facing_vector") else Vector2.DOWN
	var spot := player.global_position + behind * FOLLOW_GAP + Vector2(18, 0)
	var gap := slime.global_position.distance_to(spot)
	var sprite: AnimatedSprite2D = slime.get("sprite")
	if gap > TELEPORT:
		slime.global_position = spot
		return
	if gap < 10.0:
		slime.velocity = Vector2.ZERO
		slime.call("_play_animation", "idle")
		return
	var direction := slime.global_position.direction_to(spot)
	slime.velocity = direction * SPEED * (1.6 if gap > 160.0 else 1.0)
	slime.move_and_slide()  # desliza pela borda do obstáculo
	# Preso (não se aproxima) por mais de STUCK_TIME longe do jogador: aparece ao lado.
	_stuck = _stuck + delta if gap > 90.0 and gap >= _last_gap - 0.5 else 0.0
	_last_gap = gap
	if _stuck > STUCK_TIME:
		slime.global_position = spot
		_stuck = 0.0
	if sprite: sprite.flip_h = direction.x < 0.0
	slime.call("_play_animation", "move")


func _boss() -> Node2D:
	for boss: Node2D in slime.get_tree().get_nodes_in_group("boss_target"):
		if boss.global_position.distance_to(slime.global_position) <= HELP_RANGE: return boss
	return null


func _help(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0: return
	var boss := _boss()
	if boss == null: return
	match str(slime.get("slime_type")):
		"brotinho":
			_cooldown = SHOT_EVERY
			_shoot(boss)
		"bolhinha":
			if HEALTH.current(slime.get_tree()) >= 100: return
			_cooldown = HEAL_EVERY
			HEALTH.change(slime.get_tree(), HEAL)
			_burst(player.global_position, Color("#8fd8f0"), "+%d" % HEAL)
		"musguinho":
			_cooldown = SLOW_EVERY
			if boss.has_method("slow"): boss.call("slow", SLOW_TIME)
			_burst(boss.global_position, Color("#9cc07a"), "Lento!")
		_:
			_cooldown = SHOT_EVERY


## Semente do Brotinho: voa reto até o boss e acerta o desenho dele.
func _shoot(boss: Node2D) -> void:
	var shot := Shot.new()
	shot.target = boss
	shot.global_position = slime.global_position + Vector2(0, -16)
	slime.get_parent().add_child(shot)


## Efeito curto (cura, lentidão): círculo que abre e texto que sobe.
func _burst(at: Vector2, color: Color, text: String) -> void:
	var fx := Burst.new()
	fx.color = color
	fx.text = text
	fx.global_position = at
	slime.get_parent().add_child(fx)


## Dano dos golpes do boss (slime_boss.gd); desmaiado volta para casa até amanhã.
func take_boss_hit(amount: int) -> void:
	hp -= amount
	var sprite: CanvasItem = slime.get("sprite")
	if sprite:
		sprite.modulate = Color(1.0, 0.45, 0.45)
		slime.get_tree().create_timer(0.18).timeout.connect(func() -> void: if is_instance_valid(sprite): sprite.modulate = Color.WHITE)
	if hp > 0: return
	var tree := slime.get_tree()
	THREAT.pet_fainted(tree, str(slime.get("persistent_id")))
	var region: Node = slime.get_parent()
	if region and region.has_method("_notify"):
		region.call("_notify", "%s desmaiou e voltou para casa. Amanhã pode acompanhar de novo." % slime.call("display_name"))
	slime.queue_free()  # o habitat o traz de volta em casa


class Shot extends Node2D:
	var target: Node2D
	var _life := 2.0

	func _ready() -> void:
		z_index = 10

	func _process(delta: float) -> void:
		_life -= delta
		if not is_instance_valid(target) or _life <= 0.0:
			queue_free()
			return
		var rect: Rect2 = target.call("hurt_rect")
		var aim := rect.get_center()
		global_position = global_position.move_toward(aim, SHOT_SPEED * delta)
		if rect.grow(4.0).has_point(global_position):
			target.call("take_hit", SHOT_DAMAGE, global_position)
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 4.0, Color("#6fbf4a"))
		draw_circle(Vector2(-1, -1), 1.5, Color("#d8f5b0"))


class Burst extends Node2D:
	var color := Color.WHITE
	var text := ""
	var _t := 0.0

	func _ready() -> void:
		z_index = 10

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.7: queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := _t / 0.7
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, 14.0 + 26.0 * k, 0.0, TAU, 28, Color(color, 1.0 - k), 3.0)
		draw_set_transform(Vector2.ZERO)
		draw_string(ThemeDB.fallback_font, Vector2(-10, -40 - 20 * k), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(color, 1.0 - k))

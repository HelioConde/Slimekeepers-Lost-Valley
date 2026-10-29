extends CharacterBody2D
## Shared peaceful creature: bounded visits, rest, environmental preferences and social pauses.
signal friendship_started(persistent_id: String)
const FRAMES: SpriteFrames = preload("res://assets/slimes/bestiary/brotinho/brotinho_frames.tres")
const SPECIES := preload("res://scripts/world/slime_species.gd")
const WALK_SPEED := 30.0
const ACTIVE_DISTANCE := 1000.0

var slime_type := "brotinho"
var persistent_id := ""
var befriended := false
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
var _hop_time := 0.0
var _social_cooldown := 0.0
var _curiosity_cooldown := 0.0
var _threat_timer := 0.0
var _moving := false
var _social_partner: Node2D
var _session_key := "forest_slime_friends"
var swimming := false
var _water_material: ShaderMaterial
var _swim_path := PackedVector2Array()

func configure(habitat_manager: Node2D, observed_player: Node2D, habitat_data: Dictionary, instance_id: String) -> void:
	manager = habitat_manager
	player = observed_player
	habitat = habitat_data
	persistent_id = instance_id
	slime_type = instance_id.get_slice("/", 0)
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
	_play_animation("idle")

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

func display_name() -> String:
	return str(personality.name)

func make_friend() -> bool:
	if befriended:
		return false
	befriended = true
	var friends: Dictionary = get_tree().get_meta(_session_key, {})
	friends[persistent_id] = true
	get_tree().set_meta(_session_key, friends)
	_happy_time = 2.4
	_rest(2.4)
	_play_animation("happy")
	friendship_started.emit(persistent_id)
	return true

func _physics_process(delta: float) -> void:
	_update_swimming()
	_happy_time = maxf(0.0, _happy_time - delta)
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
		animation = "happy"
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

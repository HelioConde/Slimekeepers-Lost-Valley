extends CharacterBody2D
## Versao leve da fauna do Slime-Harvest para a Clareira Encantada.
## Preserva sprites e animacoes; nao ativa combate, captura ou fome.
const TURN_INTERVAL_MIN: float = 1.2
const TURN_INTERVAL_MAX: float = 3.4
const IDLE_CHANCE: float = 0.35

var species_id: String = ""
var home_position: Vector2 = Vector2.ZERO
var roam_radius: float = 90.0
var roam_speed: float = 23.0
var _decision_remaining: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _move: bool = false
var _rng := RandomNumberGenerator.new()
var _world_guard: Node
var _visual: AnimatedSprite2D


func configure(species: String, animation_frames: SpriteFrames, at: Vector2, seed_value: int, world_guard: Node) -> void:
	species_id = species
	home_position = at
	global_position = at
	_world_guard = world_guard
	_rng.seed = seed_value
	roam_speed = _rng.randf_range(17.0, 28.0)
	roam_radius = _rng.randf_range(55.0, 103.0)

	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	var feet := CollisionShape2D.new()
	feet.name = "FeetCollision"
	feet.position = Vector2(0.0, -4.0)
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	feet.shape = circle
	add_child(feet)

	_visual = AnimatedSprite2D.new()
	_visual.name = "AnimatedSprite2D"
	_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_visual.sprite_frames = animation_frames
	_visual.scale = Vector2.ONE * 0.49
	if animation_frames.has_animation(&"idle") and animation_frames.get_frame_count(&"idle") > 0:
		var texture: Texture2D = animation_frames.get_frame_texture(&"idle", 0)
		if texture != null:
			var image: Image = texture.get_image()
			if image != null and not image.is_empty():
				var used: Rect2i = image.get_used_rect()
				if used.size != Vector2i.ZERO:
					_visual.offset = Vector2(0.0, float(image.get_height()) * 0.5 - float(used.end.y))
	add_child(_visual)


func _ready() -> void:
	add_to_group("slimes_ambientais")
	_decision_remaining = _rng.randf_range(0.5, 2.4)
	_play(&"idle")


func _physics_process(delta: float) -> void:
	_decision_remaining -= delta
	if _decision_remaining <= 0.0:
		_decide()
	if not _move:
		velocity = Vector2.ZERO
		return
	var predicted: Vector2 = global_position + _direction * roam_speed * delta * 2.0
	if predicted.distance_to(home_position) > roam_radius or not _can_walk(predicted):
		_decide(true)
		velocity = Vector2.ZERO
		return
	velocity = _direction * roam_speed
	move_and_slide()
	if get_slide_collision_count() > 0:
		_decide(true)
	velocity = Vector2.ZERO if not _move else velocity
	if _visual != null:
		_visual.flip_h = _direction.x < -0.1


func _decide(force_pause: bool = false) -> void:
	_move = not force_pause and _rng.randf() > IDLE_CHANCE
	_decision_remaining = _rng.randf_range(TURN_INTERVAL_MIN, TURN_INTERVAL_MAX)
	if not _move:
		_play(&"idle")
		return
	var direction: Vector2 = Vector2.RIGHT.rotated(_rng.randf_range(-PI, PI))
	if global_position.distance_to(home_position) > roam_radius * 0.65:
		direction = (home_position - global_position).normalized().rotated(_rng.randf_range(-0.5, 0.5))
	_direction = direction
	_play(&"move")


func _can_walk(point: Vector2) -> bool:
	if _world_guard == null or not is_instance_valid(_world_guard):
		return false
	return bool(_world_guard.call("is_safe_position", point))


func _play(animation: StringName) -> void:
	if _visual == null or _visual.sprite_frames == null:
		return
	var candidate: StringName = animation if _visual.sprite_frames.has_animation(animation) else &"idle"
	if _visual.animation != candidate or not _visual.is_playing():
		_visual.play(candidate)

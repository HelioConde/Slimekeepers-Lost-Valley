extends CharacterBody2D
## Controle de movimento top-down em 8 direcoes.
## W/A/S/D e setas = mover | Shift = correr | Espaco = dash.
## Direcoes preservam o ultimo sentido ao parar.

signal motion_state_changed(state: String, direction: String)

const InputBindings = preload("res://scripts/input_bindings.gd")
const MovementFramesBuilder = preload("res://scripts/movement_animation_library.gd")

@export_group("Velocidades (pixels/segundo)")
@export_range(10.0, 400.0, 1.0) var walk_speed: float = 90.0
@export_range(10.0, 500.0, 1.0) var run_speed: float = 155.0
@export_range(10.0, 800.0, 1.0) var dash_speed: float = 315.0

@export_group("Aparencia")
@export_range(0.3, 1.25, 0.01) var visual_scale: float = 0.40

@export_group("Resposta do movimento")
@export_range(50.0, 3000.0, 10.0) var acceleration: float = 900.0
@export_range(50.0, 3000.0, 10.0) var friction: float = 1300.0

@export_group("Dash")
@export_range(0.05, 1.0, 0.01) var dash_duration: float = 0.16
@export_range(0.05, 3.0, 0.01) var dash_cooldown: float = 0.60

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var feet_collision: CollisionShape2D = $CollisionShape2D

const CLOCKWISE_FROM_EAST := [
	"east", "south-east", "south", "south-west",
	"west", "north-west", "north", "north-east"
]

var facing: String = "south"
var motion_state: String = "idle"
var movement_locked: bool = false
var _dash_time: float = 0.0
var _cooldown_time: float = 0.0
var _dash_vector: Vector2 = Vector2.DOWN
var _tool_animation: String = ""
var _tool_time_left: float = 0.0


func _ready() -> void:
	InputBindings.install()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var frame_builder = MovementFramesBuilder.new()
	sprite.sprite_frames = frame_builder.make_sprite_frames()
	_setup_visual_proportions()
	_set_animation("idle")



## Alinha os pes do frame original a origem de Player (ponto usado no Y-sort).
## So altera a exibicao/collider: nunca modifica PNGs da PixelLab.
func _setup_visual_proportions() -> void:
	sprite.scale = Vector2.ONE * visual_scale
	var frames: SpriteFrames = sprite.sprite_frames
	if frames != null and frames.has_animation(&"idle_south") and frames.get_frame_count(&"idle_south") > 0:
		var texture: Texture2D = frames.get_frame_texture(&"idle_south", 0)
		if texture != null:
			var image_data: Image = texture.get_image()
			if image_data != null and not image_data.is_empty():
				var used: Rect2i = image_data.get_used_rect()
				if used.size != Vector2i.ZERO:
					sprite.offset = Vector2(0.0, float(image_data.get_height()) * 0.5 - float(used.end.y))
	var source_shape: CircleShape2D = feet_collision.shape as CircleShape2D
	if source_shape != null:
		# Duplica o recurso para evitar modificar a colisao de outras instancias.
		var local_shape: CircleShape2D = source_shape.duplicate() as CircleShape2D
		local_shape.radius = maxf(3.0, source_shape.radius * visual_scale)
		feet_collision.shape = local_shape
		feet_collision.position = Vector2(0.0, -local_shape.radius)

func _physics_process(delta: float) -> void:
	_cooldown_time = maxf(0.0, _cooldown_time - delta)
	if _tool_time_left > 0.0:
		_tool_time_left = maxf(0.0, _tool_time_left - delta)
		velocity = Vector2.ZERO
		motion_state = "tool"
		if _tool_time_left <= 0.0:
			_tool_animation = ""
			_set_animation("idle")
		return

	var input_dir := Vector2.ZERO
	if not movement_locked:
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir.length_squared() > 0.0001 and _dash_time <= 0.0:
		facing = _vector_to_direction(input_dir)

	if movement_locked:
		_dash_time = 0.0
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		motion_state = "idle"
	elif _dash_time > 0.0:
		_dash_time = maxf(0.0, _dash_time - delta)
		velocity = _dash_vector * dash_speed
		motion_state = "dash"
	elif input_dir.length_squared() > 0.0001 and Input.is_action_just_pressed("dash") and _cooldown_time <= 0.0:
		_dash_vector = input_dir.normalized()
		_dash_time = dash_duration
		_cooldown_time = dash_cooldown
		velocity = _dash_vector * dash_speed
		motion_state = "dash"
	else:
		var running := Input.is_action_pressed("run") and input_dir.length_squared() > 0.0001
		var target_speed := run_speed if running else walk_speed
		var target_velocity := input_dir * target_speed
		var response := acceleration if input_dir.length_squared() > 0.0001 else friction
		velocity = velocity.move_toward(target_velocity, response * delta)
		motion_state = "idle" if input_dir.length_squared() <= 0.0001 else ("run" if running else "walk")

	move_and_slide()
	_set_animation("run" if motion_state == "dash" else motion_state)


func _set_animation(state: String) -> void:
	var name := "%s_%s" % [state, facing]
	if not sprite.sprite_frames.has_animation(name):
		name = "idle_%s" % facing
	if not sprite.sprite_frames.has_animation(name):
		return

	if sprite.animation != name or not sprite.is_playing():
		sprite.play(name)
		motion_state_changed.emit(motion_state, facing)


func _vector_to_direction(direction: Vector2) -> String:
	# angulo zero = leste, crescendo no sentido horario porque Y cresce para baixo.
	var angle_deg := fposmod(rad_to_deg(direction.angle()), 360.0)
	var index := int(round(angle_deg / 45.0)) % 8
	return CLOCKWISE_FROM_EAST[index]


func set_movement_locked(locked: bool) -> void:
	# Ganchos para futuras interacoes (minerar, colher, conversar etc.).
	movement_locked = locked
	if locked:
		_dash_time = 0.0


## Reproduz a animacao PixelLab correspondente a ferramenta e direcao atuais.
## Invocada pelo BasicToolSystem ao usar F/clique, ou ao interagir.
func play_tool_animation(tool_id: String) -> void:
	var type_id: String = tool_id
	match tool_id:
		"machado": type_id = "axe"
		"picareta": type_id = "pickaxe"
		"enxada": type_id = "hoe"
		"regador": type_id = "watering"
		"foice", "colheita": type_id = "scythe"
		"pa": type_id = "shovel"
		"pesca": type_id = "fishing"
	var animation: String = "tool_%s_%s" % [type_id, facing]
	if not sprite.sprite_frames.has_animation(animation):
		return
	var frames: SpriteFrames = sprite.sprite_frames
	_tool_animation = animation
	_tool_time_left = float(frames.get_frame_count(animation)) / maxf(1.0, frames.get_animation_speed(animation))
	_dash_time = 0.0
	velocity = Vector2.ZERO
	sprite.play(animation)
	motion_state_changed.emit("tool_" + type_id, facing)


func get_dash_ready() -> bool:
	return _cooldown_time <= 0.0 and _dash_time <= 0.0

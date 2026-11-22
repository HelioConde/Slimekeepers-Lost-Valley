extends CharacterBody2D
## Personagem 2D com movimento em 8 direções e animações dos assets originais.

const WALK_SPEED: float = 145.0
const RUN_SPEED: float = 220.0
const WORLD_BOUNDS = Rect2(34.0, 70.0, 1212.0, 835.0)
const DIRS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]

const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
## Ferramentas: chave da pasta em PROTAGONIST.ALL, quadros e velocidade.
const TOOL_ANIMATIONS := {"hoe": ["hoe", 9, 16.0], "water": ["water", 9, 14.0]}
## Despertar (intro_wake.gd): só sul, quadros contados no disco; laço = repete.
const WAKE_ANIMATIONS := {"sit_idle": [5.0, true], "sit_look_left": [6.0, false], "sit_look_right": [6.0, false],
	"sit_confused": [6.0, false], "stand_up": [9.0, false]}

@export var world_bounds: Rect2 = WORLD_BOUNDS
var _tool_time := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var facing: String = "south"
var current_animation: String = ""

func _ready() -> void:
	# Top-down obstacles meet the feet, not a vertical capsule covering the shins.
	var footprint := RectangleShape2D.new()
	footprint.size = Vector2(18,12)
	$CollisionShape2D.shape = footprint
	$CollisionShape2D.position = Vector2(0,-6)
	sprite.sprite_frames = _build_frames()
	_play_animation("idle_south")

func _physics_process(_delta: float) -> void:
	if _tool_time > 0.0:
		# Durante o golpe da ferramenta o personagem fica parado, virado para o alvo.
		_tool_time -= _delta
		velocity = Vector2.ZERO
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := Input.is_action_pressed("sprint")
	velocity = input_dir * (RUN_SPEED if running else WALK_SPEED)
	if input_dir.length_squared() > 0.01:
		facing = _get_direction_name(input_dir)
		_play_animation(("run_" if running else "walk_") + facing)
	else:
		_play_animation("idle_" + facing)
	move_and_slide()
	global_position = global_position.clamp(world_bounds.position, world_bounds.end)

func _get_direction_name(direction: Vector2) -> String:
	var angle := wrapf(direction.angle() + PI / 2.0, 0.0, TAU)
	var sector := int(round(angle / (PI / 4.0))) % 8
	# 0 = norte, 2 = leste, 4 = sul, 6 = oeste
	var names := ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]
	return names[sector]

## Toca a animação da ferramenta na direção atual; devolve a duração (s).
func play_tool(tool: String) -> float:
	var name := "%s_%s" % [tool, facing]
	if not sprite.sprite_frames.has_animation(name):
		return 0.0
	current_animation = name
	sprite.play(name)
	_tool_time = sprite.sprite_frames.get_frame_count(name) / sprite.sprite_frames.get_animation_speed(name)
	return _tool_time

func is_using_tool() -> bool:
	return _tool_time > 0.0

func _play_animation(name: String) -> void:
	if current_animation != name:
		current_animation = name
		sprite.play(name)

func _build_frames() -> SpriteFrames:
	var who: Dictionary = PROTAGONIST.data(get_tree()) if is_inside_tree() else PROTAGONIST.ALL[PROTAGONIST.DEFAULT]
	var art: String = who.art
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for direction in DIRS:
		var idle: String = "idle_" + direction
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 1.0)
		var idle_path := "%s/rotations/%s.png" % [art, direction]
		frames.add_frame(idle, load(idle_path) as Texture2D)
		for data in [["walk", "Walk", 6, 8.0], ["run", "Running", 8, 11.0]]:
			var anim_name: String = str(data[0]) + "_" + direction
			var directory: String = direction
			if str(data[1]) == "Walk" and direction == "south":
				directory = str(who.walk_south_dir)
			frames.add_animation(anim_name)
			frames.set_animation_speed(anim_name, float(data[3]))
			for frame_index in range(int(data[2])):
				var file_path := "%s/animations/%s/%s/frame_%03d.png" % [art, data[1], directory, frame_index]
				frames.add_frame(anim_name, load(file_path) as Texture2D)
		for tool in TOOL_ANIMATIONS:
			var data: Array = TOOL_ANIMATIONS[tool]
			var tool_anim := "%s_%s" % [tool, direction]
			frames.add_animation(tool_anim)
			frames.set_animation_loop(tool_anim, false)
			frames.set_animation_speed(tool_anim, float(data[2]))
			for frame_index in int(data[1]):
				frames.add_frame(tool_anim, load("%s/%s/frame_%03d.png" % [who[data[0]], direction, frame_index]) as Texture2D)
	for wake in WAKE_ANIMATIONS:
		var path_pattern: String = art + "/wake/" + wake + "/south/frame_%03d.png"
		if not ResourceLoader.exists(path_pattern % 0): continue
		frames.add_animation(wake)
		frames.set_animation_speed(wake, float(WAKE_ANIMATIONS[wake][0]))
		frames.set_animation_loop(wake, bool(WAKE_ANIMATIONS[wake][1]))
		var loaded: Array[Texture2D] = []
		while ResourceLoader.exists(path_pattern % loaded.size()):
			loaded.append(load(path_pattern % loaded.size()) as Texture2D)
		for texture in loaded: frames.add_frame(wake, texture)
		if wake != "stand_up":
			# Ida e volta: toda pose termina na posição sentada de base, onde a
			# próxima começa (sem salto entre estados; o laço da respiração fecha).
			frames.add_frame(wake, loaded[-1], 2.0)
			for k in range(loaded.size() - 2, 0, -1): frames.add_frame(wake, loaded[k])
	return frames


## Toca uma animação do despertar; devolve a duração (s), 0 se não existir.
func play_wake(name: String) -> float:
	if not sprite.sprite_frames.has_animation(name):
		return 0.0
	current_animation = name
	sprite.play(name)
	return sprite.sprite_frames.get_frame_count(name) / sprite.sprite_frames.get_animation_speed(name)

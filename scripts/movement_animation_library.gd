extends RefCounted
## Monta SpriteFrames em 8 direcoes a partir da exportacao PixelLab.
## As imagens originais nunca sao sobrescritas.

const ROOT: String = "res://sprites/Idle"
const ANIMATIONS: String = ROOT + "/animations"
const IDLE_CLIP: String = "The_adventurer_maintains_a_relaxed_idle_stance_whi"
const WALK_CLIP: String = "Walk"
const RUN_CLIP: String = "Running"

const DIRECTIONS: Array[String] = [
	"south", "south-east", "east", "north-east",
	"north", "north-west", "west", "south-west"
]
const FPS: Dictionary = {"idle": 5.0, "walk": 10.0, "run": 13.0}
const WALK_SOUTH_PRIMARY: String = "south-f96d7729"
const WALK_SOUTH_SECONDARY: String = "south-2b9cc8e0"

# True: alinha discretamente os centros das cabecas e a linha inferior,
# reduzindo deslocamento indesejado de quadros gerados por IA.
# Desative para comparar o movimento bruto dos PNGs.
const STABILIZE_WALK_RUN: bool = true
const MAX_SHIFT_X: int = 4
const MAX_SHIFT_Y: int = 2


func make_sprite_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	for state_value in ["idle", "walk", "run"]:
		var state: String = str(state_value)
		for direction_value in DIRECTIONS:
			var direction: String = str(direction_value)
			var animation_name: String = "%s_%s" % [state, direction]
			var paths: Array[String] = _get_frame_paths(state, direction)
			if paths.is_empty():
				var fallback: String = ROOT + "/rotations/" + direction + ".png"
				if ResourceLoader.exists(fallback):
					paths.append(fallback)
					push_warning("Sem quadros %s; usando sprite estatico." % animation_name)
				else:
					push_error("Imagem ausente: %s" % fallback)
					continue

			var textures: Array[Texture2D] = _load_textures(paths)
			if textures.is_empty():
				continue
			if STABILIZE_WALK_RUN and (state == "walk" or state == "run"):
				textures = _align_frames(textures)

			frames.add_animation(animation_name)
			frames.set_animation_speed(animation_name, float(FPS.get(state, 8.0)))
			frames.set_animation_loop(animation_name, true)
			for texture in textures:
				frames.add_frame(animation_name, texture)
	_add_tool_animations(frames)
	return frames


func _load_textures(paths: Array[String]) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in paths:
		var texture: Texture2D = load(path) as Texture2D
		if texture != null:
			textures.append(texture)
	return textures


func _align_frames(original: Array[Texture2D]) -> Array[Texture2D]:
	if original.size() < 2:
		return original

	var images: Array[Image] = []
	var anchors: Array[Vector2] = []
	var xs: Array[float] = []
	var ys: Array[float] = []
	for texture in original:
		var image_data: Image = texture.get_image()
		if image_data == null or image_data.is_empty():
			return original
		image_data.convert(Image.FORMAT_RGBA8)
		images.append(image_data)
		var anchor: Vector2 = _frame_anchor(image_data)
		anchors.append(anchor)
		xs.append(anchor.x)
		ys.append(anchor.y)

	xs.sort()
	ys.sort()
	var middle: int = int(xs.size() / 2)
	var target: Vector2 = Vector2(xs[middle], ys[middle])
	var fixed: Array[Texture2D] = []

	for i in range(images.size()):
		var dx: int = clampi(int(round(target.x - anchors[i].x)), -MAX_SHIFT_X, MAX_SHIFT_X)
		var dy: int = clampi(int(round(target.y - anchors[i].y)), -MAX_SHIFT_Y, MAX_SHIFT_Y)
		if dx == 0 and dy == 0:
			fixed.append(original[i])
			continue
		var image_data: Image = images[i]
		var shifted: Image = Image.create(image_data.get_width(), image_data.get_height(), false, Image.FORMAT_RGBA8)
		shifted.fill(Color.TRANSPARENT)
		shifted.blit_rect(image_data, Rect2i(Vector2i.ZERO, image_data.get_size()), Vector2i(dx, dy))
		var rebuilt_texture: ImageTexture = ImageTexture.create_from_image(shifted)
		fixed.append(rebuilt_texture)
	return fixed


func _frame_anchor(image_data: Image) -> Vector2:
	var used: Rect2i = image_data.get_used_rect()
	if used.size == Vector2i.ZERO:
		return Vector2(image_data.get_width() * 0.5, image_data.get_height() * 0.9)

	# A cabeca e mais estavel que pes/bracos durante as passadas.
	# Mede o centro horizontal nas linhas superiores do personagem.
	var y_start: int = used.position.y + int(used.size.y * 0.12)
	var y_end: int = used.position.y + int(used.size.y * 0.38)
	var x_total: float = 0.0
	var valid_rows: int = 0
	for y in range(y_start, y_end, 2):
		var first: int = used.end.x
		var last: int = -1
		for x in range(used.position.x, used.end.x):
			if image_data.get_pixel(x, y).a > 0.5:
				first = mini(first, x)
				last = maxi(last, x)
		if last >= first:
			x_total += (float(first) + float(last)) * 0.5
			valid_rows += 1

	var center_x: float = float(used.position.x) + float(used.size.x) * 0.5
	if valid_rows > 0:
		center_x = x_total / float(valid_rows)
	return Vector2(center_x, float(used.end.y))


func _get_frame_paths(state: String, direction: String) -> Array[String]:
	var clip: String = IDLE_CLIP
	match state:
		"walk":
			clip = WALK_CLIP
		"run":
			clip = RUN_CLIP

	var parent_path: String = ANIMATIONS + "/" + clip
	var selected: String = parent_path + "/" + direction
	if state == "walk" and direction == "south":
		selected = parent_path + "/" + WALK_SOUTH_PRIMARY
		if not DirAccess.dir_exists_absolute(selected):
			selected = parent_path + "/" + WALK_SOUTH_SECONDARY
	if not DirAccess.dir_exists_absolute(selected):
		return []

	var files: PackedStringArray = DirAccess.get_files_at(selected)
	files.sort()
	var paths: Array[String] = []
	for file_name in files:
		if file_name.begins_with("frame_") and file_name.ends_with(".png"):
			paths.append(selected + "/" + file_name)
	return paths

## Sequencias de acao verdadeiras exportadas da PixelLab, preservadas em 8 direcoes.
## Se algum angulo nao foi exportado, essa direcao nao recebe animacao inventada.
const TOOL_ACTIONS: Dictionary = {
	"axe": {"folder": "Create_an_Axe_Equipp", "preferred": "The_adventurer_lifts"},
	"pickaxe": {"folder": "Create_a_Pickaxe_Equ", "preferred": "The_adventurer_grips"},
	"hoe": {"folder": "Create_a_Hoe_Equippe", "preferred": "The_adventurer_grips"},
	"watering": {"folder": "Create_a_Watering_Ca", "preferred": "The_character_lifts"},
	"scythe": {"folder": "Create_a_Scythe_Equi", "preferred": "The_character_pulls"},
	"shovel": {"folder": "Create_a_Shovel_Equi", "preferred": "The_adventurer_grips"},
	"fishing": {"folder": "Create_a_Fishing_Rod", "preferred": "The_adventurer_rhythmically"},
	"interact": {"folder": "Idle", "preferred": "The_character_performs_a_gentle_interaction_gestur"}
}

func _add_tool_animations(frames: SpriteFrames) -> void:
	for key in TOOL_ACTIONS:
		var spec: Dictionary = TOOL_ACTIONS[key]
		var root: String = "res://sprites/" + String(spec["folder"]) + "/animations"
		if not DirAccess.dir_exists_absolute(root):
			push_warning("Animacao de ferramenta nao encontrada: " + root)
			continue
		var clips: PackedStringArray = DirAccess.get_directories_at(root)
		clips.sort()
		var preferred: String = String(spec["preferred"])
		var ordered: Array[String] = []
		for clip in clips:
			if clip.begins_with(preferred):
				ordered.append(clip)
		for clip in clips:
			if not clip.begins_with(preferred):
				ordered.append(clip)
		for direction in DIRECTIONS:
			var paths: Array[String] = []
			for clip in ordered:
				var dir: String = root.path_join(clip).path_join(direction)
				if not DirAccess.dir_exists_absolute(dir):
					continue
				var file_names: PackedStringArray = DirAccess.get_files_at(dir)
				file_names.sort()
				for file_name in file_names:
					if file_name.begins_with("frame_") and file_name.ends_with(".png"):
						paths.append(dir.path_join(file_name))
				if not paths.is_empty():
					break
			if paths.is_empty():
				continue
			var animation: String = "tool_%s_%s" % [String(key), direction]
			frames.add_animation(animation)
			frames.set_animation_speed(animation, 12.0)
			frames.set_animation_loop(animation, false)
			for texture in _load_textures(paths):
				frames.add_frame(animation, texture)

extends RefCounted
## Monta SpriteFrames para AnimatedSprite2D a partir dos PNGs do repositorio.
## Nao modifica nem duplica os originais; suporta os 8 sentidos.

const ROOT: String = "res://sprites/Idle"
const ANIMATIONS: String = ROOT + "/animations"
const IDLE_CLIP: String = "The_adventurer_maintains_a_relaxed_idle_stance_whi"
const WALK_CLIP: String = "Walk"
const RUN_CLIP: String = "Running"

const DIRECTIONS := [
	"south", "south-east", "east", "north-east",
	"north", "north-west", "west", "south-west"
]

const FPS: Dictionary = {"idle": 5.0, "walk": 10.0, "run": 13.0}

# O ZIP exportado do PixelLab contem 2 versoes de walk/south.
# Preferimos a segunda versao; se faltar, o carregador usa a primeira.
const WALK_SOUTH_PRIMARY: String = "south-f96d7729"
const WALK_SOUTH_SECONDARY: String = "south-2b9cc8e0"


func make_sprite_frames() -> SpriteFrames:
	var library: SpriteFrames = SpriteFrames.new()
	if library.has_animation(&"default"):
		library.remove_animation(&"default")

	for state_value in ["idle", "walk", "run"]:
		var state: String = str(state_value)
		for direction_value in DIRECTIONS:
			var direction: String = str(direction_value)
			var anim: String = "%s_%s" % [state, direction]
			var paths: Array[String] = _get_frame_paths(state, direction)
			if paths.is_empty():
				# Mesmo sem uma exportacao especifica, o jogador ainda aparece.
				var fallback: String = ROOT + "/rotations/" + direction + ".png"
				if ResourceLoader.exists(fallback):
					paths.append(fallback)
					push_warning("Sem frames para %s; usando rotacao estatica." % anim)
				else:
					push_error("Sprite ausente: %s (verifique a pasta sprites/Idle)." % anim)
					continue

			library.add_animation(anim)
			library.set_animation_speed(anim, float(FPS.get(state, 8.0)))
			library.set_animation_loop(anim, true)
			for path in paths:
				var texture: Texture2D = load(path) as Texture2D
				if texture != null:
					library.add_frame(anim, texture)
			if library.get_frame_count(anim) == 0:
				library.remove_animation(anim)

	return library


func _get_frame_paths(state: String, direction: String) -> Array[String]:
	var clip: String = IDLE_CLIP
	match state:
		"walk":
			clip = WALK_CLIP
		"run":
			clip = RUN_CLIP

	var parent: String = ANIMATIONS + "/" + clip
	var selected: String = parent + "/" + direction

	if state == "walk" and direction == "south":
		selected = parent + "/" + WALK_SOUTH_PRIMARY
		if not DirAccess.dir_exists_absolute(selected):
			selected = parent + "/" + WALK_SOUTH_SECONDARY

	if not DirAccess.dir_exists_absolute(selected):
		return []

	var filenames: PackedStringArray = DirAccess.get_files_at(selected)
	filenames.sort()  # frame_000, frame_001 ... frame_015
	var paths: Array[String] = []
	for filename in filenames:
		if filename.begins_with("frame_") and filename.ends_with(".png"):
			paths.append(selected + "/" + filename)
	return paths

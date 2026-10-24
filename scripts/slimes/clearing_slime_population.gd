extends Node
## Uma unidade de cada especie (32) do bestiario Slime-Harvest.
## Distribui por habitat sem alterar o mundo e sem gerar criaturas hostis.
const SlimeAmbient = preload("res://scripts/slimes/ambient_slime.gd")
const SPRITE_ROOT: String = "res://assets/slimes/bestiary"
const MIN_DISTANCE_FROM_PLAYER: float = 105.0
const MIN_DISTANCE_BETWEEN_SLIMES: float = 58.0
const SPECIES_BY_HABITAT: Dictionary = {
	"horta": ["brotinho", "colhita", "compo", "terrinho", "capinito", "fiapo", "seletim"],
	"lagoa": ["gota", "riacho", "chuvao"],
	"rochas": ["pedrito", "ferrito", "engrenito", "prismita", "faisca", "gelito"],
	"floresta": ["lenhoco", "raizela", "pomelo", "funguinho", "chefito", "noturno", "alquimita", "guardito"],
	"prado": ["polenita", "melado", "curinha", "ventinho", "lumito", "brasinha", "carreguim", "construlim"]
}
const HABITAT_REGIONS: Dictionary = {
	"horta": Rect2(-440.0, -525.0, 530.0, 360.0),
	"lagoa": Rect2(-490.0, 100.0, 370.0, 450.0),
	"rochas": Rect2(300.0, -540.0, 650.0, 790.0),
	"floresta": Rect2(-900.0, -520.0, 1020.0, 1060.0),
	"prado": Rect2(-120.0, -240.0, 880.0, 800.0)
}

@export var enabled: bool = true
@export var fixed_seed: int = 241026
@export var visible_names: bool = false

@onready var ground: TileMapLayer = get_node("../Ground") as TileMapLayer
@onready var player: CharacterBody2D = get_node("../WorldObjects/Player") as CharacterBody2D
@onready var objects: Node2D = get_node("../WorldObjects") as Node2D
@onready var world: Node2D = get_parent() as Node2D
@onready var house_builder: Node = get_node_or_null("../HouseBuilder")

var _rng := RandomNumberGenerator.new()
var _places: Array[Vector2] = []
var _slimes: Array[CharacterBody2D] = []
var _habitats: Dictionary = {}
var _safety_shape := CircleShape2D.new()


func _ready() -> void:
	_safety_shape.radius = 8.0
	if enabled:
		call_deferred("_populate")


func _populate() -> void:
	_rng.seed = fixed_seed
	_places.clear()
	_slimes.clear()
	_habitats.clear()
	var registered: int = 0
	var missing: Array[String] = []
	for habitat_key in SPECIES_BY_HABITAT.keys():
		var habitat: String = String(habitat_key)
		for id_value in SPECIES_BY_HABITAT[habitat]:
			var species: String = String(id_value)
			var frames_path: String = "%s/%s/%s_frames.tres" % [SPRITE_ROOT, species, species]
			if not ResourceLoader.exists(frames_path):
				missing.append(species)
				continue
			var frames: SpriteFrames = load(frames_path) as SpriteFrames
			if frames == null or not frames.has_animation(&"idle"):
				missing.append(species)
				continue
			var position: Vector2 = _find_spawn(habitat)
			if not is_finite(position.x):
				push_warning("Sem local para o slime %s (%s)" % [species, habitat])
				continue
			var slime: CharacterBody2D = CharacterBody2D.new()
			slime.set_script(SlimeAmbient)
			slime.name = species.capitalize()
			slime.call("configure", species, frames, position, _rng.randi(), self)
			objects.add_child(slime)
			_places.append(position)
			_slimes.append(slime)
			_habitats[species] = habitat
			registered += 1
			if visible_names:
				var label := Label.new()
				label.text = species.capitalize()
				label.position = Vector2(-30.0, -48.0)
				label.add_theme_font_size_override("font_size", 10)
				slime.add_child(label)
	if not missing.is_empty():
		push_warning("Slimes ausentes no projeto: %s. Execute a importacao de assets." % ", ".join(missing))
	print("Clareira Encantada: %d slimes do Slime-Harvest, em 5 habitats." % registered)


func _find_spawn(habitat: String) -> Vector2:
	var bounds: Rect2 = HABITAT_REGIONS[habitat]
	for allow_road in [false, true]:
		for attempt in range(400):
			var pt := Vector2(
				_rng.randf_range(bounds.position.x, bounds.end.x),
				_rng.randf_range(bounds.position.y, bounds.end.y)
			)
			pt = ground.to_global(ground.map_to_local(ground.local_to_map(ground.to_local(pt))))
			if not is_safe_position(pt):
				continue
			if pt.distance_to(player.global_position) < MIN_DISTANCE_FROM_PLAYER:
				continue
			if not allow_road and world.has_method("_is_road") and bool(world.call("_is_road", pt)):
				continue
			if habitat == "lagoa" and not _near_water(pt):
				continue
			if habitat == "horta" and pt.x < -445.0:
				continue
			var separated: bool = true
			for occupied in _places:
				if pt.distance_to(occupied) < MIN_DISTANCE_BETWEEN_SLIMES:
					separated = false
					break
			if separated:
				return pt
	return Vector2(INF, INF)


func _near_water(point: Vector2) -> bool:
	var center: Vector2 = Vector2(-690.0, 285.0)
	var rx: float = 264.0
	var ry: float = 218.0
	var dx: float = (point.x - center.x) / rx
	var dy: float = (point.y - center.y) / ry
	var distance: float = sqrt(dx * dx + dy * dy)
	return distance >= 1.12 and distance < 2.25


func is_safe_position(point: Vector2) -> bool:
	var cell: Vector2i = ground.local_to_map(ground.to_local(point))
	if ground.get_cell_source_id(cell) < 0:
		return false
	if world.has_method("_inside_water") and bool(world.call("_inside_water", point, 1.23)):
		return false
	if point.x > 688.0 and point.y < -323.0:
		return false
	if house_builder != null and house_builder.has_method("is_world_point_protected"):
		if bool(house_builder.call("is_world_point_protected", point, 2)):
			return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _safety_shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = 1
	return world.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

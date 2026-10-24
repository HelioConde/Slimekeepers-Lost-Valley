extends Node2D
## Slimekeepers: Lost Valley — primeira clareira exploravel.
## Composicao inspirada na arte-conceito: bifurcacao, pequena fazenda,
## lagoa e doca, floresta, rochas e saidas norte/leste/sul.
## Os props PixelLab exportados usam a tabela global world_object_scales.gd;
## as arvores antigas mantem a proporcao da floresta ja aprovada.

const Scales = preload("res://scripts/world_object_scales.gd")
const ObjectFactory = preload("res://scripts/world_object_factory.gd")
const Harvestable = preload("res://scripts/harvestable_resource.gd")
const FarmPlot = preload("res://scripts/clearing_farm_plot.gd")

const TILE: int = 32
const MAP_COLUMNS: int = 64
const MAP_ROWS: int = 42
const MIN_X: int = -32
const MIN_Y: int = -21
const VIEW_ZOOM: float = 1.0
const OVERVIEW_ZOOM: float = 0.65
const POND_CENTER: Vector2 = Vector2(-690.0, 285.0)
const POND_RADIUS: Vector2 = Vector2(264.0, 218.0)

# Godot atlas: corner bits TL=1, TR=2, BR=4, BL=8.
const CORNER_ATLAS = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
	Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1),
]

const OLD_TREES: Dictionary = {
	"oak_small": "res://sprites/objects/tree_oak_small_small_oak_tre/rotations/tree_oak_small_small_oak_tre.png",
	"oak_medium": "res://sprites/objects/tree_oak_medium_medium_oak_t/rotations/tree_oak_medium_medium_oak_t.png",
	"oak_large": "res://sprites/objects/tree_oak_large_large_mature/rotations/tree_oak_large_large_mature.png",
	"pine": "res://sprites/objects/tree_pine_tall_evergreen_pin/rotations/tree_pine_tall_evergreen_pin.png",
}

@export var generate_on_start: bool = true
@export var allow_collisions: bool = true
@export var enable_decorations: bool = true
@export_range(30, 180, 1) var decoration_count: int = 125

@onready var ground: TileMapLayer = $Ground
@onready var world: Node2D = $WorldObjects
@onready var player: CharacterBody2D = $WorldObjects/Player
@onready var camera: Camera2D = $WorldObjects/Player/Camera2D
@onready var help_label: Label = $HUD/HelpLabel

var _segments: Array[Dictionary] = []
var _object_folders: Array[String] = []
var _draw_road_pebbles: PackedVector2Array = PackedVector2Array()
var _wide_view: bool = false
var _legacy_index: int = 0
var _object_count: int = 0


func _ready() -> void:
	if not generate_on_start:
		return
	_register_roads()
	_scan_exported_objects()
	_paint_terrain()
	_prepare_road_details()
	_build_landmarks()
	_build_woods()
	if enable_decorations:
		_scatter_small_decorations()
	if allow_collisions:
		_build_pond_collision()
		_add_world_edges()
	_setup_camera()
	queue_redraw()
	print("Clareira Encantada: %d objetos montados." % _object_count)


func _register_roads() -> void:
	_segments.clear()
	_add_road([
		Vector2(118.0, -750.0), Vector2(124.0, -590.0),
		Vector2(40.0, -385.0), Vector2(78.0, -175.0),
		Vector2(5.0, 5.0), Vector2(100.0, 205.0),
		Vector2(56.0, 410.0), Vector2(40.0, 760.0)
	], 99.0)
	_add_road([
		Vector2(-110.0, 25.0), Vector2(92.0, 10.0),
		Vector2(305.0, -52.0), Vector2(555.0, -115.0),
		Vector2(780.0, -114.0), Vector2(1090.0, -225.0)
	], 86.0)
	_add_road([
		Vector2(5.0, 5.0), Vector2(-188.0, -38.0),
		Vector2(-350.0, -130.0), Vector2(-408.0, -142.0)
	], 48.0)


func _add_road(points: Array, width: float) -> void:
	for i in range(points.size() - 1):
		_segments.append({"a": points[i], "b": points[i + 1], "radius": width * 0.5})


func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var delta: Vector2 = b - a
	var distance_sq: float = delta.length_squared()
	if distance_sq < 0.001:
		return p.distance_to(a)
	var fraction: float = clampf((p - a).dot(delta) / distance_sq, 0.0, 1.0)
	return p.distance_to(a + delta * fraction)


func _is_road(p: Vector2) -> bool:
	var irregularity: float = sin(p.x * 0.037 + p.y * 0.014) * 4.0 + sin(p.y * 0.072) * 2.5
	for seg in _segments:
		var a: Vector2 = seg["a"]
		var b: Vector2 = seg["b"]
		var radius: float = seg["radius"]
		if _distance_to_segment(p, a, b) < radius + irregularity:
			return true
	return false


func _paint_terrain() -> void:
	ground.clear()
	for y in range(MIN_Y, MIN_Y + MAP_ROWS):
		for x in range(MIN_X, MIN_X + MAP_COLUMNS):
			var tl: bool = _is_road(Vector2(float(x * TILE), float(y * TILE)))
			var tr: bool = _is_road(Vector2(float((x + 1) * TILE), float(y * TILE)))
			var br: bool = _is_road(Vector2(float((x + 1) * TILE), float((y + 1) * TILE)))
			var bl: bool = _is_road(Vector2(float(x * TILE), float((y + 1) * TILE)))
			var mask: int = int(tl) + 2 * int(tr) + 4 * int(br) + 8 * int(bl)
			var atlas: Vector2i = CORNER_ATLAS[mask]
			# Variantes de grama / terra apenas nas regioes inteiras.
			var variation: int = absi(x * 17 + y * 31 + x * y * 5) % 13
			if mask == 0 and variation < 3:
				atlas = Vector2i(variation, 2)
			elif mask == 15 and variation < 3:
				atlas = Vector2i(4 + variation, 2)
			ground.set_cell(Vector2i(x, y), 0, atlas)


func _prepare_road_details() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 773923
	_draw_road_pebbles.clear()
	for i in range(1500):
		var pt := Vector2(rng.randf_range(-1010.0, 1010.0), rng.randf_range(-645.0, 645.0))
		if _is_road(pt):
			_draw_road_pebbles.append(pt)


func _scan_exported_objects() -> void:
	_object_folders.clear()
	var dir: DirAccess = DirAccess.open(Scales.ROOT)
	if dir == null:
		push_warning("Pasta da PixelLab nao encontrada: %s" % Scales.ROOT)
		return
	dir.list_dir_begin()
	while true:
		var folder: String = dir.get_next()
		if folder.is_empty():
			break
		if dir.current_is_dir() and not folder.begins_with("."):
			_object_folders.append(folder)
	dir.list_dir_end()
	_object_folders.sort()


func _find_object(prefix: String, variant: int = 0) -> String:
	var matches: Array[String] = []
	for folder in _object_folders:
		if folder.begins_with(prefix):
			matches.append(folder)
	if matches.is_empty():
		return ""
	return matches[posmod(variant, matches.size())]


func _place_export(prefix: String, pos: Vector2, solid: bool = false, variant: int = 0, scale_variation: float = 1.0) -> void:
	var folder: String = _find_object(prefix, variant)
	if folder.is_empty():
		push_warning("Sem sprite PixelLab para: " + prefix)
		return
	var node: Node2D = ObjectFactory.place(world, folder, pos, solid and allow_collisions, scale_variation)
	node.name = prefix + "_" + str(_object_count)
	_register_harvestable(node, prefix)
	_object_count += 1


func _place_cluster(prefix: String, positions: Array, solid: bool = false, start_variant: int = 0) -> void:
	for i in range(positions.size()):
		var pos: Vector2 = positions[i]
		_place_export(prefix, pos, solid, start_variant + i)


func _place_legacy_tree(kind: String, pos: Vector2, scale_factor: float) -> void:
	var path: String = String(OLD_TREES.get(kind, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		return
	var holder := Node2D.new()
	holder.name = "Tree_" + kind + "_" + str(_legacy_index)
	_legacy_index += 1
	holder.position = pos
	world.add_child(holder)
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-13.0, -2.0), Vector2(-8.0, -6.0), Vector2(8.0, -6.0),
		Vector2(13.0, -2.0), Vector2(8.0, 2.0), Vector2(-8.0, 2.0),
	])
	shadow.scale = Vector2.ONE * scale_factor
	shadow.color = Color(0.10, 0.15, 0.07, 0.19)
	holder.add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Scales.anchor_offset(texture)
	sprite.scale = Vector2.ONE * scale_factor
	holder.add_child(sprite)
	if allow_collisions:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		holder.add_child(body)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 11.0 * scale_factor
		shape.shape = circle
		shape.position = Vector2(0.0, -7.0 * scale_factor)
		body.add_child(shape)
	if kind == "oak_small":
		_attach_harvestable(holder, "machado", "madeira", 4, 3, "Arvore")
	_object_count += 1


func _build_landmarks() -> void:
	# Horta de quatro canteiros, cerca, barril, caixa e mudas.
	var fence_id: String = _find_object("wooden_fence_single")
	if not fence_id.is_empty():
		for x in range(-722, -438, 34):
			_place_export("wooden_fence_single", Vector2(float(x), -290.0))
		for y in range(-260, -80, 30):
			_place_export("wooden_fence_single", Vector2(-730.0, float(y)))
		for x in range(-710, -610, 34):
			_place_export("wooden_fence_single", Vector2(float(x), -60.0))
		for x in range(-514, -440, 34):
			_place_export("wooden_fence_single", Vector2(float(x), -60.0))
	_place_export("storage_crate_sturdy", Vector2(-695.0, -220.0), true, 2)
	_place_export("wooden_barrel_detailed", Vector2(-702.0, -87.0), true, 3)
	_build_interactive_farm()

	# Objetos narrativos: placas, troncos caidos, tocos, pedras e saidas.
	_place_export("wooden_sign_small", Vector2(460.0, -210.0), false, 4)
	_place_cluster("fallen_log", [
		Vector2(295.0, 225.0), Vector2(-280.0, 470.0)
	])
	_place_cluster("tree_stump_small", [
		Vector2(255.0, -340.0), Vector2(542.0, 345.0),
		Vector2(-120.0, -335.0)
	], false)
	_place_cluster("rock_large", [
		Vector2(752.0, 50.0), Vector2(420.0, -500.0),
		Vector2(-868.0, -90.0)
	], true, 2)
	_place_cluster("rock_small", [
		Vector2(-350.0, -520.0), Vector2(265.0, -580.0),
		Vector2(820.0, -290.0), Vector2(-200.0, 510.0)
	], true, 5)

	# Ponto de pesca na margem do lago. A doca e desenhada sobre a agua.
	_place_export("wooden_bridge", Vector2(-506.0, 355.0), false, 6)


func _build_woods() -> void:
	# Moldura de floresta densa; os caminhos centrais ficam transitaveis.
	_place_legacy_tree("oak_large", Vector2(-855.0, -470.0), 1.55)
	_place_legacy_tree("oak_large", Vector2(-425.0, -575.0), 1.55)
	_place_legacy_tree("oak_large", Vector2(615.0, -535.0), 1.55)
	_place_legacy_tree("oak_large", Vector2(905.0, -400.0), 1.55)
	_place_legacy_tree("oak_large", Vector2(785.0, 545.0), 1.55)
	_place_legacy_tree("oak_large", Vector2(-830.0, 600.0), 1.55)
	_place_legacy_tree("oak_medium", Vector2(-185.0, 415.0), 1.27)
	_place_legacy_tree("oak_medium", Vector2(585.0, 492.0), 1.30)
	_place_legacy_tree("oak_medium", Vector2(915.0, 140.0), 1.25)
	_place_legacy_tree("oak_small", Vector2(-520.0, -480.0), 1.02)
	_place_legacy_tree("oak_small", Vector2(-960.0, -10.0), 1.00)
	_place_legacy_tree("pine", Vector2(-930.0, -260.0), 1.38)
	_place_legacy_tree("pine", Vector2(735.0, -605.0), 1.35)
	_place_legacy_tree("pine", Vector2(960.0, 450.0), 1.32)
	_place_legacy_tree("pine", Vector2(-110.0, -640.0), 1.27)

	_place_cluster("fruit_tree_detailed", [
		Vector2(-910.0, -150.0), Vector2(-505.0, -385.0),
		Vector2(950.0, -585.0), Vector2(775.0, 270.0)
	], true, 4)
	_place_cluster("bush_large", [
		Vector2(-620.0, -435.0), Vector2(-185.0, -255.0),
		Vector2(345.0, -425.0), Vector2(575.0, -385.0),
		Vector2(700.0, 365.0), Vector2(-145.0, 585.0)
	], false, 1)
	_place_cluster("bush_small", [
		Vector2(-320.0, -295.0), Vector2(215.0, -330.0),
		Vector2(625.0, 90.0), Vector2(-390.0, 250.0),
		Vector2(360.0, 435.0)
	])
	_place_cluster("wildflowers_small", [
		Vector2(-530.0, -450.0), Vector2(-390.0, -275.0),
		Vector2(240.0, -275.0), Vector2(580.0, -260.0),
		Vector2(590.0, 80.0), Vector2(225.0, 315.0),
		Vector2(-125.0, 300.0), Vector2(720.0, 455.0),
		Vector2(-450.0, 490.0)
	], false, 4)


func _scatter_small_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261023
	for i in range(decoration_count):
		var pos: Vector2 = Vector2(
			rng.randf_range(-980.0, 980.0),
			rng.randf_range(-620.0, 620.0)
		)
		if _is_road(pos) or _inside_water(pos, 1.27):
			continue
		if pos.x > -780.0 and pos.x < -390.0 and pos.y > -335.0 and pos.y < -35.0:
			continue
		if pos.distance_to(Vector2(0.0, 40.0)) < 110.0:
			continue
		var choice: int = rng.randi_range(0, 11)
		if choice < 5:
			_place_export("tall_grass", pos, false, i)
		elif choice < 8:
			_place_export("wildflowers_small", pos, false, i)
		elif choice < 10:
			_place_export("rock_small", pos, false, i)
		else:
			_place_export("mushroom_cluster", pos, false, i)


func _inside_water(p: Vector2, radius_factor: float = 1.0) -> bool:
	var dx: float = (p.x - POND_CENTER.x) / (POND_RADIUS.x * radius_factor)
	var dy: float = (p.y - POND_CENTER.y) / (POND_RADIUS.y * radius_factor)
	return dx * dx + dy * dy <= 1.0


func _ellipse(center: Vector2, radius: Vector2, steps: int = 48, jitter: float = 0.0) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(steps):
		var angle: float = float(i) * TAU / float(steps)
		var wobble: float = 1.0 + sin(float(i) * 2.7) * jitter
		var point: Vector2 = center + Vector2(cos(angle) * radius.x * wobble, sin(angle) * radius.y * wobble)
		result.append(Vector2(roundf(point.x / 4.0) * 4.0, roundf(point.y / 4.0) * 4.0))
	return result


func _draw() -> void:
	_draw_pond()
	_draw_cliff()
	_draw_dock()
	for pebble in _draw_road_pebbles:
		draw_rect(Rect2(pebble, Vector2(3.0, 2.0)), Color(0.35, 0.30, 0.17, 0.18), true)


func _draw_pond() -> void:
	var shore: PackedVector2Array = _ellipse(POND_CENTER, POND_RADIUS + Vector2(28.0, 25.0), 56, 0.027)
	var border: PackedVector2Array = _ellipse(POND_CENTER, POND_RADIUS + Vector2(10.0, 12.0), 56, 0.028)
	var water: PackedVector2Array = _ellipse(POND_CENTER, POND_RADIUS, 56, 0.028)
	draw_colored_polygon(shore, Color("#7b8747"))
	draw_colored_polygon(border, Color("#6c7940"))
	draw_colored_polygon(water, Color("#286e82"))
	draw_colored_polygon(_ellipse(POND_CENTER + Vector2(-30.0, 24.0), POND_RADIUS * 0.77, 48, 0.026), Color("#2d7e90"))
	draw_colored_polygon(_ellipse(POND_CENTER + Vector2(-37.0, 37.0), POND_RADIUS * 0.53, 48, 0.035), Color("#378a94"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 75512
	for i in range(86):
		var p := Vector2(
			rng.randf_range(POND_CENTER.x - POND_RADIUS.x, POND_CENTER.x + POND_RADIUS.x),
			rng.randf_range(POND_CENTER.y - POND_RADIUS.y, POND_CENTER.y + POND_RADIUS.y)
		)
		if not _inside_water(p, 0.89):
			continue
		if i % 6 == 0:
			draw_circle(p, 5.0, Color("#6fa74a"))
			draw_circle(p + Vector2(2.0, -1.0), 2.0, Color("#9cc26a"))
		else:
			draw_line(p, p + Vector2(float(i % 3 + 3), 0.0), Color("#72aeb0"), 1.0)
	# Tufos de junco na orla para integrar visualmente a agua ao gramado.
	for i in range(32):
		var a: float = float(i) * TAU / 32.0
		var base := POND_CENTER + Vector2(cos(a) * POND_RADIUS.x, sin(a) * POND_RADIUS.y)
		if base.x > -510.0 and base.y > 240.0 and base.y < 405.0:
			continue
		for j in range(3):
			var origin := base + Vector2(float(j * 5), 0.0)
			draw_line(origin, origin + Vector2(float(j - 1) * 4.0, -float(12 + (i + j) % 12)), Color("#3f7742"), 2.0)
			if j == 1 and i % 3 == 0:
				draw_rect(Rect2(origin + Vector2(-4.0, -21.0), Vector2(3.0, 8.0)), Color("#947848"))


func _draw_cliff() -> void:
	# Canteiro elevado e afloramento no canto superior direito.
	var earth := PackedVector2Array([
		Vector2(690.0, -630.0), Vector2(980.0, -630.0),
		Vector2(980.0, -375.0), Vector2(925.0, -375.0),
		Vector2(925.0, -332.0), Vector2(750.0, -332.0),
		Vector2(750.0, -378.0), Vector2(690.0, -378.0)
	])
	draw_colored_polygon(earth, Color("#70523a"))
	for i in range(12):
		var x: float = 750.0 + float(i % 6) * 33.0
		var y: float = -370.0 + float(i / 6) * 26.0
		draw_line(Vector2(x, y), Vector2(x + 14.0, y + 2.0), Color("#4e3b30"), 3.0)
	var grass_top := PackedVector2Array([
		Vector2(692.0, -640.0), Vector2(990.0, -640.0),
		Vector2(990.0, -407.0), Vector2(908.0, -407.0),
		Vector2(908.0, -375.0), Vector2(778.0, -375.0),
		Vector2(778.0, -409.0), Vector2(692.0, -409.0)
	])
	draw_colored_polygon(grass_top, Color("#668740"))
	draw_polyline(grass_top, Color("#98a95d"), 5.0)


func _draw_farm_beds() -> void:
	var garden: Array[Vector2] = [
		Vector2(-620.0, -215.0), Vector2(-556.0, -215.0),
		Vector2(-620.0, -152.0), Vector2(-556.0, -152.0)
	]
	for plot_center in garden:
		var area := Rect2(plot_center - Vector2(27.0, 21.0), Vector2(54.0, 42.0))
		draw_rect(area.grow(4.0), Color("#657639"))
		draw_rect(area, Color("#66472e"))
		draw_rect(area.grow(-3.0), Color("#806040"), false, 2.0)
		for i in range(5):
			var px: float = area.position.x + 7.0 + float(i * 9)
			var py: float = area.position.y + 9.0 + float(i % 3) * 8.0
			draw_rect(Rect2(px, py, 5.0, 2.0), Color("#9b7146"))


func _draw_dock() -> void:
	var deck := Rect2(-584.0, 305.0, 134.0, 46.0)
	draw_rect(deck.grow(5.0), Color("#3b2b24"))
	draw_rect(deck, Color("#8a5935"))
	for i in range(8):
		var x: float = -581.0 + float(i * 17)
		draw_line(Vector2(x, 310.0), Vector2(x, 346.0), Color("#b47b4c"), 3.0)
		draw_line(Vector2(x + 4.0, 309.0), Vector2(x + 4.0, 347.0), Color("#5b3e2b"), 1.0)
	for p in [Vector2(-575.0, 306.0), Vector2(-575.0, 353.0), Vector2(-459.0, 306.0), Vector2(-459.0, 353.0)]:
		draw_rect(Rect2(p - Vector2(5.0, 8.0), Vector2(10.0, 20.0)), Color("#68462e"))
		draw_rect(Rect2(p - Vector2(4.0, 8.0), Vector2(8.0, 5.0)), Color("#bd8b58"))


func _build_pond_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "PondCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var collision := CollisionPolygon2D.new()
	collision.polygon = _ellipse(POND_CENTER, POND_RADIUS * 0.94, 32)
	body.add_child(collision)


func _add_world_edges() -> void:
	var bounds := Rect2(float(MIN_X * TILE), float(MIN_Y * TILE),
		float(MAP_COLUMNS * TILE), float(MAP_ROWS * TILE))
	_add_wall(Vector2(bounds.position.x - 15.0, bounds.get_center().y), Vector2(30.0, bounds.size.y + 80.0))
	_add_wall(Vector2(bounds.end.x + 15.0, bounds.get_center().y), Vector2(30.0, bounds.size.y + 80.0))
	_add_wall(Vector2(bounds.get_center().x, bounds.position.y - 15.0), Vector2(bounds.size.x + 80.0, 30.0))
	_add_wall(Vector2(bounds.get_center().x, bounds.end.y + 15.0), Vector2(bounds.size.x + 80.0, 30.0))


func _add_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	add_child(body)
	var hitbox := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	hitbox.shape = box
	body.add_child(hitbox)


func _setup_camera() -> void:
	camera.enabled = true
	camera.zoom = Vector2.ONE * VIEW_ZOOM
	camera.limit_left = MIN_X * TILE
	camera.limit_top = MIN_Y * TILE
	camera.limit_right = (MIN_X + MAP_COLUMNS) * TILE
	camera.limit_bottom = (MIN_Y + MAP_ROWS) * TILE
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.make_current()
	camera.reset_smoothing()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_TAB:
		_wide_view = not _wide_view
		camera.zoom = Vector2.ONE * (OVERVIEW_ZOOM if _wide_view else VIEW_ZOOM)
		_update_help()
	elif key.physical_keycode == KEY_F1:
		_jump_to(Vector2(0.0, 40.0))
	elif key.physical_keycode == KEY_F2:
		_jump_to(Vector2(-330.0, -126.0))
	elif key.physical_keycode == KEY_F3:
		_jump_to(Vector2(-350.0, 340.0))
	elif key.physical_keycode == KEY_F4:
		_jump_to(Vector2(640.0, -120.0))


func _jump_to(destination: Vector2) -> void:
	player.global_position = destination
	player.velocity = Vector2.ZERO
	camera.reset_smoothing()


func _update_help() -> void:
	help_label.text = "CLAREIRA ENCANTADA | WASD/SETAS mover | SHIFT correr | ESPACO dash | TAB: "
	help_label.text += "voltar ao zoom normal" if _wide_view else "visao geral"
	help_label.text += "\n1-4 ferramentas | F usar | E interagir | I mochila | F1-F4 viagem"


## Recursos disponiveis para coleta na floresta.
func _register_harvestable(target: Node2D, prefix: String) -> void:
	if prefix.begins_with("fallen_log"):
		_attach_harvestable(target, "machado", "madeira", 3, 2, "Tronco")
	elif prefix.begins_with("tree_stump"):
		_attach_harvestable(target, "machado", "madeira", 2, 2, "Toco")
	elif prefix.begins_with("rock_large"):
		_attach_harvestable(target, "picareta", "pedra", 3, 3, "Pedra grande")
	elif prefix.begins_with("rock_small"):
		_attach_harvestable(target, "picareta", "pedra", 1, 2, "Pedra")
	elif prefix.begins_with("bush_small"):
		_attach_harvestable(target, "mao", "fibra", 2, 1, "Arbusto")
	elif prefix.begins_with("mushroom_cluster"):
		_attach_harvestable(target, "mao", "cogumelos", 1, 1, "Cogumelos")


func _attach_harvestable(target: Node2D, tool_id: String, reward: String, amount: int, hits: int, title: String) -> void:
	var component: Node = Harvestable.new()
	component.call("configure", tool_id, reward, amount, hits, title)
	component.name = "RecursoColetavel"
	target.add_child(component)


func _build_interactive_farm() -> void:
	var beds: Array[Vector2] = [
		Vector2(-620.0, -215.0), Vector2(-556.0, -215.0),
		Vector2(-620.0, -152.0), Vector2(-556.0, -152.0)
	]
	var states: Array[int] = [0, 1, 2, 4]
	for i in range(beds.size()):
		var plot: Node2D = FarmPlot.new() as Node2D
		plot.name = "Canteiro_%d" % (i + 1)
		plot.position = beds[i]
		plot.z_index = -1
		plot.set("initial_state", states[i])
		world.add_child(plot)

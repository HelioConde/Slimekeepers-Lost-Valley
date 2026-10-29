extends Node2D
## Individual original sprites, integer scaling and feet aligned to contact shadows.
@export var reduce_motion := false
const ENV := "res://assets/menu/environment/"
const PACK := "res://assets/menu/provided/"
const PACK_REPLACEMENTS := {"cottage":"cottage"}
var _actors: Array[Dictionary] = []
var _time := 0.0
var _butterflies: Array[Dictionary] = []
var _props: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_ground()
	_props = Node2D.new()
	_props.name = "Objects"
	_props.y_sort_enabled = true
	add_child(_props)
	# Back of the garden and cottage sit on the same terrace.
	_prop("oak_medium", Vector2(76, 494), 3)
	_pack_prop("tree_large",Vector2(430,492),1)
	_pack_prop("tree_medium",Vector2(504,501),1)
	_pack_prop("bush",Vector2(490,526),1)
	_pack_prop("scarecrow",Vector2(742,557),1)
	for foot in [Vector2(558,548),Vector2(746,564)]:
		_pack_prop("fence",foot,1)
	_prop("cottage", Vector2(252, 552), 1)
	_pack_prop("wood_barrel", Vector2(124,556),1)
	_pack_prop("orange_flowers",Vector2(100,570),1)
	_pack_prop("bench",Vector2(146,623),1)
	_prop("lantern", Vector2(392, 541), 1)
	for foot in [Vector2(95,568), Vector2(152,585), Vector2(370,562), Vector2(408,548), Vector2(830,612), Vector2(794,632)]:
		_prop("flowers", foot, 1)
	for foot in [Vector2(92,600),Vector2(192,616),Vector2(226,646),Vector2(742,656),Vector2(878,654)]:
		_prop("grass", foot, 2)
	# Individually placed planting beds follow the terrace, leaving a continuous path.
	_pack_prop("seedlings",Vector2(374,646),1)
	_pack_prop("sprouts",Vector2(478,649),1)
	_pack_prop("vegetables",Vector2(584,652),1)
	_pack_prop("flower_box",Vector2(150,570),1)
	_pack_prop("pink_flowers",Vector2(396,557),1)
	_pack_prop("sunflowers",Vector2(854,637),1)
	_prop_texture(load("res://assets/player/rotations/south-east.png"), Vector2(448, 576), 1)
	_slime("gelito", Vector2(280, 633), 0.0)
	_slime("brotinho", Vector2(680, 654), 2.3)
	_slime("brasinha", Vector2(794, 608), 4.6)
	_pack_prop("wood_barrel", Vector2(738,608),1)
	_pack_prop("stump",Vector2(94,681),1)
	for foot in [Vector2(410,523),Vector2(560,551),Vector2(637,558),Vector2(822,579)]:
		_pack_prop("bush",foot,1)
	for foot in [Vector2(170,588),Vector2(702,566),Vector2(888,668),Vector2(182,696)]:
		_pack_prop("bush",foot,1)
	for foot in [Vector2(870,628),Vector2(850,686),Vector2(98,662),Vector2(218,694),Vector2(754,708)]:
		_prop("stone", foot, 1)
	# Frame the vista with branches, not four isolated corner trees.
	_prop("oak", Vector2(-12, 362), 4)
	_prop("oak_medium", Vector2(1268, 328), 3)
	_prop("oak_medium", Vector2(24, 866), 3)
	_prop("oak_medium", Vector2(1236, 858), 3)
	for foot in [Vector2(112,712), Vector2(182,742), Vector2(864,748), Vector2(1116,734)]:
		_prop("flowers", foot, 2)
	var blooms := GardenFlowers.new()
	add_child(blooms)
	for at in [Vector2(193,552),Vector2(837,576)]:
		var butterfly := Sprite2D.new()
		butterfly.texture = load(PACK+"butterfly.png")
		butterfly.scale = Vector2(0.5,0.5)
		butterfly.position = at
		add_child(butterfly)
		_butterflies.append({"sprite":butterfly,"origin":at,"phase":float(_butterflies.size())*2.8})

func _build_ground() -> void:
	var terrace := PackedVector2Array([Vector2(-180,450),Vector2(80,458),Vector2(222,486),Vector2(388,482),Vector2(548,510),Vector2(710,530),Vector2(890,562),Vector2(1080,548),Vector2(1460,520),Vector2(1460,820),Vector2(-180,820)])
	_surface(terrace,Color("#869e50"),Vector2(0,0),0.76)
	var main_path := Curve2D.new()
	main_path.bake_interval = 8
	main_path.add_point(Vector2(247,531),Vector2.ZERO,Vector2(0,27))
	main_path.add_point(Vector2(315,583),Vector2(-34,-12),Vector2(45,12))
	main_path.add_point(Vector2(456,663),Vector2(-54,-31),Vector2(75,29))
	main_path.add_point(Vector2(736,768),Vector2(-85,-27),Vector2.ZERO)
	_surface(_ribbon(main_path,20,45),Color("#7e794b"))
	_surface(_ribbon(main_path,16,40),Color("#cdb37b"),Vector2(224,32),0.52)
	var garden_path := Curve2D.new()
	garden_path.bake_interval = 8
	garden_path.add_point(Vector2(339,595),Vector2.ZERO,Vector2(68,-10))
	garden_path.add_point(Vector2(620,575),Vector2(-80,0),Vector2(80,0))
	garden_path.add_point(Vector2(945,626),Vector2(-94,-30),Vector2(108,32))
	garden_path.add_point(Vector2(1420,766),Vector2(-160,-34),Vector2.ZERO)
	_surface(_ribbon(garden_path,17,26),Color("#7e794b"))
	_surface(_ribbon(garden_path,14,23),Color("#cdb37b"),Vector2(224,32),0.52)
	var bench_path := Curve2D.new()
	bench_path.bake_interval = 8
	bench_path.add_point(Vector2(267,568),Vector2.ZERO,Vector2(-20,25))
	bench_path.add_point(Vector2(152,626),Vector2(28,-3),Vector2.ZERO)
	_surface(_ribbon(bench_path,11,15),Color("#cdb37b"),Vector2(224,32),0.52)

func _surface(points: PackedVector2Array, color: Color, tile_origin: Vector2 = Vector2(-1,-1), strength: float = 0.0) -> void:
	var surface := Polygon2D.new()
	surface.polygon = points
	surface.color = color
	if tile_origin.x >= 0:
		var material_ := ShaderMaterial.new()
		material_.shader = preload("res://scripts/menu/terrain_surface.gdshader")
		material_.set_shader_parameter("terrain_atlas",preload("res://assets/tilesets/grass_dirt_v3_32x32.png"))
		material_.set_shader_parameter("atlas_origin",tile_origin)
		material_.set_shader_parameter("texture_strength",strength)
		surface.material = material_
	add_child(surface)

func _ribbon(curve: Curve2D, start_width: float, end_width: float) -> PackedVector2Array:
	var center := curve.get_baked_points()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in range(center.size()):
		var tangent := (center[mini(i+1,center.size()-1)]-center[maxi(i-1,0)]).normalized()
		var normal := tangent.orthogonal()
		var width := lerpf(start_width,end_width,float(i)/maxi(center.size()-1,1))+sin(i*0.9)*1.5
		left.append((center[i]+normal*width).snapped(Vector2(2,2)))
		right.append((center[i]-normal*width).snapped(Vector2(2,2)))
	right.reverse()
	left.append_array(right)
	return left

func _prop(name_: String, foot: Vector2, factor: int) -> Sprite2D:
	if PACK_REPLACEMENTS.has(name_):
		return _pack_prop(PACK_REPLACEMENTS[name_],foot,factor)
	return _prop_texture(load(ENV + name_ + ".png") as Texture2D, foot, factor)

func _pack_prop(name_: String, foot: Vector2, factor: int) -> Sprite2D:
	return _prop_texture(load(PACK+name_+".png") as Texture2D,foot,factor)

func _prop_texture(texture: Texture2D, foot: Vector2, factor: int) -> Sprite2D:
	var rect := texture.get_image().get_used_rect()
	var placement := Node2D.new()
	placement.position = foot.round()
	_props.add_child(placement)
	var shadow := Polygon2D.new()
	var radius := minf(rect.size.x * factor * 0.38, 100)
	shadow.polygon = PackedVector2Array([Vector2(-radius,0),Vector2(-radius+8,-6),Vector2(radius-8,-6),Vector2(radius,0),Vector2(radius-8,6),Vector2(-radius+8,6)])
	shadow.color = Color(0.12,0.22,0.17,0.25)
	placement.add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = Vector2.ONE * factor
	sprite.position = (-Vector2(rect.get_center().x, rect.end.y) * factor).round()
	placement.add_child(sprite)
	return sprite

func _slime(kind: String, foot: Vector2, phase: float) -> void:
	var placement := Node2D.new()
	placement.position = foot.round()
	_props.add_child(placement)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = load("res://assets/slimes/bestiary/%s/%s_frames.tres" % [kind,kind]) as SpriteFrames
	var frame := sprite.sprite_frames.get_frame_texture("idle",0)
	var bounds := frame.get_image().get_used_rect()
	sprite.centered = false
	sprite.scale = Vector2(2,2)
	var base := (-Vector2(bounds.get_center().x,bounds.end.y)*2).round()
	sprite.position = base
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-30,0),Vector2(-22,-6),Vector2(22,-6),Vector2(30,0),Vector2(22,6),Vector2(-22,6)])
	shadow.color = Color(0.12,0.22,0.17,0.36)
	placement.add_child(shadow)
	placement.add_child(sprite)
	sprite.play("idle")
	_actors.append({"sprite":sprite,"base":base,"shadow":shadow,"phase":phase})

func _process(delta: float) -> void:
	if not reduce_motion: _time += delta
	for butterfly in _butterflies:
		var phase := _time * 0.8 + float(butterfly.phase)
		butterfly.sprite.position = (butterfly.origin+Vector2(sin(phase)*12,sin(phase*1.7)*6)).round()
	for actor in _actors:
		var sprite := actor.sprite as AnimatedSprite2D
		sprite.speed_scale = 0.0 if reduce_motion else 1.0
		var cycle := fmod(_time + float(actor.phase), 7.0)
		var hop := sin(cycle / 0.6 * PI) * 9.0 if cycle < 0.6 and not reduce_motion else 0.0
		sprite.position = actor.base - Vector2(0,round(hop))
		(actor.shadow as Polygon2D).modulate.a = 1.0 - hop / 30.0

class GardenFlowers extends Node2D:
	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 571
		for center in [Vector2(206,552),Vector2(152,625),Vector2(388,578),Vector2(744,656),Vector2(870,616),Vector2(1110,652)]:
			for i in range(7):
				var point: Vector2 = (center+Vector2(rng.randi_range(-25,25),rng.randi_range(-10,12))).snapped(Vector2(2,2))
				draw_rect(Rect2(point+Vector2(0,-12),Vector2(2,12)),Color("#405e35"))
				draw_rect(Rect2(point+Vector2(-4,-5),Vector2(8,2)),Color("#759a42"))
				var petals := Color("#fff0c6") if i%3 else Color("#e8a186")
				draw_rect(Rect2(point+Vector2(-4,-14),Vector2(10,4)),petals)
				draw_rect(Rect2(point+Vector2(-2,-16),Vector2(6,8)),petals)
				draw_rect(Rect2(point+Vector2(0,-13),Vector2(2,2)),Color("#d4a34f"))

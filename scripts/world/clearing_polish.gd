extends RefCounted
## Incremental, repeatable art pass. Keeps all authored trees, solids and markers.
const Layout = preload("res://scripts/world/clearing_layout.gd")
const ENV := "res://assets/menu/environment/"
const FOREST := "res://assets/world/forest/"
var _scene: Node2D
var _rng := RandomNumberGenerator.new()
var _cache: Dictionary = {}

func apply(scene: Node2D) -> void:
	_scene = scene
	_rng.seed = 26102607
	var existing := scene.get_node_or_null("WoodlandDetails")
	if existing != null:
		scene.remove_child(existing)
		existing.free()
	var group := Node2D.new()
	group.name = "WoodlandDetails"
	group.z_index = -4
	_add(scene, group)
	var ground_material := ShaderMaterial.new()
	ground_material.shader = load("res://scripts/world/forest_ground.gdshader")
	scene.get_node("Ground").material = ground_material
	for parent_name in ["ForestFloor", "NaturalTrails"]:
		for surface: Polygon2D in scene.get_node(parent_name).get_children():
			var mat := surface.material.duplicate() as ShaderMaterial
			mat.shader = load("res://scripts/world/forest_surface.gdshader")
			surface.material = mat
	var low := scene.get_node("VegetationLow") as TileMapLayer
	# Deliberate clusters replace regularly spaced tall tufts in the opening view.
	for cell in low.get_used_cells():
		if Layout.inside_clearing(low.map_to_local(cell), -25):
			low.erase_cell(cell)
	var flower_beds := [Vector2(1370,1495),Vector2(1390,1760),Vector2(1805,1700),Vector2(1740,1400),Vector2(1325,1610),Vector2(1735,1840)]
	for i in flower_beds.size():
		var centre: Vector2 = flower_beds[i]
		for j in 8:
			var at := centre + Vector2(_rng.randf_range(-42,42),_rng.randf_range(-20,24))
			if _actor_space(at):
				continue
			var path := ENV + "flowers.png" if j < 5 else FOREST + "fern.png"
			var sprite := _sprite(group,path,at)
			if j < 5 and sprite != null:
				sprite.modulate = [Color.WHITE,Color(1.08,1.02,0.72),Color(0.70,0.91,1.2)][i % 3]
	# A few low tufts keep the spawn open while avoiding a perfectly bare disk.
	for at in [Vector2(1500,1500),Vector2(1690,1635),Vector2(1510,1720),Vector2(1750,1550),Vector2(1440,1685)]:
		_sprite(group,ENV+"grass.png",at)
	# Individual mushrooms sit beside the planted borders, never on actors.
	for entry in [[Vector2(1352,1553),"mushroom_red.png"],[Vector2(1380,1559),"mushroom_brown.png"],[Vector2(1790,1738),"mushroom_red.png"],[Vector2(1823,1728),"mushroom_brown.png"],[Vector2(1730,1435),"mushroom_glow.png"]]:
		_sprite(group,FOREST+entry[1],entry[0])
	# Each side grove now has its own plant palette; the middle remains walkable.
	for i in Layout.POCKETS.size():
		var centre: Vector2 = Layout.POCKETS[i]
		var count := 11 if i == 0 else 14
		for j in count:
			var angle := TAU*j/float(count)+_rng.randf_range(-0.12,0.12)
			var at := centre + Vector2(cos(angle)*_rng.randf_range(70,105),sin(angle)*_rng.randf_range(50,85))
			var files := ["mushroom_glow.png","fern.png","mushroom_brown.png"]
			_sprite(group,FOREST+files[i],at)
	# Small tufts soften the smooth trail edges; the open corridor stays visible.
	for curve: Curve2D in Layout.trails().values():
		var length := curve.get_baked_length()
		for j in range(5,int(length/38.0)):
			if _rng.randf()<0.24:
				continue
			var offset := j*38.0+_rng.randf_range(-12,12)
			var at := curve.sample_baked(offset)
			if Layout.inside_clearing(at,20):
				continue
			var direction := (curve.sample_baked(offset+3)-curve.sample_baked(offset-3)).normalized()
			var side := -1.0 if _rng.randf()<0.5 else 1.0
			at += Vector2(-direction.y,direction.x)*side*_rng.randf_range(39,52)
			_sprite(group,ENV+"grass.png" if j%4!=0 else FOREST+"fern.png",at)
	var camera: Camera2D = scene.get_node("Player/Camera2D")
	camera.limit_right = 3200
	camera.limit_bottom = 3200

func _actor_space(at: Vector2) -> bool:
	if at.distance_to(Layout.SPAWN)<95:
		return true
	for position in Layout.SLIME_POSITIONS:
		if at.distance_to(position)<55:
			return true
	return false

func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _scene

func _sprite(parent: Node, path: String, at: Vector2) -> Sprite2D:
	if _scene.has_node("AwakeningLandmark") and at.distance_to(_scene.get_node("AwakeningLandmark").position)<85:
		return null
	if _scene.has_node("NaturalSpring") and preload("res://scripts/world/spring_builder.gd").PATCH.has_point(at):
		return null
	if not _cache.has(path):
		var tex: Texture2D = load(path)
		_cache[path] = [tex,tex.get_image().get_used_rect()]
	var sprite := Sprite2D.new()
	sprite.texture = _cache[path][0]
	var rect: Rect2i = _cache[path][1]
	sprite.position = at.round()
	sprite.offset = sprite.texture.get_size()*0.5-Vector2(rect.position.x+rect.size.x*0.5,rect.end.y)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_add(parent,sprite)
	return sprite

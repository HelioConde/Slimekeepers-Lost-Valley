extends RefCounted
## Incremental art direction pass; versioned so existing map edits are not rebuilt.
const Layout = preload("res://scripts/world/clearing_layout.gd")
const ENV := "res://assets/menu/environment/"
const FOREST := "res://assets/world/forest/"
const HIDDEN_GROVES := [Vector2(1200,2060),Vector2(1900,950)]
const LANDMARK := Vector2(1430,1560)
var root: Node2D
var paths: Dictionary
var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()

func apply(scene: Node2D) -> void:
	if scene.get_meta("composition_refinement",0) >= 3:
		return
	if scene.get_meta("composition_refinement",0) >= 1:
		scene.get_node("AwakeningLandmark").position = LANDMARK
		_clear_vistas(scene)
		scene.set_meta("composition_refinement",3)
		return
	root = scene
	paths = Layout.trails()
	rng.seed = 26102619
	noise.seed = 26102619
	noise.frequency = 0.005
	_thin_forest()
	_natural_paths()
	_clear_path_details()
	_canopy_shadows()
	_landmark()
	_grove_details()
	_clear_vistas(scene)
	scene.set_meta("composition_refinement",3)
	print("COMPOSITION trees=",scene.get_node("VegetationHigh").get_child_count()," trails=",paths.size())

func _add(parent: Node,child: Node) -> void:
	parent.add_child(child)
	child.owner = root

func _clear_vistas(scene: Node2D) -> void:
	# Physics clearance is not enough: tall foreground crowns must also leave the
	# discovery point visible at the player's standing/head height.
	var trees: Node2D = scene.get_node("VegetationHigh")
	for tree: Node2D in trees.get_children():
		var sprite: Sprite2D = tree.get_node("Sprite")
		var canopy: Rect2 = sprite.transform * sprite.get_rect()
		canopy.position += tree.position
		var masks_actor := false
		for centre in HIDDEN_GROVES:
			if tree.position.y>centre.y+12 and canopy.intersects(Rect2(centre-Vector2(38,80),Vector2(76,88))):
				masks_actor = true
		if masks_actor:
			for shadow: Node2D in scene.get_node("CanopyShade").get_children():
				if shadow.position.distance_to(tree.position+Vector2(12,0))<1:
					shadow.get_parent().remove_child(shadow)
					shadow.free()
			trees.remove_child(tree)
			tree.free()

func _group(label: String,depth: int = 0) -> Node2D:
	var group := Node2D.new()
	group.name = label
	group.z_index = depth
	_add(root,group)
	return group

func _extra_distance(at: Vector2) -> float:
	return minf(at.distance_to(paths["LogHollow"].get_closest_point(at)),at.distance_to(paths["BlueFernNook"].get_closest_point(at)))

func _thin_forest() -> void:
	var trees: Node2D = root.get_node("VegetationHigh")
	var candidates: Array[Dictionary] = []
	for tree: Node2D in trees.get_children():
		var at := tree.position
		var opening := 0.0
		for centre in Layout.POCKETS + HIDDEN_GROVES:
			var distance: float = ((at-centre)/Vector2(195,150)).length()
			opening = maxf(opening,maxf(0,1.0-distance)*2.0)
		var score := noise.get_noise_2dv(at)+opening
		var forced := _extra_distance(at)<65 or _extra_distance(at-Vector2(0,70))<35
		if forced:
			score += 10
		# Preserve the outer silhouette while opening connected areas in the interior.
		if at.x<100 or at.x>3100 or at.y<100 or at.y>3100:
			score -= 4
		candidates.append({"node":tree,"score":score})
	candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.score>b.score)
	var remove_count := maxi(0,trees.get_child_count()-950)
	for i in candidates.size():
		if i<remove_count or candidates[i].score>9:
			var tree: Node = candidates[i].node
			trees.remove_child(tree)
			tree.free()
	# Relocate existing low obstacles bordering the two new short side trails.
	for prop: Node2D in root.get_node("Decorations").get_children():
		if _extra_distance(prop.position)<65:
			var nearest: Vector2 = paths["LogHollow"].get_closest_point(prop.position)
			var other: Vector2 = paths["BlueFernNook"].get_closest_point(prop.position)
			if other.distance_to(prop.position)<nearest.distance_to(prop.position):
				nearest = other
			var direction := (prop.position-nearest).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.UP
			prop.position = (nearest+direction*95).round()
	var rocks: TileMapLayer = root.get_node("Obstacles")
	for cell in rocks.get_used_cells():
		if _extra_distance(rocks.map_to_local(cell))<50:
			rocks.erase_cell(cell)

func _natural_paths() -> void:
	var group: Node2D = root.get_node("NaturalTrails")
	for child in group.get_children():
		group.remove_child(child)
		child.free()
	# Every grassy margin is below every dirt track, keeping forks free of triangles.
	for margin in [true,false]:
		for name_: String in paths:
			var main := name_ in ["North","East","South"]
			var width := 34.0 if main else 22.0
			var begin := 175.0 if main else 0.0
			var points := _ribbon(paths[name_],width+(7 if margin else 0),begin)
			var surface := _surface(group,points,Color("929955") if margin else Color("b09e68"),Vector2.ZERO if margin else Vector2(224,32),0.35 if margin else 0.54)
			surface.name = name_+("Margin" if margin else "Track")
	for pair in [[Vector2(1455,1620),Vector2(47,21)],[Vector2(1670,1760),Vector2(32,16)]]:
		_surface(group,_blob(pair[0],pair[1]),Color("aaa365"),Vector2(224,32),0.32)
	for centre in HIDDEN_GROVES:
		var surface := _surface(root.get_node("ForestFloor"),_blob(centre,Vector2(140,110)),Color("9aa95e"),Vector2.ZERO,0.45)
		surface.name = "HiddenGroveGround"

func _ribbon(curve: Curve2D,width: float,begin: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var length := curve.get_baked_length()
	var count := int((length-begin)/8)+1
	var end_normal := Vector2.ZERO
	var end_tangent := Vector2.ZERO
	var end_width := width
	for i in count+1:
		var offset := lerpf(begin,length,float(i)/count)
		var at := curve.sample_baked(offset)
		var tangent := (curve.sample_baked(minf(length,offset+3))-curve.sample_baked(maxf(0,offset-3))).normalized()
		var normal := Vector2(-tangent.y,tangent.x)
		var variation := 1.0+sin(offset*0.012)*0.24+sin(offset*0.047)*0.07
		var half_width := width*variation
		if begin>0:
			half_width *= lerpf(0.12,1.0,clampf((offset-begin)/95,0,1))
		var broken_edge := sin(offset*0.21)*1.8+cos(offset*0.097)*2.3
		left.append(((at+normal*(half_width+broken_edge))/2).round()*2)
		right.append(((at-normal*(half_width-broken_edge*0.7))/2).round()*2)
		end_normal = normal
		end_tangent = tangent
		end_width = half_width
	var end := curve.sample_baked(length)
	for i in range(1,9):
		var angle := PI*i/9.0
		left.append(((end+(end_normal*cos(angle)+end_tangent*sin(angle))*end_width)/2).round()*2)
	right.reverse()
	left.append_array(right)
	return left

func _clear_path_details() -> void:
	var low: TileMapLayer = root.get_node("VegetationLow")
	for cell in low.get_used_cells():
		var at := low.map_to_local(cell)
		if Layout.trail_distance(at,paths)<18 or at.distance_to(LANDMARK)<88:
			low.erase_cell(cell)
	for child: Node2D in root.get_node("WoodlandDetails").get_children():
		if Layout.trail_distance(child.position,paths)<16 or child.position.distance_to(LANDMARK)<85:
			child.get_parent().remove_child(child)
			child.free()

func _canopy_shadows() -> void:
	var shade := _group("CanopyShade",-6)
	for tree: Node2D in root.get_node("VegetationHigh").get_children():
		var sprite: Sprite2D = tree.get_node("Sprite")
		if sprite.scale.x<2:
			continue
		var projection := Polygon2D.new()
		projection.position = tree.position+Vector2(12,0)
		projection.polygon = _blob(Vector2.ZERO,Vector2(58,23))
		projection.color = Color(0.10,0.22,0.17,0.16)
		_add(shade,projection)

func _landmark() -> void:
	var landmark := Node2D.new()
	landmark.name = "AwakeningLandmark"
	landmark.position = LANDMARK
	landmark.y_sort_enabled = true
	_add(root,landmark)
	var moss := _surface(landmark,_blob(Vector2(0,2),Vector2(73,37)),Color("849a57"),Vector2.ZERO,0.4)
	moss.z_index = -12
	# Low ancestral stone and broken ring: broad southern opening faces the spawn.
	_stone(landmark,Vector2.ZERO,2,"HeartStone")
	for data in [Vector2(-50,-8),Vector2(-32,-29),Vector2(9,-32),Vector2(47,-20),Vector2(56,7)]:
		_stone(landmark,data,1,"RingStone")
	for pair in [[Vector2(-58,24),ENV+"flowers.png"],[Vector2(48,29),ENV+"flowers.png"],[Vector2(-37,-17),FOREST+"fern.png"],[Vector2(38,-27),FOREST+"mushroom_glow.png"]]:
		_sprite(landmark,pair[1],pair[0])
	# A small native Godot crystal/leaf engraving gives the reused stone an identity.
	var mark := Polygon2D.new()
	mark.name = "LeafEngraving"
	mark.position = Vector2(0,-29)
	mark.polygon = PackedVector2Array([Vector2(0,-9),Vector2(6,-1),Vector2(0,6),Vector2(-5,-1)])
	mark.color = Color("a9dcb2")
	_add(landmark.get_node("HeartStone"),mark)
	var approach := Marker2D.new()
	approach.name = "Approach"
	approach.position = Vector2(0,63)
	_add(landmark,approach)

func _grove_details() -> void:
	var group := _group("HiddenGroveDetails")
	group.y_sort_enabled = true
	var log: Node2D = Node2D.new()
	log.name = "FlowerLog"
	log.position = HIDDEN_GROVES[0]+Vector2(-33,-57)
	_add(group,log)
	_sprite(log,"res://assets/sprites/objects/fallen_log_mossy_fallen_oak/rotations/fallen_log_mossy_fallen_oak.png",Vector2.ZERO)
	_body(log,Vector2(33,11))
	for i in 9:
		_sprite(group,ENV+"flowers.png",log.position+Vector2(rng.randf_range(-70,70),rng.randf_range(8,32)))
	for i in 10:
		var at := HIDDEN_GROVES[1]+Vector2(rng.randf_range(-100,100),rng.randf_range(-70,40))
		if at.distance_to(HIDDEN_GROVES[1])>45:
			_sprite(group,FOREST+("mushroom_glow.png" if i%3==0 else "fern.png"),at)

func _stone(parent: Node,at: Vector2,size_scale: int,label: String) -> void:
	var stone := Node2D.new()
	stone.name = label
	stone.position = at
	_add(parent,stone)
	_sprite(stone,ENV+"stone.png",Vector2.ZERO,size_scale)
	_body(stone,Vector2(12,6)*size_scale)

func _body(parent: Node,half: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "SolidBase"
	body.collision_layer = 2
	body.collision_mask = 1
	_add(parent,body)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = half*2
	shape.shape = rectangle
	shape.position.y = -half.y
	_add(body,shape)

func _sprite(parent: Node,path: String,at: Vector2,scale_: int = 1) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	var used := sprite.texture.get_image().get_used_rect()
	sprite.offset = sprite.texture.get_size()*0.5-Vector2(used.position.x+used.size.x*0.5,used.end.y)
	sprite.position = at.round()
	sprite.scale = Vector2.ONE*scale_
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_add(parent,sprite)
	return sprite

func _blob(at: Vector2,radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 36:
		var angle := TAU*i/36.0
		points.append(((at+Vector2.from_angle(angle)*radius*(1+sin(angle*3)*0.12+cos(angle*5)*0.06))/2).round()*2)
	return points

func _surface(parent: Node,points: PackedVector2Array,color: Color,origin: Vector2,strength: float) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/world/forest_surface.gdshader")
	mat.set_shader_parameter("terrain_atlas",load("res://assets/tilesets/grass_dirt_v3_32x32.png"))
	mat.set_shader_parameter("atlas_origin",origin)
	mat.set_shader_parameter("texture_strength",strength)
	polygon.material = mat
	_add(parent,polygon)
	return polygon

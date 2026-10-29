extends Node2D
## Ground-only silhouette projection. Actors, collision shapes and Y-sort stay untouched.
const RULES = preload("res://scripts/world/visual_rules.gd")
const STOPS := [
	[0.0, Vector2(-.22,.22), .09], [180.0, Vector2(.22,.30), .07],
	[300.0, Vector2(.65,.42), 0.0], [360.0, Vector2(-1.1,.55), .15],
	[420.0, Vector2(-.85,.48), .25], [720.0, Vector2(.04,.19), .19],
	[990.0, Vector2(.8,.42), .26], [1110.0, Vector2(1.18,.55), .22],
	[1170.0, Vector2(1.3,.65), 0.0], [1200.0, Vector2(-.4,.35), .06],
	[1320.0, Vector2(-.5,.27), .11], [1440.0, Vector2(-.22,.22), .09]
]
var _casters: Dictionary = {}
var _kinds: Dictionary = {}
var _pending: Array[WeakRef] = []
var _used_rects: Dictionary = {}
var _profile := {"vector": Vector2.ZERO, "opacity": 0.0}
var _region: Node2D
var _old_canopy: CanvasItem
var _old_canopy_visible := false
var drawn_casters := 0
var _dynamic_ids: Array = []
var _static_ids: Array = []
var _visible_static: Array = []
var _static_pass: Node2D
var _cull_age := 1.0
var _shade_age := 1.0

func _ready() -> void:
	_region = get_parent().get_parent()
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_as_relative = false
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shade := ShaderMaterial.new()
	shade.shader = preload("res://scripts/world/day_shadows.gdshader")
	material = shade
	_static_pass = Node2D.new()
	_static_pass.name = "StaticGroundShadows"
	_static_pass.use_parent_material = true
	_static_pass.draw.connect(func(): _draw_casters(_static_pass,_visible_static))
	add_child(_static_pass)
	for node in _region.find_children("*", "", true, false):
		if node is Sprite2D or node is AnimatedSprite2D: _register(node)
	get_tree().node_added.connect(_on_node_added)
	_old_canopy = _region.get_node_or_null("CanopyShade")
	if _old_canopy:
		_old_canopy_visible = _old_canopy.visible
		_old_canopy.hide()
	update_for_time(0)

func _exit_tree() -> void:
	if is_instance_valid(_old_canopy): _old_canopy.visible = _old_canopy_visible
	if get_tree().node_added.is_connected(_on_node_added): get_tree().node_added.disconnect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is Sprite2D or node is AnimatedSprite2D: _pending.append(weakref(node))

func _register(sprite: Node2D) -> void:
	if not is_instance_valid(sprite) or not _region.is_ancestor_of(sprite): return
	var kind := ""
	var parent := sprite.get_parent()
	if parent is CharacterBody2D:
		kind = "slime" if parent.is_in_group("living_slimes") or (parent.get_script() and parent.get_script().resource_path.ends_with("/slime.gd")) else "player"
	elif str(sprite.name).begins_with("Ambient_") or _is_wildlife_texture(sprite): kind = "animal"
	else:
		var node: Node = sprite
		while node and node != _region:
			if str(node.name) in RULES.PROP_GROUPS or str(node.name) in ["MapArt", "AwakeningLandmark", "NaturalSpring"]:
				kind = "object"
				break
			node = node.get_parent()
		if kind == "object" and sprite is Sprite2D and sprite.texture:
			var path: String = sprite.texture.resource_path.to_lower()
			if RULES.is_ground_cover(path): return
			if ("oak" in path or "pine" in path or "tree" in path) and not "log" in path: kind = "tree"
	if kind.is_empty(): return
	if not _casters.has(sprite.get_instance_id()):
		if kind in ["player","slime","animal"]: _dynamic_ids.append(sprite.get_instance_id())
		else: _static_ids.append(sprite.get_instance_id()); _cull_age = 1.0
	_casters[sprite.get_instance_id()] = sprite
	_kinds[sprite.get_instance_id()] = kind

func _is_wildlife_texture(sprite: Node2D) -> bool:
	var texture := _texture_for(sprite)
	if not texture: return false
	if texture is AtlasTexture: texture = texture.atlas
	return "/wildlife/" in texture.resource_path

func update_for_time(delta: float) -> void:
	for ref in _pending:
		var sprite = ref.get_ref()
		if is_instance_valid(sprite): _register(sprite)
	_pending.clear()
	_profile = profile_at(GameClock.get_save_data().minutes)
	_cull_age += delta
	_shade_age += delta
	if _cull_age >= .25 or delta == 0:
		_cull_age = 0.0
		var view := (get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()).grow(170)
		_visible_static.clear()
		for id in _casters.keys():
			if not is_instance_valid(_casters[id]):
				_casters.erase(id)
				_kinds.erase(id)
		_dynamic_ids = _dynamic_ids.filter(func(id): return _casters.has(id))
		_static_ids = _static_ids.filter(func(id): return _casters.has(id))
		for id in _static_ids:
			if view.has_point(_casters[id].global_position): _visible_static.append(id)
		_shade_age = 1.0
	if _shade_age >= .1 or delta == 0:
		_shade_age = 0.0
		_static_pass.queue_redraw()
	queue_redraw()

static func profile_at(minutes: float) -> Dictionary:
	var value := fposmod(minutes,1440.0) if is_finite(minutes) else 420.0
	for i in range(STOPS.size()-1):
		var a: Array = STOPS[i]
		var b: Array = STOPS[i+1]
		if value <= b[0]:
			var t := smoothstep(float(a[0]),float(b[0]),value)
			return {"vector":(a[1] as Vector2).lerp(b[1],t),"opacity":lerpf(a[2],b[2],t)}
	return {"vector":Vector2.ZERO,"opacity":0.0}

func has_caster(sprite: Node2D) -> bool: return _casters.has(sprite.get_instance_id())
func count_category(kind: String) -> int: return _kinds.values().count(kind)

func casts_on_ground(sprite: Node2D) -> bool:
	if not sprite.is_visible_in_tree(): return false
	var parent := sprite.get_parent()
	return not (parent.is_in_group("living_slimes") and parent.get("swimming"))

func _texture_for(sprite: Node2D) -> Texture2D:
	if sprite is Sprite2D: return sprite.texture
	if sprite is AnimatedSprite2D and sprite.sprite_frames and sprite.sprite_frames.has_animation(sprite.animation):
		if sprite.sprite_frames.get_frame_count(sprite.animation)>0:
			return sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	return null

func _rect_for(sprite: Node2D, texture: Texture2D) -> Rect2:
	if sprite is Sprite2D: return sprite.get_rect()
	return Rect2(sprite.offset - (texture.get_size()*.5 if sprite.centered else Vector2.ZERO),texture.get_size())

func source_bottom(sprite: Node2D) -> float:
	var texture := _texture_for(sprite)
	if not texture: return 0.0
	var rect := _rect_for(sprite,texture)
	if sprite is Sprite2D and (sprite.region_enabled or sprite.hframes>1 or sprite.vframes>1): return rect.end.y
	var key := texture.get_instance_id()
	if not _used_rects.has(key): _used_rects[key] = texture.get_image().get_used_rect()
	var used: Rect2i = _used_rects[key]
	return rect.position.y + (texture.get_height()-used.position.y if sprite.flip_v else used.end.y)

func projection_for(sprite: Node2D, foot: Vector2, direction: Vector2) -> Transform2D:
	var source := sprite.global_transform
	# Strip transparent bottom padding and hop height: the shadow remains on the ground.
	var baseline := source * Vector2(0,source_bottom(sprite))
	source.origin -= Vector2(foot.x,baseline.y)
	var projection := Transform2D(Vector2.RIGHT,-direction,foot)
	return projection * source

func _draw() -> void:
	drawn_casters = 0
	_draw_casters(self,_dynamic_ids)

func _draw_casters(target: Node2D, ids: Array) -> void:
	if _profile.opacity < .001: return
	var view := (get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()).grow(170)
	for id in ids:
		var sprite = _casters.get(id)
		if not is_instance_valid(sprite) or not casts_on_ground(sprite): continue
		var parent: Node = sprite.get_parent()
		var foot: Vector2 = parent.global_position if parent is CharacterBody2D or (sprite.name == &"Sprite" and parent is Node2D) else sprite.global_position
		if not view.has_point(foot): continue
		var texture := _texture_for(sprite)
		if not texture: continue
		var rect := _rect_for(sprite,texture)
		var direction: Vector2 = _profile.vector
		# Avoid enormous overlapping canopy projections while retaining tree silhouettes.
		var height: float = rect.size.y * sprite.global_scale.y
		if height*direction.length()>140: direction *= 140/(height*direction.length())
		var opacity: float = _profile.opacity * (.70 if _kinds[id]=="tree" else 1.0)
		target.draw_set_transform_matrix(target.global_transform.affine_inverse()*projection_for(sprite,foot,direction))
		if sprite.flip_h: rect.position.x += rect.size.x; rect.size.x = -rect.size.x
		if sprite.flip_v: rect.position.y += rect.size.y; rect.size.y = -rect.size.y
		var tint := Color(1,1,1,opacity*sprite.modulate.a)
		if sprite is Sprite2D and sprite.region_enabled:
			target.draw_texture_rect_region(texture,rect,sprite.region_rect,tint)
		elif sprite is Sprite2D and (sprite.hframes>1 or sprite.vframes>1):
			var size := texture.get_size()/Vector2(sprite.hframes,sprite.vframes)
			target.draw_texture_rect_region(texture,rect,Rect2(Vector2(sprite.frame_coords)*size,size),tint)
		else: target.draw_texture_rect(texture,rect,false,tint)
		drawn_casters += 1
	target.draw_set_transform_matrix(Transform2D.IDENTITY)

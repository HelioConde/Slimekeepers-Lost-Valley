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
## Sombra de contato: faixa da base da silhueta (tronco, pedra, pés), projetada curta.
## Comprimento máximo (px) da sombra projetada: copas não cobrem a clareira e os caminhos.
const MAX_CAST := 110.0
const CONTACT_MIN := 6.0
const CONTACT_MAX := 18.0
const CONTACT_SKIP := ["flower", "fern", "reed", "grass", "lily", "clover"]
## Objetos que boiam: um blob escuro pintado sob eles parece sombra sem origem.
const FLOATING := ["lily"]
## Grupos com objetos sólidos fora de PROP_GROUPS: pedras da borda das cachoeiras
## (só os nós "Sprite"; o véu d'água e as paredes de rocha não projetam no chão)
## e a fogueira da estação de culinária.
const EXTRA_CASTER_GROUPS := ["MapArt", "AwakeningLandmark", "NaturalSpring", "Waterfalls", "CookingStation"]
var _casters: Dictionary = {}
var _contacts: Dictionary = {}
var _hidden_blobs: Array[CanvasItem] = []
var _contact := {"vector": Vector2.ZERO, "opacity": 0.0}
var _kinds: Dictionary = {}
var _pending: Array[WeakRef] = []
var _used_rects: Dictionary = {}
var _ground_lines: Dictionary = {}
var _profile := {"vector": Vector2.ZERO, "opacity": 0.0}
var _region: Node2D
var _old_canopy: CanvasItem
var _old_canopy_visible := false
var drawn_casters := 0
var _dynamic_ids: Array = []
var _static_ids: Array = []
var _visible_static: Array = []
var _static_pass: Node2D
var _dynamic_pass: Node2D
var _static_contact: Node2D
var _dynamic_contact: Node2D
## Sombras projetadas são desenhadas opacas dentro deste grupo e a opacidade do
## horário é aplicada uma única vez: onde várias copas se sobrepõem não há acúmulo
## (antes, faixas diagonais mais escuras dividiam o chão).
var cast_group: CanvasGroup
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
	cast_group = CanvasGroup.new()
	cast_group.name = "CastShadows"
	add_child(cast_group)
	_static_pass = _make_pass("StaticGroundShadows", cast_group, func(): _draw_casters(_static_pass,_visible_static,false))
	_dynamic_pass = _make_pass("DynamicGroundShadows", cast_group, func(): _draw_casters(_dynamic_pass,_dynamic_ids,false))
	_static_contact = _make_pass("StaticContactShadows", self, func(): _draw_casters(_static_contact,_visible_static,true))
	_dynamic_contact = _make_pass("DynamicContactShadows", self, func(): _draw_casters(_dynamic_contact,_dynamic_ids,true))
	for node in _region.find_children("*", "", true, false):
		if node is Sprite2D or node is AnimatedSprite2D: _register(node)
	get_tree().node_added.connect(_on_node_added)
	_hide_floating_blobs()
	_old_canopy = _region.get_node_or_null("CanopyShade")
	if _old_canopy:
		_old_canopy_visible = _old_canopy.visible
		_old_canopy.hide()
	update_for_time(0)

func _exit_tree() -> void:
	for blob in _hidden_blobs:
		if is_instance_valid(blob): blob.show()
	_hidden_blobs.clear()
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
			if str(node.name) in RULES.PROP_GROUPS or str(node.name) in EXTRA_CASTER_GROUPS:
				kind = "object"
				if str(node.name) == "Waterfalls" and sprite.name != &"Sprite": kind = ""
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
	_contacts[sprite.get_instance_id()] = _wants_contact(sprite)
	# O blob elíptico fixo do mapa é trocado pela sombra de contato com silhueta.
	for holder in [sprite, sprite.get_parent()]:
		var blob := holder.get_node_or_null("ContactShadow") as CanvasItem
		if blob and blob.visible and _contacts[sprite.get_instance_id()]:
			blob.hide()
			_hidden_blobs.append(blob)

func _hide_floating_blobs() -> void:
	for blob in _region.find_children("ContactShadow", "CanvasItem", true, false):
		var owner_sprite := blob.get_parent().get_node_or_null("Sprite") as Sprite2D
		if not owner_sprite or not owner_sprite.texture or not blob.visible: continue
		var path := owner_sprite.texture.resource_path.to_lower()
		for word in FLOATING:
			if word in path:
				blob.hide()
				_hidden_blobs.append(blob)
				break

func _wants_contact(sprite: Node2D) -> bool:
	var texture := _texture_for(sprite)
	if texture is AtlasTexture: texture = texture.atlas
	var path := texture.resource_path.to_lower() if texture else ""
	for word in CONTACT_SKIP:
		if word in path: return false
	return true

func has_contact(sprite: Node2D) -> bool: return _contacts.get(sprite.get_instance_id(), false)

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
	_contact = contact_profile(GameClock.get_save_data().minutes)
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
		# Mesma textura em sequência = um lote só (pinheiros/carvalhos se repetem muito).
		_visible_static.sort_custom(func(a, b): return _texture_key(a) < _texture_key(b))
		_shade_age = 1.0
	if _shade_age >= .1 or delta == 0:
		_shade_age = 0.0
		_static_pass.queue_redraw()
		_static_contact.queue_redraw()
	cast_group.self_modulate.a = float(_profile.opacity) * .85
	drawn_casters = 0
	_dynamic_pass.queue_redraw()
	_dynamic_contact.queue_redraw()

static func profile_at(minutes: float) -> Dictionary:
	var value := fposmod(minutes,1440.0) if is_finite(minutes) else 420.0
	for i in range(STOPS.size()-1):
		var a: Array = STOPS[i]
		var b: Array = STOPS[i+1]
		if value <= b[0]:
			var t := smoothstep(float(a[0]),float(b[0]),value)
			return {"vector":(a[1] as Vector2).lerp(b[1],t),"opacity":lerpf(a[2],b[2],t)}
	return {"vector":Vector2.ZERO,"opacity":0.0}

## Contato: mesma direção do sol, encurtada, com um leve espalhamento para baixo
## (oclusão no pé) para nunca sumir ao meio-dia; mais escura que a sombra projetada.
static func contact_profile(minutes: float) -> Dictionary:
	var cast := profile_at(minutes)
	return {"vector": (cast.vector as Vector2) * .8 + Vector2(0, .3), "opacity": .16 + .55 * float(cast.opacity)}

## Faixa (em coordenadas locais do sprite) da base visível da silhueta.
func contact_strip(sprite: Node2D) -> Rect2:
	var texture := _texture_for(sprite)
	if not texture: return Rect2()
	var rect := _rect_for(sprite, texture)
	var bottom := ground_bottom(sprite)
	var scale_y := maxf(absf(sprite.global_scale.y), .001)
	var visible_height := bottom - rect.position.y
	var height := clampf(visible_height * scale_y * .18, CONTACT_MIN, CONTACT_MAX) / scale_y
	height = minf(height, visible_height)
	return Rect2(rect.position.x, bottom - height, rect.size.x, height)

## Árvores (pé e altura em px do mundo) com pé dentro do retângulo: as manchas de
## sol nascem nas aberturas dessas copas.
func trees_near(center: Vector2, half: Vector2) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var box := Rect2(center - half, half * 2.0)
	for id in _static_ids:
		if _kinds.get(id) != "tree": continue
		var sprite = _casters.get(id)
		if not is_instance_valid(sprite) or not sprite.is_visible_in_tree(): continue
		var foot := foot_for(sprite)
		if not box.has_point(foot): continue
		var texture := _texture_for(sprite)
		var height := _rect_for(sprite, texture).size.y * absf(sprite.global_scale.y) if texture else 120.0
		found.append({"foot": foot, "height": height})
	return found

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

## Ponto de apoio no chão: o corpo do personagem ou o nó-âncora do objeto.
func foot_for(sprite: Node2D) -> Vector2:
	var parent: Node = sprite.get_parent()
	if parent is CharacterBody2D or (sprite.name == &"Sprite" and parent is Node2D): return parent.global_position
	# Sprite solto: apoia na base visível (ignora padding transparente embaixo),
	# senão a sombra nasce alguns pixels abaixo do objeto e parece desconectada.
	return Vector2(sprite.global_position.x, (sprite.global_transform * Vector2(0, ground_bottom(sprite))).y)

## Linha do chão estável da animação: o pé mais baixo entre todos os quadros.
## Usar a base de cada quadro fazia a sombra subir/descer até 7 px por quadro na
## corrida (quadros com os dois pés no ar), fora de sincronia com o corpo.
func ground_bottom(sprite: Node2D) -> float:
	if not (sprite is AnimatedSprite2D and sprite.sprite_frames and sprite.sprite_frames.has_animation(sprite.animation)):
		return source_bottom(sprite)
	var frames: SpriteFrames = sprite.sprite_frames
	var key := "%d:%s:%s" % [frames.get_instance_id(), sprite.animation, sprite.flip_v]
	if not _ground_lines.has(key):
		var lowest := -INF
		for index in frames.get_frame_count(sprite.animation):
			var texture := frames.get_frame_texture(sprite.animation, index)
			if not texture: continue
			var rect := _rect_for(sprite, texture)
			var used_key := texture.get_instance_id()
			if not _used_rects.has(used_key): _used_rects[used_key] = texture.get_image().get_used_rect()
			var used: Rect2i = _used_rects[used_key]
			lowest = maxf(lowest, rect.position.y + (texture.get_height()-used.position.y if sprite.flip_v else used.end.y))
		_ground_lines[key] = lowest if is_finite(lowest) else source_bottom(sprite)
	return _ground_lines[key]

func projection_for(sprite: Node2D, foot: Vector2, direction: Vector2) -> Transform2D:
	var source := sprite.global_transform
	# Strip transparent bottom padding and hop height: the shadow remains on the ground.
	var baseline := source * Vector2(0,ground_bottom(sprite))
	source.origin -= Vector2(foot.x,baseline.y)
	var projection := Transform2D(Vector2.RIGHT,-direction,foot)
	return projection * source

func _make_pass(pass_name: String, parent: Node, painter: Callable) -> Node2D:
	var node := Node2D.new()
	node.name = pass_name
	node.material = material
	node.draw.connect(painter)
	parent.add_child(node)
	return node

## contact = false: silhueta projetada opaca (opacidade vem do CastShadows);
## contact = true: faixa da base, com a opacidade do contato.
func _draw_casters(target: Node2D, ids: Array, contact: bool) -> void:
	if (not contact and _profile.opacity < .001) or (contact and _contact.opacity < .001): return
	var view := (get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()).grow(170)
	for id in ids:
		var sprite = _casters.get(id)
		if not is_instance_valid(sprite) or not casts_on_ground(sprite): continue
		if contact and (not _contacts.get(id, false) or sprite.flip_v): continue
		var foot := foot_for(sprite)
		if not view.has_point(foot): continue
		var texture := _texture_for(sprite)
		if not texture: continue
		var source := _source_for(sprite, texture)
		if contact:
			_draw_contact(target, sprite, texture, foot, source)
			continue
		var rect := _rect_for(sprite,texture)
		var direction: Vector2 = _profile.vector
		# Avoid enormous overlapping canopy projections while retaining tree silhouettes.
		var height: float = rect.size.y * sprite.global_scale.y
		if height*direction.length()>MAX_CAST: direction *= MAX_CAST/(height*direction.length())
		target.draw_set_transform_matrix(target.global_transform.affine_inverse()*projection_for(sprite,foot,direction))
		if sprite.flip_h: rect.position.x += rect.size.x; rect.size.x = -rect.size.x
		if sprite.flip_v: rect.position.y += rect.size.y; rect.size.y = -rect.size.y
		target.draw_texture_rect_region(texture,rect,source,Color(1,1,1,sprite.modulate.a))
		drawn_casters += 1
	target.draw_set_transform_matrix(Transform2D.IDENTITY)

func _texture_key(id: int) -> int:
	var sprite = _casters.get(id)
	var texture := _texture_for(sprite) if is_instance_valid(sprite) else null
	return texture.get_rid().get_id() if texture else 0

func _source_for(sprite: Node2D, texture: Texture2D) -> Rect2:
	if sprite is Sprite2D and sprite.region_enabled: return sprite.region_rect
	if sprite is Sprite2D and (sprite.hframes>1 or sprite.vframes>1):
		var size := texture.get_size()/Vector2(sprite.hframes,sprite.vframes)
		return Rect2(Vector2(sprite.frame_coords)*size,size)
	return Rect2(Vector2.ZERO,texture.get_size())

func _draw_contact(target: Node2D, sprite: Node2D, texture: Texture2D, foot: Vector2, source: Rect2) -> void:
	var full := _rect_for(sprite,texture)
	var strip := contact_strip(sprite)
	if strip.size.y <= 0.0 or full.size.y <= 0.0: return
	var ratio := source.size.y/full.size.y
	var src := Rect2(source.position.x,source.position.y+(strip.position.y-full.position.y)*ratio,source.size.x,strip.size.y*ratio)
	target.draw_set_transform_matrix(target.global_transform.affine_inverse()*projection_for(sprite,foot,_contact.vector))
	if sprite.flip_h: strip.position.x += strip.size.x; strip.size.x = -strip.size.x
	target.draw_texture_rect_region(texture,strip,src,Color(1,1,1,float(_contact.opacity)*sprite.modulate.a))

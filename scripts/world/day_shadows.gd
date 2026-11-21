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
## Copas: projeção curta, a sombra fica sob a árvore e colada ao tronco.
const MAX_TREE_CAST := 70.0
const CONTACT_MIN := 6.0
const CONTACT_MAX := 18.0
const CONTACT_SKIP := ["flower", "fern", "reed", "grass", "lily", "clover"]
## Objetos que boiam: um blob escuro pintado sob eles parece sombra sem origem.
const FLOATING := ["lily"]
## Grupos com objetos sólidos fora de PROP_GROUPS: pedras da borda das cachoeiras
## (só os nós "Sprite"; o véu d'água e as paredes de rocha não projetam no chão)
## e a fogueira da estação de culinária.
const EXTRA_CASTER_GROUPS := ["GroundDetail", "MapArt", "AwakeningLandmark", "NaturalSpring", "Waterfalls", "CookingStation", "FarmField"]
var _casters: Dictionary = {}
var _contacts: Dictionary = {}
var _heights: Dictionary = {}
var _mounds: Dictionary = {}
## Tufos de mato (z -2): sombra numa camada própria logo abaixo deles (z -3).
var _undercover: Dictionary = {}
var _undercover_pass: Node2D
var _boxes: Array[Node2D] = []
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
	_undercover_pass = _make_pass("UnderCoverShadows", self, func(): _draw_undercover(_undercover_pass))
	_undercover_pass.z_as_relative = false
	_undercover_pass.z_index = -3
	for node in _region.find_children("*", "", true, false):
		if node is Sprite2D or node is AnimatedSprite2D: _register(node)
	for node in get_tree().get_nodes_in_group("shadow_boxes"):
		if _region.is_ancestor_of(node): _register_box(node)
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
	if node is Sprite2D or node is AnimatedSprite2D or node.has_method("shadow_footprint"): _pending.append(weakref(node))

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
			# Tufos de mato são cobertura de chão para a ordem de desenho, mas são de pé:
			# projetam sombra (só abaixo da base, sem escurecer o próprio tufo).
			if RULES.is_ground_cover(path) and not path.ends_with("/grass.png"): return
			if ("oak" in path or "pine" in path or "tree" in path) and not "log" in path: kind = "tree"
	if kind.is_empty(): return
	if not _casters.has(sprite.get_instance_id()):
		if kind in ["player","slime","animal"]: _dynamic_ids.append(sprite.get_instance_id())
		else: _static_ids.append(sprite.get_instance_id()); _cull_age = 1.0
	_casters[sprite.get_instance_id()] = sprite
	_kinds[sprite.get_instance_id()] = kind
	_contacts[sprite.get_instance_id()] = _wants_contact(sprite)
	var texture := _texture_for(sprite)
	var file := texture.resource_path.get_file().to_lower() if texture else ""
	_heights[sprite.get_instance_id()] = height_factor(kind, file)
	if file == "grass.png": _undercover[sprite.get_instance_id()] = true
	var mound := mound_height(kind, file)
	if mound > 0.0: _mounds[sprite.get_instance_id()] = mound
	else: _mounds.erase(sprite.get_instance_id())
	# O blob elíptico fixo do mapa é trocado pela sombra de contato com silhueta.
	for holder in [sprite, sprite.get_parent()]:
		var blob := holder.get_node_or_null("ContactShadow") as CanvasItem
		if blob and blob.visible and (_contacts[sprite.get_instance_id()] or _mounds.has(sprite.get_instance_id())):
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

## Fração do sprite que é altura física. Na arte 3/4 top-down, parte do desenho de
## pedras, arbustos e copas é a face de cima vista de frente — projetar o sprite
## inteiro jogava sombras de árvores e pedras para o meio da clareira, longe do pé.
static func height_factor(kind: String, file: String) -> float:
	if kind in ["player", "slime", "animal"]: return 1.0
	if kind == "tree": return 0.42
	# Tufo de mato: fica abaixo dos atores (z -2), então a sombra só pode sair da base
	# para baixo e curta, sem cobrir o próprio tufo.
	if "grass" in file: return 0.09
	for word in ["rock", "stone", "boulder", "stump", "log", "ruin", "crystal", "campfire", "step"]:
		if word in file: return 0.35
	for word in ["bush", "shrub"]:
		if word in file: return 0.45
	return 0.55

## Direção de projeção do sprite no horário atual, já com altura real e limite.
func cast_direction(sprite: Node2D) -> Vector2:
	var id := sprite.get_instance_id()
	var texture := _texture_for(sprite)
	if not texture: return Vector2.ZERO
	var height: float = _rect_for(sprite, texture).size.y * sprite.global_scale.y
	var direction: Vector2 = (_profile.vector as Vector2) * float(_heights.get(id, 1.0))
	var limit := MAX_TREE_CAST if _kinds.get(id) == "tree" else MAX_CAST
	if height * direction.length() > limit: direction *= limit / (height * direction.length())
	return direction

func has_box(node: Node2D) -> bool: return _boxes.has(node)

func _register_box(node: Node2D) -> void:
	if not _boxes.has(node) and node.has_method("shadow_footprint"):
		_boxes.append(node)
		_cull_age = 1.0

## Caixa baixa desenhada por código: pegada + a mesma pegada deslocada pela altura.
func _draw_box(target: Node2D, node: Node2D, contact: bool) -> void:
	var footprint: Rect2 = node.shadow_footprint()
	if footprint.size == Vector2.ZERO: return
	var height: float = node.shadow_height()
	var shift: Vector2 = (_contact.vector if contact else _profile.vector) * height * (0.6 if contact else 1.0)
	var points := PackedVector2Array()
	for corner in [footprint.position, Vector2(footprint.end.x, footprint.position.y), footprint.end, Vector2(footprint.position.x, footprint.end.y)]:
		points.append(node.global_transform * corner)
		points.append(node.global_transform * corner + shift)
	var hull := Geometry2D.convex_hull(points)
	target.draw_set_transform_matrix(target.global_transform.affine_inverse())
	target.draw_colored_polygon(hull, Color(1, 1, 1, float(_contact.opacity) if contact else 1.0))

func _wants_contact(sprite: Node2D) -> bool:
	var texture := _texture_for(sprite)
	if texture is AtlasTexture: texture = texture.atlas
	var path := texture.resource_path.to_lower() if texture else ""
	for word in CONTACT_SKIP:
		if word in path: return false
	return true

func has_contact(sprite: Node2D) -> bool:
	return _contacts.get(sprite.get_instance_id(), false) or _mounds.has(sprite.get_instance_id())

## Objetos baixos e arredondados (altura real em px): a sombra é a própria silhueta
## deslocada para o lado oposto ao sol, abraçando o contorno. Projetar a silhueta
## achatada (como numa árvore) virava uma lâmina fina descolada do objeto.
const MOUNDS := {"crop_growth": 5.0, "campfire": 4.0, "flower": 4.0, "fern": 5.0, "clover": 3.0, "mushroom": 6.0,
	"log": 6.0, "rock": 8.0, "stone": 8.0, "pebble": 3.0, "boulder": 9.0, "stump": 9.0, "bush": 10.0, "shrub": 10.0}
static func mound_height(kind: String, file: String) -> float:
	if kind != "object" or "steps" in file: return 0.0
	for word in MOUNDS:
		if word in file: return MOUNDS[word]
	return 0.0

## Deslocamento da sombra de um objeto baixo: segue o sol, nunca some ao meio-dia.
func mound_offset(id: int) -> Vector2:
	return ((_profile.vector as Vector2) * .55 + Vector2(0, .25)) * float(_mounds.get(id, 0.0))

func _is_wildlife_texture(sprite: Node2D) -> bool:
	var texture := _texture_for(sprite)
	if not texture: return false
	if texture is AtlasTexture: texture = texture.atlas
	return "/wildlife/" in texture.resource_path

func update_for_time(delta: float) -> void:
	for ref in _pending:
		var sprite = ref.get_ref()
		if not is_instance_valid(sprite): continue
		if sprite.has_method("shadow_footprint"):
			if _region.is_ancestor_of(sprite): _register_box(sprite)
		else: _register(sprite)
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
		_undercover_pass.queue_redraw()
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
		var mound: bool = _mounds.has(id)
		if contact and not mound and (not _contacts.get(id, false) or sprite.flip_v): continue
		if not contact and mound: continue  # objeto baixo: só a sombra deslocada (passe de contato)
		if _undercover.has(id): continue  # mato: camada própria, por baixo do tufo
		var foot := foot_for(sprite)
		if not view.has_point(foot): continue
		var texture := _texture_for(sprite)
		if not texture: continue
		var source := _source_for(sprite, texture)
		if contact and mound:
			var box := _rect_for(sprite, texture)
			target.draw_set_transform_matrix(target.global_transform.affine_inverse() * Transform2D(0.0, mound_offset(id)) * sprite.global_transform * mirror_for(sprite, box))
			target.draw_texture_rect_region(texture, box, source, Color(1, 1, 1, float(_contact.opacity) * 1.25 * sprite.modulate.a))
			continue
		if contact:
			_draw_contact(target, sprite, texture, foot, source)
			continue
		var rect := _rect_for(sprite,texture)
		var direction := cast_direction(sprite)
		target.draw_set_transform_matrix(target.global_transform.affine_inverse()*projection_for(sprite,foot,direction)*mirror_for(sprite,rect))
		target.draw_texture_rect_region(texture,rect,source,Color(1,1,1,sprite.modulate.a))
		drawn_casters += 1
	if target == _static_pass or target == _static_contact:
		_boxes = _boxes.filter(func(b): return is_instance_valid(b) and b.is_inside_tree())
		for box in _boxes:
			if box.is_visible_in_tree() and view.has_point(box.global_position): _draw_box(target, box, contact)
	target.draw_set_transform_matrix(Transform2D.IDENTITY)

## Espelhamento do sprite como transform, dentro do próprio retângulo. No GL
## Compatibility um retângulo de largura negativa NÃO espelha: desloca o desenho uma
## largura inteira (192 px numa árvore), e a sombra de toda árvore com flip_h
## aparecia no meio da clareira, longe do tronco.
static func mirror_for(sprite: Node2D, rect: Rect2, vertical: bool = true) -> Transform2D:
	var h: bool = sprite.get("flip_h") == true
	var v: bool = vertical and sprite.get("flip_v") == true
	return Transform2D(Vector2(-1.0 if h else 1.0, 0), Vector2(0, -1.0 if v else 1.0),
		Vector2(2.0 * rect.position.x + rect.size.x if h else 0.0, 2.0 * rect.position.y + rect.size.y if v else 0.0))

## Sombra embaixo do tufo: a silhueta achatada sobre a base (poça), puxada 1–3 px
## para o lado oposto ao sol e um pouco para baixo. O tufo é desenhado por cima.
func undercover_transform(sprite: Node2D) -> Transform2D:
	var base := sprite.global_transform * Vector2(0, ground_bottom(sprite))
	var shift := Vector2((_profile.vector as Vector2).x * 3.0, 2.0)
	var flatten := Transform2D(Vector2(1, 0), Vector2(0, 0.3), Vector2.ZERO)
	return Transform2D(0.0, base + shift) * flatten * Transform2D(0.0, -base) * sprite.global_transform

func _draw_undercover(target: Node2D) -> void:
	if _contact.opacity < .001: return
	var view := (get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()).grow(170)
	for id in _visible_static:
		if not _undercover.has(id): continue
		var sprite = _casters.get(id)
		if not is_instance_valid(sprite) or not casts_on_ground(sprite) or not view.has_point(sprite.global_position): continue
		var texture := _texture_for(sprite)
		if not texture: continue
		var rect := _rect_for(sprite, texture)
		target.draw_set_transform_matrix(target.global_transform.affine_inverse() * undercover_transform(sprite) * mirror_for(sprite, rect))
		target.draw_texture_rect_region(texture, rect, _source_for(sprite, texture), Color(1, 1, 1, float(_contact.opacity) * 1.4 * sprite.modulate.a))
	target.draw_set_transform_matrix(Transform2D.IDENTITY)

func has_undercover(sprite: Node2D) -> bool: return _undercover.has(sprite.get_instance_id())

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
	target.draw_set_transform_matrix(target.global_transform.affine_inverse()*projection_for(sprite,foot,_contact.vector)*mirror_for(sprite,full,false))
	target.draw_texture_rect_region(texture,strip,src,Color(1,1,1,float(_contact.opacity)*sprite.modulate.a))

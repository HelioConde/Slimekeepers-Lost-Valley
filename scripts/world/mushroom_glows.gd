extends Node2D
## Brilho dos cogumelos (referências V9): poça de luz no chão em volta de cada
## cogumelo luminoso (ciano) e brilho quente dos cogumelos vermelhos, que já
## acende ao entardecer. Vale para cogumelos em Sprite2D e nos tilemaps.
## Um conjunto fixo de halos é reposicionado nos cogumelos mais próximos do
## jogador (nada de um nó por cogumelo do mapa).

const CYAN := Color(0.35, 0.85, 1.0)
const WARM := Color(1.0, 0.55, 0.35)
const POOL_SIZE := 28
const REACH := 720.0
const KINDS := {"mushroom_glow": "cyan", "mushroom_red": "warm"}

var points := {"cyan": [] as Array[Vector2], "warm": [] as Array[Vector2]}  # células de tilemap
var sprites: Array[Sprite2D] = []  # validados ao usar: outro sistema pode trocar ou esconder
var pools: Array[Sprite2D] = []   # poças no chão (atrás de tudo)
var caps: Array[Sprite2D] = []    # brilho junto ao chapéu
var _anchor := Vector2.INF
var _time := 0.0
var _ground_texture: GradientTexture2D
var _cap_texture: GradientTexture2D


static func radial(width: int, height: int, stops: PackedFloat32Array, alphas: PackedFloat32Array) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = stops
	var colors := PackedColorArray()
	for a in alphas: colors.append(Color(1, 1, 1, a))
	gradient.colors = colors
	# Faixas (constante): luz em degraus, como pixel art, sem anéis grosseiros.
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = width
	texture.height = height
	return texture


static func kind_of(path: String) -> String:
	for key in KINDS:
		if path.ends_with(key + ".png"): return KINDS[key]
	return ""


func setup(region: Node2D) -> void:
	name = "MushroomGlows"
	top_level = true
	for node in region.find_children("*", "", true, false):
		if node is Sprite2D and node.texture:
			var kind := kind_of(node.texture.resource_path)
			if kind != "": sprites.append(node)
		elif node is TileMapLayer and node.tile_set:
			var layer := node as TileMapLayer
			for cell in layer.get_used_cells():
				var source := layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
				if source == null or source.texture == null: continue
				var kind := kind_of(source.texture.resource_path)
				if kind != "": points[kind].append(layer.to_global(layer.map_to_local(cell)))
	_ground_texture = radial(96, 48, PackedFloat32Array([0.0, 0.3, 0.55, 0.8]), PackedFloat32Array([0.5, 0.3, 0.14, 0.0]))
	_cap_texture = radial(28, 24, PackedFloat32Array([0.0, 0.35, 0.7]), PackedFloat32Array([0.9, 0.5, 0.0]))
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for i in POOL_SIZE:
		var pool := Sprite2D.new()
		pool.texture = _ground_texture
		pool.material = additive
		pool.z_as_relative = false
		pool.z_index = -3  # sobre o chão, sob plantas e personagens
		pool.visible = false
		pool.set_meta("no_shadow", true)
		add_child(pool)
		pools.append(pool)
		var cap := Sprite2D.new()
		cap.texture = _cap_texture
		cap.material = additive
		cap.z_as_relative = false
		cap.z_index = -1  # atrás do cogumelo e das copas: o halo aparece em volta, nunca sobre árvores
		cap.visible = false
		cap.set_meta("no_shadow", true)
		add_child(cap)
		caps.append(cap)


## Os cogumelos mais próximos (até POOL_SIZE), ciano e quentes misturados.
func nearest(center: Vector2) -> Array:
	var found: Array = []
	for kind in points:
		for at: Vector2 in points[kind]:
			var d := at.distance_squared_to(center)
			if d < REACH * REACH: found.append([d, at, kind])
	for sprite in sprites:
		if not is_instance_valid(sprite) or not sprite.is_visible_in_tree() or sprite.texture == null: continue
		var kind := kind_of(sprite.texture.resource_path)
		if kind == "": continue
		var at := sprite.global_position
		var d := at.distance_squared_to(center)
		if d < REACH * REACH: found.append([d, at, kind])
	found.sort_custom(func(a, b): return a[0] < b[0])
	return found.slice(0, POOL_SIZE)


func apply_time(minutes: float, center: Vector2, delta: float) -> void:
	_time += delta
	if _anchor == Vector2.INF or _anchor.distance_to(center) > 96.0:
		_anchor = center
		var near := nearest(center)
		for i in POOL_SIZE:
			var on := i < near.size()
			pools[i].visible = on
			caps[i].visible = on
			if on:
				var at: Vector2 = near[i][1]
				var warm: bool = near[i][2] == "warm"
				pools[i].position = (at + Vector2(0, -2)).round()
				caps[i].position = (at + Vector2(0, -6)).round()
				pools[i].set_meta("warm", warm)
				pools[i].scale = Vector2(0.6, 0.6) if warm else Vector2.ONE
	var night: float = preload("res://scripts/world/ambient_lights.gd").night_factor(minutes)
	# O quente já acende ao entardecer (referência das 18h); o ciano é da noite.
	var dusk := smoothstep(16.5 * 60.0, 18.5 * 60.0, fposmod(minutes, 1440.0)) if fposmod(minutes, 1440.0) > 12 * 60 else 0.0
	for i in POOL_SIZE:
		if not pools[i].visible: continue
		var warm: bool = pools[i].get_meta("warm", false)
		var on := maxf(night, dusk * 0.6) if warm else night
		var pulse := 0.88 + 0.12 * sin(_time * 1.1 + i * 1.7)
		var color := WARM if warm else CYAN
		pools[i].modulate = Color(color.r, color.g, color.b, (0.35 if warm else 0.55) * on * pulse)
		caps[i].modulate = Color(color.r, color.g, color.b, (0.6 if warm else 0.75) * on * pulse)

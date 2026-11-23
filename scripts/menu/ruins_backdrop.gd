extends Node2D
## Cenário vivo do menu (pedido do usuário, 2026-11-23): vale de ruínas antigas tomado
## pela natureza, montado em camadas independentes geradas no PixelLab
## (assets/menu/ruins/). Tela lógica de 480×270; o menu escala por inteiro.
## Nada aqui anima a imagem inteira: céu, nuvens, ruínas, chão e árvore são camadas
## com parallax próprio; água e folhas usam shaders; vaga-lumes, folhas caindo,
## névoa da cachoeira e faíscas dos cristais são partículas.
## Luz igual à do jogo (pedido do usuário, 2026-11-23): grade de cor do mundo
## (world_grade, perfil da manhã dourada), raios de sol com poça de luz no pé,
## manchas de sol nítidas no gramado (dapples) e halos em faixas (ambient_lights).

const ART := "res://assets/menu/ruins/"
const SIZE := Vector2(480, 270)
## Camadas: nome, posição na tela lógica, força do parallax (px lógicos).
const LAYERS := [
	["Sky", Vector2(0, 0), 0.0],
	["Ruins", Vector2(40, 40), 1.5],
	["Ground", Vector2(0, 80), 2.0],
	["Tree", Vector2(-120, -10), 5.0],
]
const WATERFALL_FOOT := Vector2(447, 186)
const CRYSTAL_SPOTS := [Vector2(54, 222), Vector2(73, 230)]  # cristais na raiz da árvore
const LIGHTS := preload("res://scripts/world/ambient_lights.gd")
const GRADE := preload("res://scripts/world/world_grade.gd")
## Hora do perfil de luz do menu: manhã dourada (minutos do dia, como o GameClock).
const MENU_MINUTE := 430.0
## Direção do sol (de cima à direita) e onde cada raio toca o chão.
const SUN_DIR := Vector2(-0.42, 1.0)
const SHAFT_FEET := [Vector2(250, 205), Vector2(300, 190), Vector2(342, 214), Vector2(205, 228)]
const DAPPLE_SPOTS := [Vector2(185, 196), Vector2(262, 178), Vector2(318, 204), Vector2(150, 236), Vector2(372, 188), Vector2(228, 214)]

var reduce_motion := false:
	set(value):
		reduce_motion = value
		_apply_motion()
## Tempo de animação acumulado (para no modo "reduzir movimento").
var age := 0.0
var _layers: Dictionary = {}
var _clouds: Array[Sprite2D] = []
var _glows: Array[Sprite2D] = []
var _particles: Array[CPUParticles2D] = []
var _materials: Array[ShaderMaterial] = []

var shafts: Array = []  # [{top, bottom, alpha, color, width}] como em ambient_lights
var _shaft_layer: Node2D
var _pool_layer: Node2D
var _dapples: Array[Sprite2D] = []
var _grade: ColorRect


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for spec in LAYERS:
		var sprite := Sprite2D.new()
		sprite.name = spec[0]
		sprite.centered = false
		sprite.texture = load(ART + str(spec[0]).to_lower() + ".png")
		sprite.position = spec[1]
		sprite.set_meta("home", spec[1])
		sprite.set_meta("depth", spec[2])
		add_child(sprite)
		_layers[spec[0]] = sprite
	_add_clouds()
	_layers.Ruins.material = _shader("water_flow", {"flow": Vector2(0, 1), "bands": 30.0, "grass_sway": 1.0})
	_layers.Ground.material = _shader("water_flow", {"flow": Vector2(-0.4, 1), "bands": 18.0, "strength": 0.22, "grass_sway": 1.0})
	_layers.Tree.material = _shader("foliage_sway", {"rooted": 0.42, "amount_px": 1.0})
	_add_sunlight()
	_add_glow_props()
	_add_particles()
	_add_grade()
	_apply_motion()


func _shader(file: String, params: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/menu/%s.gdshader" % file)
	for key in params: material.set_shader_parameter(key, params[key])
	_materials.append(material)
	return material


## Nuvens soltas que atravessam o céu devagar, atrás das ruínas.
func _add_clouds() -> void:
	var cloud_art: Texture2D = load(ART + "cloud.png")
	for i in 3:
		var cloud := Sprite2D.new()
		cloud.name = "Cloud%d" % i
		cloud.texture = cloud_art
		cloud.modulate = Color(1, 1, 1, 0.42 - i * 0.08)
		cloud.scale = Vector2.ONE * (1.0 - i * 0.2)
		cloud.position = Vector2(60 + i * 170, 26 + i * 18)
		cloud.set_meta("speed", 3.0 - i * 0.7)
		add_child(cloud)
		move_child(cloud, 1)  # logo depois do céu
		_clouds.append(cloud)


## Cristais e cogumelos que brilham (halo aditivo pulsando).
func _add_glow_props() -> void:
	var props := [
		["crystals", Vector2(404, 236), Color(0.45, 0.85, 1.0)],
		["mushrooms", Vector2(118, 252), Color(0.4, 0.9, 1.0)],
		["mushrooms", Vector2(372, 214), Color(0.4, 0.9, 1.0)],
	]
	var halo := LIGHTS.banded_light_texture(40)
	for i in props.size():
		var spec: Array = props[i]
		var prop := Sprite2D.new()
		prop.name = "%s%d" % [str(spec[0]).capitalize(), i]
		prop.texture = load(ART + str(spec[0]) + ".png")
		prop.position = spec[1]
		prop.scale = Vector2.ONE * (0.5 if spec[0] == "mushrooms" else 0.75)
		add_child(prop)
		_add_glow(spec[1] + Vector2(0, -4), spec[2], halo, i * 1.7)
	for spot: Vector2 in CRYSTAL_SPOTS:
		_add_glow(spot, Color(0.45, 0.85, 1.0), halo, spot.x)


func _add_glow(at: Vector2, color: Color, halo: Texture2D, phase: float) -> void:
	var glow := Sprite2D.new()
	glow.texture = halo
	glow.position = at
	glow.modulate = Color(color, 0.5)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	glow.set_meta("phase", phase)
	add_child(glow)
	_glows.append(glow)


## Raios de sol + poças de luz + manchas de sol (mesmo desenho do jogo).
func _add_sunlight() -> void:
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var tree_index: int = (_layers.Tree as Node).get_index()
	_pool_layer = Node2D.new()
	_pool_layer.name = "LightPools"
	_pool_layer.material = glow
	_pool_layer.draw.connect(_draw_pools)
	add_child(_pool_layer)
	move_child(_pool_layer, tree_index)
	for i in DAPPLE_SPOTS.size():
		var dapple := Sprite2D.new()
		dapple.name = "Dapple%d" % i
		dapple.texture = ImageTexture.create_from_image(LIGHTS.dapple_image(i, Vector2(-0.35, 0.25)))
		dapple.position = DAPPLE_SPOTS[i]
		dapple.scale = Vector2.ONE * 0.75
		dapple.material = glow
		dapple.modulate = Color(1.0, 0.92, 0.7, LIGHTS.DAPPLE_STRENGTH)
		add_child(dapple)
		move_child(dapple, tree_index)
		_dapples.append(dapple)
	_shaft_layer = Node2D.new()
	_shaft_layer.name = "SunShafts"
	_shaft_layer.material = glow
	_shaft_layer.draw.connect(_draw_shafts)
	add_child(_shaft_layer)
	_update_shafts()


func _update_shafts() -> void:
	shafts.clear()
	var warm := Color(1.0, 0.82, 0.5)
	for i in SHAFT_FEET.size():
		var foot: Vector2 = SHAFT_FEET[i]
		shafts.append({"top": foot - SUN_DIR * 230.0, "bottom": foot, "color": warm, "width": 0.55 + 0.15 * (i % 2),
			"alpha": 0.17 * (0.75 + 0.25 * sin(age * 0.45 + i * 1.3))})
	_shaft_layer.queue_redraw()
	_pool_layer.queue_redraw()


## Feixe em seções com bordas transparentes (igual a ambient_lights._draw_shafts).
func _draw_shafts() -> void:
	for shaft in shafts:
		var top: Vector2 = shaft.top
		var bottom: Vector2 = shaft.bottom
		var across := (bottom - top).orthogonal().normalized()
		var c: Color = shaft.color
		var a: float = shaft.alpha
		var w: float = shaft.width
		var stations := [[0.0, 6.0 * w, 0.0], [0.3, 14.0 * w, 0.55], [0.6, 24.0 * w, 1.0], [1.0, 40.0 * w, 0.0]]
		for k in stations.size() - 1:
			var s0: Array = stations[k]
			var s1: Array = stations[k + 1]
			var p0 := top.lerp(bottom, s0[0])
			var p1 := top.lerp(bottom, s1[0])
			var core0 := Color(c, a * float(s0[2]))
			var core1 := Color(c, a * float(s1[2]))
			var clear := Color(c, 0.0)
			for side in [-1.0, 1.0]:
				_shaft_layer.draw_polygon(
					PackedVector2Array([p0, p0 + across * float(s0[1]) * side, p1 + across * float(s1[1]) * side, p1]),
					PackedColorArray([core0, clear, clear, core1]))


## Poça achatada no pé de cada raio: 3 elipses em degraus (igual ao jogo).
func _draw_pools() -> void:
	for shaft in shafts:
		var c: Color = shaft.color
		var w: float = shaft.width
		var at: Vector2 = (shaft.bottom as Vector2).lerp(shaft.top, 0.12).round()
		var axis: Vector2 = ((shaft.bottom as Vector2) - (shaft.top as Vector2)).normalized()
		var side := axis.orthogonal()
		for ring in [[1.0, 0.35], [0.66, 0.4], [0.36, 0.5]]:
			var length: float = 24.0 * w * float(ring[0])
			var thin: float = 6.0 * w * float(ring[0])
			var points := PackedVector2Array()
			for k in 20:
				var ang := TAU * float(k) / 20.0
				points.append((at + axis * cos(ang) * length + side * sin(ang) * thin).round())
			_pool_layer.draw_colored_polygon(points, Color(c.r, c.g * 0.95, c.b * 0.7, float(shaft.alpha) * 2.2 * float(ring[1])))


## Grade de cor do mundo (mesmo shader e perfil de horário do jogo), sob a interface.
func _add_grade() -> void:
	var material := ShaderMaterial.new()
	material.shader = GRADE.SHADER
	var profile := GRADE.profile_at(MENU_MINUTE)
	for key in profile: material.set_shader_parameter(key, profile[key])
	material.set_shader_parameter("exposure", 1.0)
	material.set_shader_parameter("glow_strength", 0.0)
	_grade = ColorRect.new()
	_grade.name = "Grade"
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grade.material = material
	_grade.position = Vector2(-16, -16)
	_grade.size = SIZE + Vector2(32, 32)
	add_child(_grade)


static func _halo_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.55))
	gradient.set_color(1, Color(1, 1, 1, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 40
	texture.height = 40
	return texture


func _add_particles() -> void:
	# Vaga-lumes sobre o vale.
	_particles.append(_emitter("Fireflies", Vector2(250, 200), Vector2(220, 60), 22, 5.0,
		Color(1.0, 0.95, 0.55), 1.0, Vector2.ZERO, 6.0, true))
	# Folhas caindo da copa.
	var leaves := _emitter("Leaves", Vector2(70, 40), Vector2(70, 25), 7, 7.0,
		Color(0.55, 0.75, 0.3), 2.0, Vector2(4, 9), 8.0, false)
	leaves.color_initial_ramp = _ramp([Color(0.45, 0.7, 0.25), Color(0.85, 0.6, 0.25)])
	_particles.append(leaves)
	# Névoa e respingos na base da cachoeira.
	_particles.append(_emitter("Mist", WATERFALL_FOOT, Vector2(14, 3), 26, 1.6,
		Color(0.92, 0.97, 1.0), 2.0, Vector2(0, -10), 10.0, false))
	# Faíscas mágicas subindo dos cristais.
	for i in CRYSTAL_SPOTS.size() + 1:
		var at: Vector2 = CRYSTAL_SPOTS[i] if i < CRYSTAL_SPOTS.size() else Vector2(404, 226)
		_particles.append(_emitter("Sparks%d" % i, at, Vector2(6, 4), 5, 2.4,
			Color(0.6, 0.95, 1.0), 1.0, Vector2(0, -7), 3.0, true))
	# Partículas de luz que surgem e somem no ar (pólen dourado nos raios de sol).
	_particles.append(_emitter("LightMotes", Vector2(300, 140), Vector2(170, 90), 26, 4.0,
		Color(1.0, 0.9, 0.6), 1.0, Vector2(2, -2), 3.0, true))
	# Vento: traços finos e claros atravessando o vale da esquerda para a direita.
	var wind := _emitter("Wind", Vector2(200, 150), Vector2(220, 90), 6, 2.6,
		Color(1.0, 1.0, 1.0, 0.35), 1.0, Vector2.ZERO, 0.0, false)
	var streak := Image.create(10, 1, false, Image.FORMAT_RGBA8)
	for x in 10: streak.set_pixel(x, 0, Color(1, 1, 1, 0.2 + 0.08 * x))
	wind.texture = ImageTexture.create_from_image(streak)
	wind.direction = Vector2.RIGHT
	wind.spread = 4.0
	wind.initial_velocity_min = 70.0
	wind.initial_velocity_max = 110.0
	_particles.append(wind)


func _emitter(node_name: String, at: Vector2, half: Vector2, amount: int, life: float,
		color: Color, size_px: float, gravity: Vector2, spread_speed: float, glow: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = node_name
	p.position = at
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.randomness = 0.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = half
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = spread_speed * 0.3
	p.initial_velocity_max = spread_speed
	p.gravity = gravity
	p.scale_amount_min = size_px
	p.scale_amount_max = size_px
	p.color = color
	p.color_ramp = _ramp([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	if glow:
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = additive
	add_child(p)
	return p


static func _ramp(colors: Array) -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array()
	gradient.colors = PackedColorArray()
	for i in colors.size():
		gradient.add_point(float(i) / maxf(1.0, colors.size() - 1.0), colors[i])
	return gradient


func _apply_motion() -> void:
	if not is_inside_tree(): return
	for material in _materials: material.set_shader_parameter("speed", 0.0 if reduce_motion else 1.0)
	for p in _particles: p.speed_scale = 0.0 if reduce_motion else 1.0
	set_process(not reduce_motion)


func _process(delta: float) -> void:
	age += delta
	for cloud in _clouds:
		cloud.position.x += float(cloud.get_meta("speed")) * delta
		if cloud.position.x > SIZE.x + 80: cloud.position.x = -80
	for glow in _glows:
		glow.modulate.a = 0.38 + 0.2 * sin(age * 1.6 + float(glow.get_meta("phase")))
	# Vento nas copas: as manchas de sol piscam em onda, como no jogo.
	for i in _dapples.size():
		_dapples[i].modulate.a = LIGHTS.DAPPLE_STRENGTH * (0.7 + 0.3 * sin(age * 1.1 - _dapples[i].position.x * 0.05))
	_update_shafts()
	# Camadas paradas (o usuário achou estranho o parallax): só o vento anima a cena.

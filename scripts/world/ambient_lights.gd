extends Node2D
## Fontes de luz locais que acompanham o GameClock: fogueira (luz quente, chama e
## brasas), cogumelos luminosos e uma luz suave de visibilidade em volta do jogador.
## Instalado pelo DayNightLighting, como o DayShadows. Luzes em faixas (sem degradê
## borrado) para combinar com a pixel art; quantidade limitada por desempenho.

const MAX_GLOW_LIGHTS := 12
const MAX_DAPPLES := 35  # = células da janela 7×5
const MAX_SLIME_LIGHTS := 10
## Enxames de vagalumes (margens d'água primeiro, depois vegetação) e brilhos
## mágicos raros em flores/cogumelos especiais, reposicionados perto do jogador.
const MAX_SWARMS := 6
const MAX_GLINTS := 5
const SPOT_RADIUS := 720.0
const SPOT_SEPARATION := 90.0
const GLINT_LIFT := Vector2(0, -8)
const SHADOWS := preload("res://scripts/world/day_shadows.gd")
## id de slime (no caminho dos SpriteFrames) -> [cor, escala, faíscas]
const SLIME_GLOWS := {
	"brasinha": [Color(1.0, 0.5, 0.2), 1.1, true],
	"gelito": [Color(0.55, 0.82, 1.0), 0.9, false],
}
## Mancha de sol: textura pequena em pixel art, 1 pixel = DAPPLE_PIXEL px do mundo.
const DAPPLE_PIXEL := 2
const DAPPLE_SIZE := 56
## Força máxima (alfa aditivo) do miolo da mancha; o contorno usa metade.
const DAPPLE_STRENGTH := 0.3
## Variantes de recorte; cada mancha escolhe a sua pelo hash da posição no mundo.
const DAPPLE_VARIANTS := 12
## Distância (px) em que o jogador dentro de uma mancha recebe luz fraca.
const DAPPLE_PLAYER_REACH := 30.0
## Grade de mundo das manchas de sol: cada célula tem posição fixa (hash), não segue a câmera.
const DAPPLE_CELL := 240.0
## Janela de células em volta do jogador: cobre a vista toda (960×540 com zoom 0,8 =
## 1200×675 px de mundo) com folga,
## para as manchas nunca surgirem/sumirem dentro da vista ao trocar de célula.
const DAPPLE_WINDOW := Vector2i(3, 2)
const GLOW_TEXTURE_SUFFIX := "mushroom_glow.png"
const CAMPFIRE_NAME := "CookingStation"
const DUSK_START := 16.5 * 60.0
const DUSK_END := 19.5 * 60.0
const DAWN_START := 4.5 * 60.0
const DAWN_END := 6.5 * 60.0
const CAMPFIRE_COLOR := Color(1.0, 0.55, 0.25)
## Raio (px do mundo) da luz da fogueira: só o entorno, sem disco gigante no caminho.
const CAMPFIRE_RADIUS := 92.0
const GLOW_COLOR := Color(0.45, 0.95, 0.85)
const PLAYER_COLOR := Color(1.0, 0.96, 0.88)

var _region: Node
var _campfires: Array[PointLight2D] = []
var _fires: Array[CPUParticles2D] = []
var _embers: Array[CPUParticles2D] = []
var _glows: Array[PointLight2D] = []
var _player_light: PointLight2D
var _fireflies: CPUParticles2D
var _motes: CPUParticles2D
var _dapples: Array[Sprite2D] = []
var _dapple_strengths: PackedFloat32Array = []
var _dapple_cache: Dictionary = {}
var _dapple_material: CanvasItemMaterial
var _player_dapple_light: PointLight2D
var _dapple_anchor := Vector2.INF
var _slime_lights: Array[PointLight2D] = []
var _spots := {"water": [], "vegetation": [], "bloom": []}
var _spots_dirty := true
var _spot_anchor := Vector2.INF
var _swarms: Array[CPUParticles2D] = []
var _glints: Array[CPUParticles2D] = []
var _identity := 1.0
var _time := 0.0
var _light_texture: GradientTexture2D
var _soft_texture: GradientTexture2D


## 0 de dia, 1 à noite; rampas suaves no anoitecer e no amanhecer.
static func night_factor(minutes: float) -> float:
	var m := fposmod(minutes, 1440.0)
	if m >= DUSK_START:
		return smoothstep(DUSK_START, DUSK_END, m)
	if m <= DAWN_END:
		return 1.0 - smoothstep(DAWN_START, DAWN_END, m)
	return 0.0


## Aberturas entre folhas em pixel art: 6–9 furos pequenos e nítidos (2 faixas de
## alfa), alongados na direção da sombra conforme o sol baixa. A direção é desenhada
## nos pixels — o sprite nunca gira, então a grade de pixels continua alinhada.
static func dapple_image(variant: int, sun: Vector2) -> Image:
	var size := DAPPLE_SIZE
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 + variant * 104729
	var along := sun.normalized() if sun.length() > 0.05 else Vector2.DOWN
	var across := along.orthogonal()
	var stretch := 1.0 + 1.3 * clampf((sun.length() - 0.15) / 1.0, 0.0, 1.0)
	var center := Vector2(size, size) * 0.5
	var holes: Array = []
	# Aglomerado irregular: alguns furos grandes no miolo, pequenos espalhados.
	for i in rng.randi_range(5, 9):
		var spread := rng.randf_range(3.0, 11.0)
		var offset := Vector2.from_angle(rng.randf() * TAU) * spread
		holes.append([offset, rng.randf_range(1.3, 3.6) * (1.25 if spread < 5.0 else 1.0)])
	# Folhas na frente da abertura: recortam os furos em crescentes e bordas tortas.
	var leaves: Array = []
	for i in rng.randi_range(2, 4):
		leaves.append([Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(2.0, 9.0), rng.randf_range(1.6, 3.2)])
	var grain := rng.randi()
	# Só percorre a caixa de cada furo (barato o bastante para gerar em jogo).
	var best := PackedFloat32Array()
	best.resize(size * size)
	best.fill(9.0)
	for hole in holes:
		var offset: Vector2 = hole[0]
		var radius: float = hole[1]
		var at := center + along * offset.dot(along) * stretch + across * offset.dot(across)
		var reach := int(ceil(radius * stretch)) + 1
		for y in range(maxi(0, int(at.y) - reach), mini(size, int(at.y) + reach + 1)):
			for x in range(maxi(0, int(at.x) - reach), mini(size, int(at.x) + reach + 1)):
				var d := Vector2(x, y) + Vector2(0.5, 0.5) - at
				var value := Vector2(d.dot(along) / stretch, d.dot(across)).length() / radius
				# Borda irregular controlada: ±12% por pixel, determinística.
				value += (float(hash(Vector3i(x, y, grain)) % 100) / 100.0 - 0.5) * 0.24
				var index := y * size + x
				if value < best[index]: best[index] = value
	for leaf in leaves:
		var leaf_at: Vector2 = center + along * (leaf[0] as Vector2).dot(along) * stretch + across * (leaf[0] as Vector2).dot(across)
		var leaf_r: float = leaf[1]
		var reach := int(ceil(leaf_r * stretch)) + 1
		for y in range(maxi(0, int(leaf_at.y) - reach), mini(size, int(leaf_at.y) + reach + 1)):
			for x in range(maxi(0, int(leaf_at.x) - reach), mini(size, int(leaf_at.x) + reach + 1)):
				var d := Vector2(x, y) + Vector2(0.5, 0.5) - leaf_at
				if Vector2(d.dot(along) / stretch, d.dot(across)).length() < leaf_r:
					best[y * size + x] = 9.0
	for index in best.size():
		var value := best[index]
		if value < 1.0:
			image.set_pixel(index % size, index / size, Color(1, 1, 1, 1.0 if value < 0.72 else 0.5))
	return image


## Textura de mancha em cache por variante e direção/comprimento do sol (em degraus).
func dapple_texture_for(variant: int, sun: Vector2) -> ImageTexture:
	var angle_step := int(round(sun.angle() / (TAU / 16.0))) if sun.length() > 0.05 else 99
	var length_step := int(round(clampf(sun.length(), 0.0, 1.4) * 4.0))
	var key := Vector3i(variant, angle_step, length_step)
	if not _dapple_cache.has(key):
		var quantized := Vector2.from_angle(angle_step * TAU / 16.0) * (length_step / 4.0) if angle_step != 99 else Vector2.ZERO
		_dapple_cache[key] = ImageTexture.create_from_image(dapple_image(variant, quantized))
	return _dapple_cache[key]


## Textura radial com poucas faixas de intensidade (estilo pixel art).
static func banded_light_texture(size: int, banded: bool = true) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT if banded else Gradient.GRADIENT_INTERPOLATE_CUBIC
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.55, 0.78, 0.95])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.42),
		Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = size
	texture.height = size
	return texture


func _ready() -> void:
	name = "AmbientLights"
	_region = get_parent().get_parent()
	_light_texture = banded_light_texture(128)
	_soft_texture = banded_light_texture(128, false)
	_dapple_material = CanvasItemMaterial.new()
	_dapple_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	call_deferred("_scan")
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)


func campfire_lights() -> Array[PointLight2D]: return _campfires
func campfire_fire() -> Array[CPUParticles2D]: return _fires
func campfire_embers() -> Array[CPUParticles2D]: return _embers


## Queda suave e rápida (≈ quadrática, interpolação cúbica): sem anéis concêntricos.
static func campfire_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.35, 0.55, 0.75, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.78), Color(1, 1, 1, 0.42),
		Color(1, 1, 1, 0.19), Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture
func glow_lights() -> Array[PointLight2D]: return _glows
func player_light() -> PointLight2D: return _player_light
func fireflies() -> CPUParticles2D: return _fireflies
func motes() -> CPUParticles2D: return _motes
func dapples() -> Array[Sprite2D]: return _dapples
func dapple_strength(index: int) -> float: return _dapple_strengths[index] if index < _dapple_strengths.size() else 0.0
func slime_lights() -> Array[PointLight2D]: return _slime_lights
func firefly_swarms() -> Array[CPUParticles2D]: return _swarms
func magic_glints() -> Array[CPUParticles2D]: return _glints
func spots(kind: String) -> Array: return _spots.get(kind, [])


## Onde vagalumes e brilhos se concentram, pelo nome da textura.
static func classify_spot(path: String) -> String:
	var p := path.to_lower()
	if "reed" in p or "lily" in p or "water" in p: return "water"
	if "bush" in p or "fern" in p or "shrub" in p: return "vegetation"
	if "flower" in p or "mushroom" in p: return "bloom"
	return ""


## Só ~1 em 11 flores/cogumelos é "especial" (hash da posição: sempre o mesmo).
static func is_special_bloom(at: Vector2) -> bool:
	return posmod(hash(Vector2i(at.round())), 11) == 0


## Pontos mais próximos do centro, até count, com distância mínima entre si.
static func nearest_spots(points: Array, center: Vector2, count: int, taken: Array = [], separation: float = SPOT_SEPARATION) -> Array[Vector2]:
	var near := points.filter(func(p): return p.distance_to(center) <= SPOT_RADIUS)
	near.sort_custom(func(a, b): return a.distance_squared_to(center) < b.distance_squared_to(center))
	var picked: Array[Vector2] = []
	for point in near:
		if picked.size() >= count:
			break
		var free := true
		for other in picked + taken:
			if point.distance_to(other) < separation:
				free = false
				break
		if free:
			picked.append(point)
	return picked


## Força da luz filtrada por região: Floresta misteriosa, Clareira suave.
static func region_identity(region_name: String) -> float:
	if region_name.contains("Floresta"): return 1.3
	if region_name.contains("Vale"): return 1.0
	return 0.75


## Cor das motas mágicas: manhã dourada, tarde âmbar, anoitecer rosa-violeta.
static func mote_color(minutes: float) -> Color:
	var m := fposmod(minutes, 1440.0)
	var morning := Color(1.0, 0.92, 0.6, 0.85)
	var afternoon := Color(1.0, 0.78, 0.45, 0.85)
	var dusk := Color(1.0, 0.62, 0.9, 0.9)
	if m < 12 * 60.0:
		return morning
	if m < 16.5 * 60.0:
		return morning.lerp(afternoon, smoothstep(12 * 60.0, 16.5 * 60.0, m))
	return afternoon.lerp(dusk, smoothstep(16.5 * 60.0, 19.0 * 60.0, m))


## Mais vagalumes na Floresta e no Vale; poucos na Clareira (visibilidade para iniciantes).
static func firefly_amount(region_name: String) -> int:
	if region_name.contains("Floresta"): return 28
	if region_name.contains("Vale"): return 20
	return 8


func _process(delta: float) -> void:
	apply_time(GameClock.get_hour() * 60.0 + GameClock.get_minute(), delta)


func apply_time(minutes: float, delta: float) -> void:
	_time += delta
	var night := night_factor(minutes)
	var flicker := 1.0 + 0.09 * sin(_time * 7.3) + 0.05 * sin(_time * 13.1 + 1.7)
	# A fogueira só domina depois que o sol se põe; no anoitecer ainda é discreta.
	var fire_glow := smoothstep(0.55, 1.0, night)
	for light in _campfires:
		if is_instance_valid(light):
			light.energy = 0.95 * fire_glow * flicker
	for fire in _fires:
		if is_instance_valid(fire):
			fire.emitting = night > 0.15
	for embers in _embers:
		if is_instance_valid(embers):
			embers.emitting = night > 0.15
	for light in _glows:
		if is_instance_valid(light):
			light.energy = 0.55 * night
	if is_instance_valid(_player_light):
		_player_light.energy = 0.22 * night
	if is_instance_valid(_fireflies):
		_fireflies.emitting = night > 0.2
	if is_instance_valid(_motes):
		_motes.emitting = night < 0.75
		_motes.color = mote_color(minutes)
	for i in _slime_lights.size():
		var light := _slime_lights[i]
		if is_instance_valid(light):
			var pulse := 0.86 + 0.09 * sin(_time * (2.3 + i * 0.37)) + 0.05 * sin(_time * 5.9 + i)
			light.energy = (0.25 + 0.45 * night) * pulse
	_update_dapples(minutes, night)
	_update_spots(night)


func _scan() -> void:
	if not is_instance_valid(_region):
		return
	for node in _region.find_children("*", "", true, false):
		_consider(node)
	var player := _region.get_node_or_null("Player")
	if player and not is_instance_valid(_player_light):
		_player_light = _make_light(PLAYER_COLOR, 2.6)
		# Luz de visibilidade: degradê suave (faixas viram anéis em chão escuro).
		_player_light.texture = banded_light_texture(128, false)
		_player_light.name = "VisibilityLight"
		player.add_child(_player_light)
		# Poucos vagalumes soltos; o grosso fica nos enxames da vegetação e da água.
		_fireflies = _make_fireflies(maxi(4, firefly_amount(str(_region.name)) / 3))
		player.add_child(_fireflies)
		for i in MAX_SWARMS:
			var swarm := _make_fireflies(maxi(3, firefly_amount(str(_region.name)) / 5))
			swarm.name = "FireflySwarm%d" % i
			swarm.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			swarm.emission_sphere_radius = 28.0
			swarm.initial_velocity_max = 6.0
			swarm.scale_amount_min = 2.0
			swarm.scale_amount_max = 3.0
			swarm.z_as_relative = false
			swarm.z_index = 1
			swarm.visible = false
			add_child(swarm)
			_swarms.append(swarm)
		for i in MAX_GLINTS:
			var glint := _make_glint()
			glint.name = "MagicGlint%d" % i
			add_child(glint)
			_glints.append(glint)
		_identity = region_identity(str(_region.name))
		_motes = _make_motes(int(round(22 * _identity)))
		player.add_child(_motes)
		for i in MAX_DAPPLES:
			add_child(_make_dapple(i))
		# Luz fraca no jogador quando ele atravessa uma mancha de sol.
		_player_dapple_light = _make_light(Color(1.0, 0.93, 0.75), 0.45)
		_player_dapple_light.texture = _soft_texture
		_player_dapple_light.name = "DappleLight"
		_player_dapple_light.position = Vector2(0, -12)
		player.add_child(_player_dapple_light)
	apply_time(GameClock.get_hour() * 60.0 + GameClock.get_minute(), 0.0)


func _on_node_added(node: Node) -> void:
	if is_instance_valid(_region) and _region.is_ancestor_of(node):
		_consider.call_deferred(node)


func _consider(node: Node) -> void:
	if not is_instance_valid(node):
		return
	_consider_spot(node)
	if node.has_meta("ambient_light"):
		return
	if node.name == CAMPFIRE_NAME and node is Node2D:
		node.set_meta("ambient_light", true)
		_add_campfire(node)
	elif node is AnimatedSprite2D and _slime_lights.size() < MAX_SLIME_LIGHTS and node.sprite_frames:
		var path: String = node.sprite_frames.resource_path
		for id in SLIME_GLOWS:
			if path.contains(id):
				node.set_meta("ambient_light", true)
				var spec: Array = SLIME_GLOWS[id]
				var light := _make_light(spec[0], spec[1])
				light.texture = _soft_texture
				light.name = "SlimeGlow"
				node.add_child(light)
				_slime_lights.append(light)
				node.add_child(_make_sparks(spec[2]))
				break
	elif node is Sprite2D and _glows.size() < MAX_GLOW_LIGHTS:
		var texture: Texture2D = node.texture
		if texture and texture.resource_path.ends_with(GLOW_TEXTURE_SUFFIX):
			node.set_meta("ambient_light", true)
			var light := _make_light(GLOW_COLOR, 0.55)
			light.texture = _soft_texture
			light.name = "GlowLight"
			node.add_child(light)
			_glows.append(light)


func _consider_spot(node: Node) -> void:
	if node.has_meta("ambient_spot") or not node is Node2D:
		return
	var kind := ""
	if node.is_in_group("water_sources"):
		kind = "water"
	elif node is Sprite2D and node.texture:
		kind = classify_spot(node.texture.resource_path)
		if kind == "bloom" and not is_special_bloom(node.global_position):
			kind = ""
	if kind.is_empty():
		return
	node.set_meta("ambient_spot", true)
	_spots[kind].append((node as Node2D).global_position.round())
	_spots_dirty = true


func _update_spots(night: float) -> void:
	if _swarms.is_empty() or not is_instance_valid(_region):
		return
	var player := _region.get_node_or_null("Player") as Node2D
	var center := player.global_position if player else Vector2.ZERO
	var cell := Vector2(floorf(center.x / DAPPLE_CELL), floorf(center.y / DAPPLE_CELL))
	if _spots_dirty or cell != _spot_anchor:
		_spots_dirty = false
		_spot_anchor = cell
		var water := nearest_spots(_spots["water"], center, MAX_SWARMS)
		var picks := water + nearest_spots(_spots["vegetation"], center, MAX_SWARMS - water.size(), water)
		for i in _swarms.size():
			_swarms[i].visible = i < picks.size()
			if _swarms[i].visible:
				_swarms[i].global_position = picks[i]
		var blooms := nearest_spots(_spots["bloom"], center, MAX_GLINTS, [], 60.0)
		for i in _glints.size():
			_glints[i].visible = i < blooms.size()
			if _glints[i].visible:
				_glints[i].global_position = blooms[i] + GLINT_LIFT
	for swarm in _swarms:
		swarm.emitting = swarm.visible and night > 0.2
	for i in _glints.size():
		# Cintila de vez em quando, cada flor no seu ritmo; mais comum à noite.
		_glints[i].emitting = _glints[i].visible and sin(_time * (0.45 + 0.04 * i) + i * 2.1) > 0.55 - 0.15 * night


func _make_glint() -> CPUParticles2D:
	var glint := CPUParticles2D.new()
	glint.amount = 3
	glint.lifetime = 1.2
	glint.local_coords = false
	glint.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	glint.emission_sphere_radius = 6.0
	glint.direction = Vector2.UP
	glint.spread = 60.0
	glint.gravity = Vector2(0, -8)
	glint.initial_velocity_min = 2.0
	glint.initial_velocity_max = 6.0
	glint.scale_amount_min = 1.0
	glint.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.6, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(0.85, 1.0, 1.0, 1.0), Color(1.0, 0.8, 1.0, 0.6), Color(1, 1, 1, 0)])
	glint.color_ramp = ramp
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glint.material = glow
	glint.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glint.z_as_relative = false
	glint.z_index = 1
	glint.visible = false
	glint.emitting = false
	return glint


func _add_campfire(station: Node2D) -> void:
	var light := _make_light(CAMPFIRE_COLOR, 1.0)
	light.texture = campfire_light_texture()
	light.texture_scale = CAMPFIRE_RADIUS * 2.0 / 256.0
	light.name = "CampfireLight"
	light.position = Vector2(0, -14)
	station.add_child(light)
	_campfires.append(light)
	var fire := CPUParticles2D.new()
	fire.name = "CampfireFlame"
	fire.position = Vector2(0, -14)
	fire.amount = 24
	fire.lifetime = 0.75
	fire.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	fire.emission_sphere_radius = 5.0
	fire.direction = Vector2.UP
	fire.spread = 18.0
	fire.gravity = Vector2(0, -24)
	fire.initial_velocity_min = 8.0
	fire.initial_velocity_max = 18.0
	fire.scale_amount_min = 2.0
	fire.scale_amount_max = 4.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.35, 0.75, 1.0])
	ramp.colors = PackedColorArray([
		Color(1.0, 0.95, 0.55, 1.0), Color(1.0, 0.62, 0.2, 0.95),
		Color(0.85, 0.25, 0.12, 0.7), Color(0.4, 0.12, 0.1, 0.0),
	])
	fire.color_ramp = ramp
	fire.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fire.emitting = false
	station.add_child(fire)
	_fires.append(fire)
	station.add_child(_make_embers())


## Brasas que sobem devagar, oscilam e apagam; faíscas raras mais rápidas.
func _make_embers() -> CPUParticles2D:
	var embers := CPUParticles2D.new()
	embers.name = "CampfireEmbers"
	embers.position = Vector2(0, -18)
	embers.amount = 10
	embers.lifetime = 2.4
	embers.local_coords = false
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 6.0
	embers.direction = Vector2.UP
	embers.spread = 25.0
	embers.gravity = Vector2(0, -10)
	embers.initial_velocity_min = 10.0
	embers.initial_velocity_max = 28.0
	embers.tangential_accel_min = -12.0
	embers.tangential_accel_max = 12.0
	embers.damping_min = 2.0
	embers.damping_max = 5.0
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.6, 1.0])
	ramp.colors = PackedColorArray([Color(1.0, 0.95, 0.6, 0.0), Color(1.0, 0.8, 0.35, 1.0), Color(1.0, 0.45, 0.15, 0.7), Color(0.6, 0.15, 0.05, 0.0)])
	embers.color_ramp = ramp
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	embers.material = glow
	embers.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	embers.emitting = false
	_embers.append(embers)
	return embers


func _make_light(color: Color, scale: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _light_texture
	light.texture_scale = scale
	light.color = color
	light.energy = 0.0
	light.shadow_enabled = false
	return light


func _make_fireflies(amount: int) -> CPUParticles2D:
	var flies := CPUParticles2D.new()
	flies.name = "Fireflies"
	flies.amount = amount
	flies.lifetime = 6.0
	flies.preprocess = 3.0
	flies.local_coords = false
	flies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flies.emission_rect_extents = Vector2(460, 260)
	flies.direction = Vector2.UP
	flies.spread = 180.0
	flies.gravity = Vector2.ZERO
	flies.initial_velocity_min = 3.0
	flies.initial_velocity_max = 9.0
	flies.scale_amount_min = 1.5
	flies.scale_amount_max = 2.5
	flies.tangential_accel_min = -8.0
	flies.tangential_accel_max = 8.0
	flies.damping_min = 1.0
	flies.damping_max = 3.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	ramp.colors = PackedColorArray([
		Color(0.8, 1.0, 0.45, 0.0), Color(0.85, 1.0, 0.5, 0.9), Color(0.6, 0.9, 0.35, 0.25),
		Color(0.9, 1.0, 0.55, 0.85), Color(0.8, 1.0, 0.45, 0.0),
	])
	flies.color_ramp = ramp
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	flies.material = glow
	flies.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flies.emitting = false
	return flies


## Manchas de sol nítidas presas ao mundo (grade de células com hash), no plano do
## chão, mais longas com sol baixo; zero à noite.
func _make_dapple(index: int) -> Sprite2D:
	var dapple := Sprite2D.new()
	dapple.name = "SunDapple%d" % index
	dapple.top_level = true
	dapple.z_as_relative = false
	dapple.z_index = -1
	dapple.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dapple.material = _dapple_material
	dapple.scale = Vector2(DAPPLE_PIXEL, DAPPLE_PIXEL)
	dapple.visible = false
	var dust := _make_sunbeam_dust()
	dust.emission_sphere_radius = 10.0  # o sprite tem escala 2
	dapple.add_child(dust)
	_dapples.append(dapple)
	_dapple_strengths.append(0.0)
	return dapple


func _update_dapples(minutes: float, night: float) -> void:
	if _dapples.is_empty() or not is_instance_valid(_region):
		return
	var player := _region.get_node_or_null("Player") as Node2D
	var center := player.global_position if player else Vector2.ZERO
	var cell := Vector2(floorf(center.x / DAPPLE_CELL), floorf(center.y / DAPPLE_CELL))
	if _dapple_anchor != cell:
		_dapple_anchor = cell
		var homes := dapple_homes(center, _dapples.size(), dapple_density(str(_region.name)))
		for i in _dapples.size():
			_dapples[i].set_meta("home", homes[i] if i < homes.size() else Vector2.INF)
	var sun: Vector2 = SHADOWS.profile_at(minutes)["vector"]
	var low_sun := clampf((sun.length() - 0.15) / 1.0, 0.0, 1.0)
	var day := 1.0 - night
	var warm := Color(1.0, 0.95, 0.8).lerp(Color(1.0, 0.8, 0.55), smoothstep(13 * 60.0, 17.5 * 60.0, fposmod(minutes, 1440.0)))
	var near_player := 0.0
	for i in _dapples.size():
		var dapple := _dapples[i]
		var home: Vector2 = dapple.get_meta("home", Vector2.INF)
		var strength := 0.0 if home == Vector2.INF else DAPPLE_STRENGTH * day * (0.65 + 0.35 * low_sun) * _identity * (0.85 + 0.15 * sin(_time * 0.7 + i))
		_dapple_strengths[i] = strength
		dapple.visible = strength > 0.01
		var dust := dapple.get_node_or_null("SunbeamDust") as CPUParticles2D
		if dust:
			dust.emitting = day > 0.5
		if not dapple.visible:
			continue
		# Folhas balançando: 1–2 px, na grade de pixels, sem sair do lugar no mundo.
		dapple.global_position = (home + Vector2(sin(_time * 0.9 + i), cos(_time * 0.7 + i * 1.7)) * 1.5).round()
		dapple.texture = dapple_texture_for(posmod(hash(Vector2i(home)), DAPPLE_VARIANTS), sun)
		dapple.modulate = Color(warm.r, warm.g, warm.b, strength)
		if player:
			near_player = maxf(near_player, strength * (1.0 - clampf(player.global_position.distance_to(home) / DAPPLE_PLAYER_REACH, 0.0, 1.0)))
	if is_instance_valid(_player_dapple_light):
		_player_dapple_light.color = warm
		_player_dapple_light.energy = 0.9 * near_player


func _make_motes(amount: int) -> CPUParticles2D:
	var motes := _make_fireflies(amount)
	motes.name = "MagicMotes"
	motes.lifetime = 8.0
	motes.gravity = Vector2(0, -2)
	motes.initial_velocity_min = 1.0
	motes.initial_velocity_max = 4.0
	motes.scale_amount_min = 1.5
	motes.scale_amount_max = 2.5
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	motes.color_ramp = ramp
	return motes


func _make_sparks(fire: bool) -> CPUParticles2D:
	var sparks := CPUParticles2D.new()
	sparks.name = "SlimeSparks"
	sparks.amount = 7 if fire else 5
	sparks.lifetime = 0.9
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 6.0
	sparks.direction = Vector2.UP
	sparks.spread = 35.0
	sparks.gravity = Vector2(0, -18) if fire else Vector2(0, -4)
	sparks.lifetime = 0.9 if fire else 1.6
	sparks.local_coords = false  # deixa um pequeno rastro ao se mover
	sparks.initial_velocity_min = 6.0
	sparks.initial_velocity_max = 14.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1.0, 0.85, 0.4, 1.0), Color(1.0, 0.35, 0.1, 0.0)]) if fire else PackedColorArray([Color(0.8, 0.95, 1.0, 0.9), Color(0.5, 0.75, 1.0, 0.0)])
	sparks.color_ramp = ramp
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sparks.material = glow
	return sparks


## Posições fixas no mundo para as manchas de sol: no máximo uma por célula da
## janela em volta do jogador; a célula tem mancha conforme o hash e a densidade
## da região. Mesmo lugar sempre que o jogador volta; as mais distantes saem primeiro.
static func dapple_homes(center: Vector2, count: int, density: float = 0.75) -> Array[Vector2]:
	var homes: Array[Vector2] = []
	var base := Vector2(floorf(center.x / DAPPLE_CELL), floorf(center.y / DAPPLE_CELL))
	var cells: Array[Vector2] = []
	for dy in range(-DAPPLE_WINDOW.y, DAPPLE_WINDOW.y + 1):
		for dx in range(-DAPPLE_WINDOW.x, DAPPLE_WINDOW.x + 1):
			cells.append(base + Vector2(dx, dy))
	cells.sort_custom(func(a, b): return a.distance_squared_to(base) < b.distance_squared_to(base))
	for cell in cells:
		if homes.size() >= count:
			break
		var h := hash(Vector2i(cell))
		if posmod(h, 100) >= int(density * 100.0):
			continue  # célula na sombra da copa: variação natural
		var jitter := Vector2(float((h >> 8) & 255) / 255.0, float((h >> 16) & 255) / 255.0)
		homes.append(((cell + jitter) * DAPPLE_CELL).round())
	return homes


## Densidade de aberturas na copa: Floresta fechada mais salpicada, Vale aberto menos.
static func dapple_density(region_name: String) -> float:
	if region_name.contains("Floresta"): return 0.85
	if region_name.contains("Vale"): return 0.55
	return 0.65


func _make_sunbeam_dust() -> CPUParticles2D:
	var dust := CPUParticles2D.new()
	dust.name = "SunbeamDust"
	dust.amount = 4
	dust.lifetime = 5.0
	dust.preprocess = 2.5
	dust.local_coords = false
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 20.0
	dust.gravity = Vector2(1.5, -1.0)
	dust.initial_velocity_min = 0.5
	dust.initial_velocity_max = 2.5
	dust.spread = 180.0
	dust.tangential_accel_min = -1.5
	dust.tangential_accel_max = 1.5
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	ramp.colors = PackedColorArray([Color(1.0, 0.9, 0.55, 0.0), Color(1.0, 0.92, 0.6, 0.8), Color(1.0, 0.85, 0.5, 0.45), Color(1.0, 0.9, 0.55, 0.0)])
	dust.color_ramp = ramp
	# Poeira no ar: acima do chão (a mancha fica em z -1), abaixo da copa ordenada por Y.
	dust.z_as_relative = false
	dust.z_index = 0
	dust.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	dust.material = glow
	dust.emitting = false
	return dust

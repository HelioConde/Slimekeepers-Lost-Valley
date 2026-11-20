extends Node2D
## Fontes de luz locais que acompanham o GameClock: fogueira (luz quente, chama e
## brasas), cogumelos luminosos e uma luz suave de visibilidade em volta do jogador.
## Instalado pelo DayNightLighting, como o DayShadows. Luzes em faixas (sem degradê
## borrado) para combinar com a pixel art; quantidade limitada por desempenho.

const MAX_GLOW_LIGHTS := 12
const GLOW_TEXTURE_SUFFIX := "mushroom_glow.png"
const CAMPFIRE_NAME := "CookingStation"
const DUSK_START := 16.5 * 60.0
const DUSK_END := 19.5 * 60.0
const DAWN_START := 4.5 * 60.0
const DAWN_END := 6.5 * 60.0
const CAMPFIRE_COLOR := Color(1.0, 0.55, 0.25)
const GLOW_COLOR := Color(0.45, 0.95, 0.85)
const PLAYER_COLOR := Color(1.0, 0.96, 0.88)

var _region: Node
var _campfires: Array[PointLight2D] = []
var _fires: Array[CPUParticles2D] = []
var _glows: Array[PointLight2D] = []
var _player_light: PointLight2D
var _fireflies: CPUParticles2D
var _time := 0.0
var _light_texture: GradientTexture2D


## 0 de dia, 1 à noite; rampas suaves no anoitecer e no amanhecer.
static func night_factor(minutes: float) -> float:
	var m := fposmod(minutes, 1440.0)
	if m >= DUSK_START:
		return smoothstep(DUSK_START, DUSK_END, m)
	if m <= DAWN_END:
		return 1.0 - smoothstep(DAWN_START, DAWN_END, m)
	return 0.0


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
	call_deferred("_scan")
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)


func campfire_lights() -> Array[PointLight2D]: return _campfires
func campfire_fire() -> Array[CPUParticles2D]: return _fires
func glow_lights() -> Array[PointLight2D]: return _glows
func player_light() -> PointLight2D: return _player_light
func fireflies() -> CPUParticles2D: return _fireflies


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
	for light in _campfires:
		if is_instance_valid(light):
			light.energy = 0.8 * night * flicker
	for fire in _fires:
		if is_instance_valid(fire):
			fire.emitting = night > 0.15
	for light in _glows:
		if is_instance_valid(light):
			light.energy = 0.55 * night
	if is_instance_valid(_player_light):
		_player_light.energy = 0.22 * night
	if is_instance_valid(_fireflies):
		_fireflies.emitting = night > 0.4


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
		_fireflies = _make_fireflies(firefly_amount(str(_region.name)))
		player.add_child(_fireflies)
	apply_time(GameClock.get_hour() * 60.0 + GameClock.get_minute(), 0.0)


func _on_node_added(node: Node) -> void:
	if is_instance_valid(_region) and _region.is_ancestor_of(node):
		_consider.call_deferred(node)


func _consider(node: Node) -> void:
	if not is_instance_valid(node) or node.has_meta("ambient_light"):
		return
	if node.name == CAMPFIRE_NAME and node is Node2D:
		node.set_meta("ambient_light", true)
		_add_campfire(node)
	elif node is Sprite2D and _glows.size() < MAX_GLOW_LIGHTS:
		var texture: Texture2D = node.texture
		if texture and texture.resource_path.ends_with(GLOW_TEXTURE_SUFFIX):
			node.set_meta("ambient_light", true)
			var light := _make_light(GLOW_COLOR, 0.55)
			light.name = "GlowLight"
			node.add_child(light)
			_glows.append(light)


func _add_campfire(station: Node2D) -> void:
	var light := _make_light(CAMPFIRE_COLOR, 2.0)
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
	flies.scale_amount_min = 1.0
	flies.scale_amount_max = 2.0
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

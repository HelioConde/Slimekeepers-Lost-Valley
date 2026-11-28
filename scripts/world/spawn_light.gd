extends Node2D
## Foco de luz sobre o ponto de início da Clareira do Despertar: um feixe largo que
## desce das copas, uma poça de luz no chão em volta do jogador e pó brilhando no
## ar. Preso ao mundo (não segue o jogador). Dourado de dia, azul-luar à noite.
## Tudo aditivo, em polígonos com bordas em degraus (pixel art, sem degradê liso).

const LIGHTS := preload("res://scripts/world/ambient_lights.gd")
const DAY := Color(1.0, 0.86, 0.5)
const NIGHT := Color(0.55, 0.78, 1.0)
const TOP_OFFSET := Vector2(-130.0, -440.0)  # o feixe vem do alto, à esquerda (copas)

var color := DAY
var strength := 0.0
var _shaft: Node2D
var _pool: Node2D
var _dust: CPUParticles2D
var _time := 0.0


func setup(at: Vector2) -> void:
	name = "SpawnLight"
	top_level = true
	global_position = at.round()
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_pool = Node2D.new()
	_pool.name = "Pool"
	_pool.z_as_relative = false
	_pool.z_index = -1  # no chão, sob plantas e personagens
	_pool.material = additive
	_pool.set_meta("no_shadow", true)
	_pool.draw.connect(_draw_pool)
	add_child(_pool)
	_shaft = Node2D.new()
	_shaft.name = "Shaft"
	_shaft.z_as_relative = false
	_shaft.z_index = 25  # no ar, à frente das copas
	_shaft.material = additive
	_shaft.set_meta("no_shadow", true)
	_shaft.draw.connect(_draw_shaft)
	add_child(_shaft)
	_dust = CPUParticles2D.new()
	_dust.name = "Dust"
	_dust.amount = 14
	_dust.lifetime = 5.0
	_dust.preprocess = 3.0
	_dust.position = TOP_OFFSET * 0.45
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(46, 170)
	_dust.gravity = Vector2(0, 2)
	_dust.initial_velocity_min = 1.0
	_dust.initial_velocity_max = 4.0
	_dust.spread = 180.0
	_dust.scale_amount_min = 2.0
	_dust.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	_dust.color_ramp = ramp
	_dust.z_as_relative = false
	_dust.z_index = 26
	_dust.material = additive
	_dust.set_meta("no_shadow", true)
	add_child(_dust)


func apply_time(minutes: float, delta: float) -> void:
	_time += delta
	var night := LIGHTS.night_factor(minutes)
	# Reforço só no fim de tarde: de manhã o sol baixo já ilumina a Clareira.
	var golden := float(LIGHTS.foliage_profile(minutes).get("golden", 0.0)) * (1.0 if fposmod(minutes, 1440.0) > 720.0 else 0.0)
	color = DAY.lerp(NIGHT, night)
	# Sempre presente; mais forte com sol baixo e um pouco mais fraco ao meio-dia.
	strength = (0.2 + 0.14 * golden) * (1.0 - night) + 0.17 * night
	strength *= 0.9 + 0.1 * sin(_time * 0.5)
	if is_instance_valid(_dust):
		_dust.modulate = Color(color, 1.0)
	_shaft.queue_redraw()
	_pool.queue_redraw()


func _draw_shaft() -> void:
	var top := TOP_OFFSET
	var bottom := Vector2(0, -6)
	var across := (bottom - top).orthogonal().normalized()
	# Seções (posição, meia-largura, alfa no eixo); bordas laterais transparentes.
	# Maior e mais delicado: mais largo, alfa baixo, subida e descida suaves.
	var stations := [[0.0, 20.0, 0.0], [0.2, 36.0, 0.45], [0.5, 50.0, 0.8], [0.8, 60.0, 1.0], [1.0, 66.0, 0.6]]
	for k in stations.size() - 1:
		var s0: Array = stations[k]
		var s1: Array = stations[k + 1]
		var p0 := top.lerp(bottom, s0[0])
		var p1 := top.lerp(bottom, s1[0])
		var c0 := Color(color, strength * 0.9 * float(s0[2]))
		var c1 := Color(color, strength * 0.9 * float(s1[2]))
		var clear := Color(color, 0.0)
		for side in [-1.0, 1.0]:
			_shaft.draw_polygon(
				PackedVector2Array([p0, p0 + across * float(s0[1]) * side, p1 + across * float(s1[1]) * side, p1]),
				PackedColorArray([c0, clear, clear, c1]))


func _draw_pool() -> void:
	# Poça em volta do jogador: 5 elipses achatadas em degraus finos, levemente alongadas
	# na direção do feixe.
	var axis := (Vector2.ZERO - TOP_OFFSET).normalized()
	var flat := Vector2(1.0, 0.42)
	for ring in [[1.0, 0.16], [0.8, 0.2], [0.6, 0.24], [0.42, 0.28], [0.26, 0.3]]:
		var points := PackedVector2Array()
		for k in 32:
			var ang := TAU * float(k) / 32.0
			var v := Vector2(cos(ang) * 92.0, sin(ang) * 92.0) * float(ring[0]) * flat
			v += axis * maxf(0.0, v.dot(axis)) * 0.25
			points.append(v.round())
		_pool.draw_colored_polygon(points, Color(color.r, color.g * 0.97, color.b * 0.8, strength * float(ring[1])))

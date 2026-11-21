extends Node
## Sistema único de reflexos de Sol e Lua na água (V10).
## Um overlay por polígono de água, com material próprio. Na instalação, cada corpo
## d'água é dividido em células fixas do mundo e amostrado (pontos DENTRO do
## polígono). A cada mudança do céu, cada célula escolhe a amostra mais próxima do
## ponto ideal dado pelo astro (Astronomy.reflection_offset). Resultado: âncoras
## sempre na água, presas ao mundo, que só se movem quando o astro se move —
## nunca com o jogador, a câmera ou a tela.
const REFLECTION_SHADER = preload("res://scripts/world/water_reflections.gdshader")
const ASTRONOMY = preload("res://scripts/systems/astronomy.gd")
const WATER_SHADERS := ["spring_water.gdshader", "valley_water.gdshader"]
const MAX_ANCHORS := 16
## Célula ~ do tamanho da vista: no máximo um reflexo da Lua por enquadramento.
const MIN_CELL := 400.0
const LATTICE := 1000.0
## ~ largura da vista (1200 px de mundo no zoom 0,8): reflexos nunca lado a lado.
const MIN_SPACING := 900.0
## Distância máxima entre o ponto ideal e a água escolhida.
const MAX_SNAP := 400.0
const SAMPLE_STEP := 16.0

var materials: Array[ShaderMaterial] = []
## Camada encantada (water_magic) por superfície.
const MAGIC := preload("res://scripts/world/water_magic.gd")
var magic_overlays: Array[Polygon2D] = []
var _light_refresh := 0.0
var surfaces: Array[Polygon2D] = []
## Por superfície: Array de {rect: Rect2, samples: PackedVector2Array} (mundo).
var cells: Array = []
var elapsed := 0.0
var reduce_motion := false
var last_sky: Dictionary = {}
var _last_offsets := [Vector2.INF, Vector2.INF]


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://presentation.cfg") == OK:
		reduce_motion = cfg.get_value("accessibility", "reduce_motion", false)
	var region := get_parent().get_parent()
	for node in region.find_children("*", "Polygon2D", true, false):
		if not node.material is ShaderMaterial or not node.material.shader: continue
		if not node.material.shader.resource_path.get_file() in WATER_SHADERS: continue
		add_surface(node, find_blockers(region))
	update_for_time(0.0)


## Retângulo do corpo d'água em coordenadas de mundo.
static func world_bounds(water: Polygon2D) -> Rect2:
	var box := Rect2(water.global_transform * (water.polygon[0] + water.offset), Vector2.ZERO)
	for point in water.polygon:
		box = box.expand(water.global_transform * (point + water.offset))
	return box


## Divide o corpo em até MAX_ANCHORS células fixas e guarda pontos de água em cada.
static func sample_cells(water: Polygon2D, blockers: Array = []) -> Array:
	var bounds := world_bounds(water)
	var side := maxf(MIN_CELL, sqrt(bounds.get_area() / float(MAX_ANCHORS)) * 1.05)
	var counts := Vector2i(ceili(bounds.size.x / side), ceili(bounds.size.y / side))
	while counts.x * counts.y > MAX_ANCHORS:
		side *= 1.1
		counts = Vector2i(ceili(bounds.size.x / side), ceili(bounds.size.y / side))
	var size := Vector2(bounds.size.x / counts.x, bounds.size.y / counts.y)
	var to_local := water.global_transform.affine_inverse()
	var result: Array = []
	for cy in counts.y:
		for cx in counts.x:
			var rect := Rect2(bounds.position + Vector2(cx, cy) * size, size)
			var samples := PackedVector2Array()
			var y := rect.position.y + SAMPLE_STEP * 0.5
			while y < rect.end.y:
				var x := rect.position.x + SAMPLE_STEP * 0.5
				while x < rect.end.x:
					if Geometry2D.is_point_in_polygon(to_local * Vector2(x, y) - water.offset, water.polygon) and not _blocked(Vector2(x, y), blockers):
						samples.append(Vector2(x, y))
					x += SAMPLE_STEP
				y += SAMPLE_STEP
			if samples.size() > 6: result.append({"rect": rect, "samples": samples})
	return result


## Pontes e afins cobrem a água: o reflexo não nasce embaixo delas (folga de 20 px).
static func _blocked(at: Vector2, blockers: Array) -> bool:
	for rect: Rect2 in blockers:
		if rect.grow(20.0).has_point(at): return true
	return false


## Retângulos (mundo) do que fica por cima da água: polígonos dos nós "Bridges".
static func find_blockers(region: Node) -> Array:
	var rects: Array = []
	var bridges := region.get_node_or_null("Bridges")
	if bridges == null: return rects
	for polygon in bridges.find_children("*", "Polygon2D", true, false):
		var p := polygon as Polygon2D
		if p.polygon.is_empty(): continue
		var box := Rect2(p.global_transform * p.polygon[0], Vector2.ZERO)
		for point in p.polygon: box = box.expand(p.global_transform * point)
		rects.append(box)
	return rects


## Âncoras: malha fixa do mundo com um ponto ideal a cada LATTICE px, deslocado
## pelo astro. Cada ponto ideal vira a amostra de água mais próxima (até MAX_SNAP);
## entre âncoras a menos de MIN_SPACING vence a de menor índice na malha — no máximo
## um reflexo do astro por vista. Depende só da água e do céu.
static func pick_anchors(surface_cells: Array, offset: Vector2) -> PackedVector2Array:
	var samples := PackedVector2Array()
	var bounds := Rect2()
	for cell in surface_cells:
		samples.append_array(cell.samples)
		bounds = cell.rect if bounds.size == Vector2.ZERO else bounds.merge(cell.rect)
	if samples.is_empty(): return PackedVector2Array()
	var candidates: Array = []
	var start := (bounds.position / LATTICE).floor()
	var end := (bounds.end / LATTICE).ceil()
	for gy in range(int(start.y), int(end.y)):
		for gx in range(int(start.x), int(end.x)):
			var ideal := (Vector2(gx, gy) + Vector2(0.5, 0.5) + offset * 0.5) * LATTICE
			var best := samples[0]
			for point in samples:
				if point.distance_squared_to(ideal) < best.distance_squared_to(ideal): best = point
			var error := best.distance_to(ideal)
			if error <= MAX_SNAP: candidates.append([gy * 10000 + gx, best])
	if candidates.is_empty():
		# Corpo pequeno (lago): uma âncora, a água mais próxima do ideal no próprio corpo.
		var ideal := bounds.get_center() + offset * bounds.size * 0.5
		var best := samples[0]
		for point in samples:
			if point.distance_squared_to(ideal) < best.distance_squared_to(ideal): best = point
		return PackedVector2Array([best])
	# Prioridade fixa pela posição na malha (não muda com o tempo): sem saltos de
	# uma âncora para outra enquanto o astro anda.
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	var anchors := PackedVector2Array()
	for candidate in candidates:
		if anchors.size() >= MAX_ANCHORS: break
		var far := true
		for kept in anchors:
			if kept.distance_to(candidate[1]) < MIN_SPACING: far = false
		if far: anchors.append(candidate[1])
	return anchors


func add_surface(water: Polygon2D, blockers: Array = []) -> void:
	var material := ShaderMaterial.new()
	material.shader = REFLECTION_SHADER
	var overlay := Polygon2D.new()
	overlay.name = "CelestialReflection"
	overlay.polygon = water.polygon
	overlay.polygons = water.polygons
	overlay.offset = water.offset
	overlay.material = material
	overlay.set_meta("no_shadow", true)
	water.add_child(overlay)
	surfaces.append(overlay)
	materials.append(material)
	# Rios grandes correm para baixo; lagos pequenos derivam de leve.
	var big := maxf(world_bounds(water).size.x, world_bounds(water).size.y) > 600.0
	magic_overlays.append(MAGIC.make_overlay(water, Vector2(0.08, 1.0) if big else Vector2(1.0, 0.25)))
	cells.append(sample_cells(water, blockers))


func update_for_time(delta: float) -> void:
	if materials.is_empty(): return
	if not reduce_motion: elapsed += maxf(delta, 0.0)
	apply_sky(ASTRONOMY.now())
	update_magic(delta)


## Camada encantada: tempo, noite e fontes de luz próximas (mundo).
func update_magic(delta: float) -> void:
	var night: float = preload("res://scripts/world/ambient_lights.gd").night_factor(float(last_sky.get("minutes", 540.0)))
	_light_refresh -= delta
	var refresh := _light_refresh <= 0.0
	if refresh: _light_refresh = 0.2
	var region := get_parent().get_parent()
	var view := Vector2.ZERO
	var player := region.get_node_or_null("Player") as Node2D
	if player: view = player.global_position
	for overlay in magic_overlays:
		var m := overlay.material as ShaderMaterial
		m.set_shader_parameter("elapsed", floorf(elapsed * 8.0) / 8.0)
		m.set_shader_parameter("night", night)
		if not refresh: continue
		var lights := PackedVector4Array()
		var colors := PackedVector4Array()
		for source in MAGIC.gather_lights(region, overlay.get_meta("world_rect"), view):
			var c: Color = source.get_meta("light_color", Color(0.5, 0.85, 1.0))
			lights.append(Vector4(source.global_position.x, source.global_position.y, float(source.get_meta("light_radius", 14.0)), float(source.get_meta("light_strength", 1.0))))
			colors.append(Vector4(c.r, c.g, c.b, 1.0))
		m.set_shader_parameter("light_count", lights.size())
		lights.resize(MAGIC.MAX_LIGHTS)
		colors.resize(MAGIC.MAX_LIGHTS)
		m.set_shader_parameter("lights", lights)
		m.set_shader_parameter("light_colors", colors)


func apply_sky(sky: Dictionary) -> void:
	last_sky = sky
	var moon_offset: Vector2 = ASTRONOMY.reflection_offset(sky.moon_altitude, sky.moon_azimuth)
	var sun_offset: Vector2 = ASTRONOMY.reflection_offset(sky.sun_altitude, sky.sun_azimuth)
	# Âncoras só são recalculadas quando o astro anda o bastante (barato e estável).
	var moved := moon_offset.distance_to(_last_offsets[0]) > 0.01 or sun_offset.distance_to(_last_offsets[1]) > 0.01
	if moved: _last_offsets = [moon_offset, sun_offset]
	for i in materials.size():
		var material := materials[i]
		if moved:
			var moon := pick_anchors(cells[i], moon_offset)
			var sun := pick_anchors(cells[i], sun_offset)
			material.set_shader_parameter("anchor_count", moon.size())
			moon.resize(MAX_ANCHORS)
			sun.resize(MAX_ANCHORS)
			material.set_shader_parameter("moon_anchors", moon)
			material.set_shader_parameter("sun_anchors", sun)
		material.set_shader_parameter("elapsed", floorf(elapsed * 8.0) / 8.0)
		material.set_shader_parameter("moon_strength", sky.moon_reflection)
		material.set_shader_parameter("moon_phase", sky.moon_phase)
		material.set_shader_parameter("sun_strength", maxf(0.0, sky.sun_reflection) * 0.9)
		material.set_shader_parameter("sun_color", sky.sun_color)


## Âncoras atuais da Lua por superfície (mundo), para testes e depuração.
func moon_anchors() -> Array:
	var result: Array = []
	var offset: Vector2 = ASTRONOMY.reflection_offset(last_sky.moon_altitude, last_sky.moon_azimuth)
	for surface_cells in cells: result.append(pick_anchors(surface_cells, offset))
	return result

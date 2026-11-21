extends RefCounted
## Água encantada (V11): monta a camada aditiva water_magic.gdshader sobre um
## polígono de água. A máscara de distância à margem é calculada da geometria real
## (scanline + transformada de distância chanfrada), em grade de CELL px do mundo.
## Fontes de luz (plantas mágicas, cogumelos, slimes) são atualizadas por
## WaterReflections a cada quadro; tudo em coordenadas de mundo.

const SHADER := preload("res://scripts/world/water_magic.gdshader")
const CELL := 4.0
const EDGE_SCALE := 64.0
const MAX_LIGHTS := 24


## Distância (px de mundo) de cada célula até a margem, codificada em R (0..1 = 0..EDGE_SCALE).
static func edge_map(water: Polygon2D) -> Dictionary:
	var xform := water.global_transform
	var points := PackedVector2Array()
	for point in water.polygon: points.append(xform * (point + water.offset))
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points: bounds = bounds.expand(point)
	bounds = bounds.grow(CELL * 2.0)
	var w := int(ceil(bounds.size.x / CELL))
	var h := int(ceil(bounds.size.y / CELL))
	var inf := 1e9
	var dist := PackedFloat32Array()
	dist.resize(w * h)
	# Scanline: dentro = INF, fora = 0.
	for y in h:
		var wy := bounds.position.y + (y + 0.5) * CELL
		var xs: Array[float] = []
		for i in points.size():
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			if (a.y <= wy and b.y > wy) or (b.y <= wy and a.y > wy):
				xs.append(a.x + (wy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		for x in w: dist[y * w + x] = 0.0
		var k := 0
		while k + 1 < xs.size():
			var x0 := int(ceil((xs[k] - bounds.position.x) / CELL - 0.5))
			var x1 := int(floor((xs[k + 1] - bounds.position.x) / CELL - 0.5))
			for x in range(maxi(x0, 0), mini(x1, w - 1) + 1): dist[y * w + x] = inf
			k += 2
	# Chanfrada 3-4 em duas passadas.
	for y in h:
		for x in w:
			var i := y * w + x
			if dist[i] == 0.0: continue
			var v := dist[i]
			if x > 0: v = minf(v, dist[i - 1] + 1.0)
			if y > 0:
				v = minf(v, dist[i - w] + 1.0)
				if x > 0: v = minf(v, dist[i - w - 1] + 1.414)
				if x < w - 1: v = minf(v, dist[i - w + 1] + 1.414)
			dist[i] = v
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			if dist[i] == 0.0: continue
			var v := dist[i]
			if x < w - 1: v = minf(v, dist[i + 1] + 1.0)
			if y < h - 1:
				v = minf(v, dist[i + w] + 1.0)
				if x < w - 1: v = minf(v, dist[i + w + 1] + 1.414)
				if x > 0: v = minf(v, dist[i + w - 1] + 1.414)
			dist[i] = v
	var image := Image.create(w, h, false, Image.FORMAT_L8)
	for y in h:
		for x in w:
			image.set_pixel(x, y, Color.from_hsv(0, 0, clampf(dist[y * w + x] * CELL / EDGE_SCALE, 0.0, 1.0)))
	return {"image": image, "rect": bounds}


static func make_overlay(water: Polygon2D, flow_dir: Vector2) -> Polygon2D:
	var map := edge_map(water)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("edge_map", ImageTexture.create_from_image(map.image))
	var rect: Rect2 = map.rect
	material.set_shader_parameter("edge_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	material.set_shader_parameter("edge_scale", EDGE_SCALE)
	material.set_shader_parameter("flow_dir", flow_dir)
	var overlay := Polygon2D.new()
	overlay.name = "EnchantedWater"
	overlay.polygon = water.polygon
	overlay.polygons = water.polygons
	overlay.offset = water.offset
	overlay.material = material
	overlay.set_meta("no_shadow", true)
	overlay.set_meta("world_rect", rect)
	water.add_child(overlay)
	return overlay


## Fontes luminosas (mundo) dentro de `rect` crescido: sprites com meta
## magic_flower, cogumelos luminosos e slimes com aura. Mais próximas da vista primeiro.
static func gather_lights(region: Node, rect: Rect2, view: Vector2) -> Array:
	var found: Array = []
	var grown := rect.grow(48.0)
	for node in region.get_tree().get_nodes_in_group("water_light_sources"):
		if not (node is Node2D) or not node.is_visible_in_tree() or not region.is_ancestor_of(node): continue
		var at: Vector2 = (node as Node2D).global_position
		if grown.has_point(at): found.append([at.distance_squared_to(view), node])
	found.sort_custom(func(a, b): return a[0] < b[0])
	return found.slice(0, MAX_LIGHTS).map(func(x): return x[1])

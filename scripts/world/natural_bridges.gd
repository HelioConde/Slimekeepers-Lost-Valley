extends RefCounted
## Pontes naturais do Vale: o mundo não tem humanos, então as travessias de tábuas
## viram passagens que a natureza formou. O usuário aprovou só o arco de raízes
## entrelaçadas (tronco caído, pedras e istmo foram rejeitados), então os 5 locais
## (BRIDGES) usam o mesmo arco: [arte, girar 90°, espelhar], espelhado em
## alternância para não repetir igual; verticais usam a versão vertical do arco.
## A travessia em si não muda: a colisão da água tem buracos nos retângulos de
## BRIDGES (region_surfaces/build_valley). Aqui só troca o visual.

const ART := "res://assets/world/valley/natural_bridges/"
const KINDS := [["root_bridge", false, false], ["root_bridge", false, true], ["root_bridge_v", false, false], ["root_bridge_v", false, true], ["root_bridge", false, false]]
const SCALE := 2.0  # mesma densidade de pixel das árvores e plantas


static func apply(bridges: Node2D) -> Array[Sprite2D]:
	var placed: Array[Sprite2D] = []
	var rects: Array = preload("res://scripts/world/valley_layout.gd").BRIDGES
	for i in rects.size():
		var bridge := bridges.get_node_or_null("Bridge%d" % (i + 1)) as Node2D
		if bridge == null: continue
		# Tábuas e moldura somem; o nó fica (retângulo usado por lanternas e reflexos).
		for part in bridge.get_children():
			if part is CanvasItem: (part as CanvasItem).visible = false
		var rect: Rect2 = rects[i]
		var sprite := Sprite2D.new()
		var kind: Array = KINDS[i]
		sprite.name = "Natural_%s_%d" % [kind[0], i + 1]
		sprite.texture = load(ART + str(kind[0]) + ".png")
		if kind[1]: sprite.rotation = PI / 2.0  # 90° exatos: pixels intactos
		sprite.flip_h = kind[2]
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(SCALE, SCALE)
		sprite.position = bridges.to_local(rect.get_center()).round()
		sprite.set_meta("no_shadow", true)
		bridges.add_child(sprite)
		placed.append(sprite)
		if str(kind[0]).ends_with("_v"):
			_blend_ends(bridges, sprite, i)
	return placed


## Pontas da ponte vertical se misturam ao chão (pedido do usuário): o sprite já
## some em pontilhado nas pontas; aqui matinho rasteiro do mapa (trevo e tufo de
## grama baixa, 32 px) cobre as laterais do tronco da ponta até a beira da água,
## em posições fixas por ponte (hash da posição, sem aleatório por sessão).
const TUFTS := [preload("res://assets/world/ground/clover_sprig.png"), preload("res://assets/world/ground/clover_sprig.png"), preload("res://assets/world/ground/grass_tuft_sunlit.png")]  # mais trevo (rasteiro)
const TUFT_STEP := 40.0  # lateral leve (24 ficou carregado)
static func _blend_ends(bridges: Node2D, bridge: Sprite2D, index: int) -> void:
	var waters: Array = []
	var region := bridges.get_parent()
	if region and region.has_node("Water"):
		waters = region.get_node("Water").get_children().filter(func(n): return n is Polygon2D)
	var center := bridges.to_global(bridge.position)
	var half := bridge.texture.get_height() * SCALE * 0.5
	for end in [-1.0, 1.0]:
		for side in [-1.0, 1.0]:
			var t := 6.0
			var k := 0
			while t < half - 8.0:
				var along: float = end * (half - t)
				var at: Vector2 = center + Vector2(side * (22.0 + float(k % 2) * 8.0), along + (10.0 if side > 0 else 0.0))
				if _in_water(at + Vector2(0, end * -6.0), waters): break  # chegou na beira
				var h: int = posmod(hash(Vector3i(index, k, int(side * end))), 97)
				if h % 3 == 0:  # falhas na fileira: não forma cerca
					t += TUFT_STEP
					k += 1
					continue
				var tuft := Sprite2D.new()
				tuft.name = "BridgeTuft"
				tuft.texture = TUFTS[h % TUFTS.size()]
				tuft.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				tuft.flip_h = h % 2 == 0
				tuft.offset = Vector2(0, -6)
				tuft.position = bridges.to_local(at + Vector2(side * float(h % 5), 0)).round()
				tuft.set_meta("no_shadow", true)
				bridges.add_child(tuft)
				t += TUFT_STEP
				k += 1


	_scatter_around(bridges, center, half, index, waters)


## Mato rasteiro solto no chão em volta das duas pontas (raio ~140 px), mais denso
## perto da ponte e rareando para fora, para a lateral não ficar destacada.
static func _scatter_around(bridges: Node2D, center: Vector2, half: float, index: int, waters: Array) -> void:
	for end in [-1.0, 1.0]:
		var anchor := center + Vector2(0, end * (half - 30.0))
		for gy in range(-5, 6):
			for gx in range(-6, 7):
				var cell := Vector2(gx, gy) * 26.0
				var h: int = posmod(hash(Vector3i(index * 31 + int(end), gx, gy)), 1000)
				var at := anchor + cell + Vector2(h % 13 - 6, (h / 13) % 13 - 6)
				var d := (at - anchor).length() / 140.0
				if d > 1.0 or float(h % 100) / 100.0 > 0.35 * (1.0 - d): continue
				if absf(at.x - center.x) < 22.0: continue  # não em cima da passarela
				if _in_water(at, waters) or _in_water(at + Vector2(0, 8), waters): continue
				var tuft := Sprite2D.new()
				tuft.name = "BridgeTuft"
				tuft.texture = TUFTS[h % TUFTS.size()]
				tuft.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				tuft.flip_h = h % 2 == 0
				tuft.offset = Vector2(0, -6)
				tuft.position = bridges.to_local(at).round()
				tuft.set_meta("no_shadow", true)
				bridges.add_child(tuft)


static func _in_water(at: Vector2, waters: Array) -> bool:
	for w: Polygon2D in waters:
		if Geometry2D.is_point_in_polygon(w.global_transform.affine_inverse() * at - w.offset, w.polygon): return true
	return false

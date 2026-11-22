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
## some em pontilhado nas pontas; aqui tufos da própria vegetação do mapa cobrem a
## emenda dos dois lados, em posições fixas por ponte (sem aleatório por sessão).
const TUFTS := [preload("res://assets/world/forest/fern.png"), preload("res://assets/world/forest/plant_rosette.png")]
static func _blend_ends(bridges: Node2D, bridge: Sprite2D, index: int) -> void:
	var half := bridge.texture.get_height() * SCALE * 0.5
	for end in [-1.0, 1.0]:
		for side in [-1.0, 1.0]:
			var tuft := Sprite2D.new()
			tuft.name = "BridgeTuft"
			tuft.texture = TUFTS[(index + int(end > 0) + int(side > 0)) % TUFTS.size()]
			tuft.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tuft.flip_h = side > 0
			# Perto da ponta, encostado no lado do tronco; a de baixo um pouco mais baixa.
			tuft.position = (bridge.position + Vector2(side * 22.0, end * (half - 26.0) + (10.0 if end > 0 else 0.0))).round()
			tuft.offset = Vector2(0, -16)
			tuft.set_meta("no_shadow", true)
			bridges.add_child(tuft)

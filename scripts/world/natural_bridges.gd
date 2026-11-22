extends RefCounted
## Pontes naturais do Vale: o mundo não tem humanos, então as travessias de tábuas
## viram passagens que a natureza formou. A escolha segue cada local (BRIDGES):
##  1 noroeste, riacho estreito entre gramados  -> tronco caído com musgo
##  2 nordeste, riacho com pedras nas margens    -> pedras redondas de travessia
##  3 oeste, faixa estreita entre dois lagos     -> istmo de terra e grama
##  4 leste, entre lagos sob uma árvore grande   -> árvore gigante caída
##  5 sul, riacho entre árvores grandes          -> ponte de raízes entrelaçadas
## A travessia em si não muda: a colisão da água tem buracos nos retângulos de
## BRIDGES (region_surfaces/build_valley). Aqui só troca o visual.

const ART := "res://assets/world/valley/natural_bridges/"
const KINDS := ["fallen_log", "boulders", "land_bridge", "giant_log", "root_bridge"]
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
		sprite.name = "Natural_%s" % KINDS[i]
		sprite.texture = load(ART + KINDS[i] + ".png")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(SCALE, SCALE)
		sprite.position = bridges.to_local(rect.get_center()).round()
		sprite.set_meta("no_shadow", true)
		bridges.add_child(sprite)
		placed.append(sprite)
	return placed

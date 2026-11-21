extends Node2D
## Plantas-lanterna bioluminescentes nas cabeceiras das pontes do Vale (ref. V9 do
## rio): o brilho quente das lanternas da referência, mas vindo da natureza — o
## mundo não tem humanos para acender lanternas. Acendem ao anoitecer.

const ART := preload("res://assets/world/valley/lantern_flower.png")
const WARM := Color(1.0, 0.62, 0.3)

var plants: Array[Sprite2D] = []
var halos: Array[Sprite2D] = []
var lights: Array[PointLight2D] = []
var _time := 0.0


## Cantos de cada ponte (retângulos do mundo), com folga para fora do tabuleiro.
func setup(bridge_rects: Array[Rect2], parent_for_plants: Node2D) -> void:
	name = "LanternFlowers"
	var halo_texture := preload("res://scripts/world/mushroom_glows.gd").radial(64, 48, PackedFloat32Array([0.0, 0.3, 0.55, 0.8]), PackedFloat32Array([0.7, 0.4, 0.16, 0.0]))
	var light_texture := preload("res://scripts/world/pond_magic.gd").halo_texture(128)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for rect in bridge_rects:
		for corner in [rect.position + Vector2(-6, -4), Vector2(rect.end.x + 6, rect.position.y - 4), Vector2(rect.position.x - 6, rect.end.y + 10), rect.end + Vector2(6, 10)]:
			var holder := Node2D.new()
			holder.name = "LanternFlower"
			holder.position = parent_for_plants.to_local(corner)
			parent_for_plants.add_child(holder)
			var plant := Sprite2D.new()
			plant.name = "Sprite"
			plant.texture = ART
			plant.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			plant.offset = Vector2(0, -20)
			holder.add_child(plant)
			plants.append(plant)
			var halo := Sprite2D.new()
			halo.texture = halo_texture
			halo.material = additive
			halo.position = Vector2(0, -22)
			halo.scale = Vector2(0.7, 0.7)  # brilho de planta, não de tocha (ref. V11 da ponte)
			halo.modulate = Color(WARM, 0.0)
			halo.set_meta("no_shadow", true)
			holder.add_child(halo)
			halos.append(halo)
			var light := PointLight2D.new()
			light.texture = light_texture
			light.texture_scale = 0.8
			light.color = WARM
			light.energy = 0.0
			light.position = Vector2(0, -16)
			holder.add_child(light)
			lights.append(light)


func apply_time(night: float, delta: float) -> void:
	_time += delta
	for i in halos.size():
		var flicker := 0.9 + 0.1 * sin(_time * (2.1 + i * 0.3)) * sin(_time * 5.3 + i)
		halos[i].modulate.a = 0.45 * night * flicker
		lights[i].energy = 0.45 * night * flicker

extends Node2D
## Névoa noturna baixa (referências V9): poucas faixas azuladas, longas e
## translúcidas, rente ao chão, que derivam devagar em volta do jogador.
## Mínima de propósito: não pode borrar a cena nem cobrir flores e água.

const BANDS := 12
const SPREAD := Vector2(1600, 1000)  # maior que a vista: a troca de cópia acontece fora da tela
const MAX_ALPHA := 0.13
const COLOR := Color(0.62, 0.76, 1.0)

var bands: Array[Sprite2D] = []
var _homes: Array[Vector2] = []
var _time := 0.0


func _ready() -> void:
	name = "NightMist"
	top_level = true
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for i in BANDS:
		var band := Sprite2D.new()
		band.texture = texture
		band.material = material
		band.scale = Vector2(3.2 + (i % 3) * 0.6, 0.55 + (i % 2) * 0.15)
		band.z_as_relative = false
		band.z_index = -1  # sobre o chão, atrás de plantas, árvores e personagens
		band.modulate = Color(COLOR.r, COLOR.g, COLOR.b, 0.0)
		band.set_meta("no_shadow", true)
		add_child(band)
		bands.append(band)
		_homes.append(Vector2(fposmod(i * 0.37, 1.0) - 0.5, fposmod(i * 0.61, 1.0) - 0.5) * SPREAD)


## Faixas presas ao mundo (o jogador passa por elas), repetidas a cada SPREAD:
## usa-se a cópia mais perto da vista.
func apply_time(night: float, center: Vector2, delta: float) -> void:
	_time += delta
	for i in bands.size():
		var band := bands[i]
		var drift := Vector2(sin(_time * 0.05 + i * 1.3) * 60.0, cos(_time * 0.04 + i) * 14.0)
		var at := _homes[i] + drift
		at += ((center - at) / SPREAD).round() * SPREAD
		band.position = at.round()
		band.modulate.a = MAX_ALPHA * night * (0.7 + 0.3 * sin(_time * 0.2 + i * 2.1))
